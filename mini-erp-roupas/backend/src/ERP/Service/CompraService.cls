Class ERP.Service.CompraService
{

ClassMethod Listar() As %DynamicArray
{
    Set array = []
    Set sql = "SELECT ID, DataCompra, Fornecedor, ValorTotal, Status, Observacao FROM ERP_Model.Compra ORDER BY DataCompra DESC"
    Set statement = ##class(%SQL.Statement).%New()
    $$$THROWONERROR(sc, statement.%Prepare(sql))
    Set rset = statement.%Execute()
    While rset.%Next() {
        Set item = {}
        Set item.id = rset.%Get("ID")
        Set item.dataCompra = rset.%Get("DataCompra")
        Set item.valorTotal = rset.%Get("ValorTotal")
        Set item.status = rset.%Get("Status")
        Set item.observacao = rset.%Get("Observacao")

        Set fornecedorId = rset.%Get("Fornecedor")
        If fornecedorId '= "" {
            Set fornecedor = ##class(ERP.Model.Fornecedor).%OpenId(fornecedorId)
            If $IsObject(fornecedor) {
                Set item.fornecedor = fornecedor.Nome
                Set item.fornecedorId = fornecedorId
            }
        }

        Set itens = []
        Set itemSql = "SELECT ID, ItemGrade, Quantidade, CustoUnitario, ValorTotal FROM ERP_Model.CompraItem WHERE Compra = ?"
        Set itemStmt = ##class(%SQL.Statement).%New()
        $$$THROWONERROR(sc, itemStmt.%Prepare(itemSql))
        Set itemRset = itemStmt.%Execute(rset.%Get("ID"))
        While itemRset.%Next() {
            Set grade = ##class(ERP.Model.ItemGrade).%OpenId(itemRset.%Get("ItemGrade"))
            Set itemCompra = {}
            Set itemCompra.id = itemRset.%Get("ID")
            Set itemCompra.quantidade = itemRset.%Get("Quantidade")
            Set itemCompra.custoUnitario = itemRset.%Get("CustoUnitario")
            Set itemCompra.valorTotal = itemRset.%Get("ValorTotal")
            If $IsObject(grade) {
                Set itemCompra.skuId = itemRset.%Get("ItemGrade")
                Set itemCompra.produto = grade.Produto.Nome
                Set itemCompra.tamanho = grade.Tamanho
                Set itemCompra.cor = grade.Cor
            }
            Do itens.%Push(itemCompra)
        }
        Set item.itens = itens
        Do array.%Push(item)
    }
    Quit array
}

ClassMethod RegistrarCompra(pJson As %DynamicObject) As %Status
{
    // Keep the stock entry, purchase, and payable in one all-or-nothing transaction.
    TSTART
    Try {
        If '$IsObject(pJson) {
            Throw ##class(%Exception.General).%New("Dados da compra inválidos.")
        }
        If pJson.fornecedorId = "" {
            Throw ##class(%Exception.General).%New("Fornecedor obrigatório.")
        }
        If '$IsObject(pJson.itens) || (pJson.itens.%Size() = 0) {
            Throw ##class(%Exception.General).%New("Selecione ao menos um item para entrada de estoque.")
        }

        Set fornecedor = ##class(ERP.Model.Fornecedor).%OpenId(pJson.fornecedorId)
        If '$IsObject(fornecedor) {
            Throw ##class(%Exception.General).%New("Fornecedor não encontrado.")
        }

        Set compra = ##class(ERP.Model.Compra).%New()
        Set compra.Fornecedor = fornecedor
        Set compra.Status = pJson.%Get("status", "Aberta")
        Set compra.Observacao = pJson.%Get("observacao", "")
        Set compra.Usuario = pJson.%Get("usuario", "admin")
        Set compra.TerminalId = pJson.%Get("terminalId", "")
        Set compra.TerminalNome = pJson.%Get("terminalNome", "")
        Set compra.ValorTotal = 0
        $$$THROWONERROR(sc, compra.%Save())

        Set totalCompra = 0
        Set iterator = pJson.itens.%GetIterator()
        While iterator.%GetNext(.key, .item) {
            Set skuId = item.skuId
            Set quantidade = +item.quantidade
            Set custoUnitario = +item.custoUnitario

            If (skuId = "") || (quantidade <= 0) || (custoUnitario <= 0) {
                Throw ##class(%Exception.General).%New("SKU, quantidade e custo unitário positivo são obrigatórios.")
            }
            Set grade = ##class(ERP.Model.ItemGrade).%OpenId(skuId)
            If '$IsObject(grade) {
                Throw ##class(%Exception.General).%New("SKU não encontrado para entrada de estoque.")
            }

            Set totalItem = custoUnitario * quantidade
            Set totalCompra = totalCompra + totalItem

            Set saldoAnterior = grade.QtdEstoque
            Set grade.QtdEstoque = saldoAnterior + quantidade
            $$$THROWONERROR(sc, grade.%Save())
            $$$THROWONERROR(sc, ##class(ERP.Service.EstoqueService).RegistrarMovimento(grade, "Entrada", quantidade, saldoAnterior, grade.QtdEstoque, "Compra", compra.%Id(), compra.Usuario, compra.TerminalId, compra.TerminalNome))

            Set compraItem = ##class(ERP.Model.CompraItem).%New()
            Set compraItem.Compra = compra
            Set compraItem.ItemGrade = grade
            Set compraItem.Quantidade = quantidade
            Set compraItem.CustoUnitario = custoUnitario
            Set compraItem.ValorTotal = totalItem
            $$$THROWONERROR(sc, compraItem.%Save())
        }

        Set compra.ValorTotal = totalCompra
        $$$THROWONERROR(sc, compra.%Save())

        Set conta = ##class(ERP.Model.Conta).%New()
        Set conta.Tipo = "Pagar"
        Set conta.Descricao = "Compra #" _ compra.%Id() _ " - " _ fornecedor.Nome
        Set conta.Valor = totalCompra
        Set conta.ValorPago = 0
        Set conta.Status = "Aberta"
        Set conta.DataVencimento = pJson.%Get("dataVencimento", $ZDATE($HOROLOG,3))
        Set conta.OrigemTipo = "Compra"
        Set conta.OrigemNome = fornecedor.Nome
        Set conta.Usuario = "admin"
        $$$THROWONERROR(sc, conta.%Save())

        TCOMMIT
        Return $$$OK
    }
    Catch ex {
        TROLLBACK
        Return ex.AsStatus()
    }
}

}
