Class ERP.Service.VendaService
{

ClassMethod RegistrarVenda(pSkuId As %String, pQuantidade As %Integer, pUsuario As %String = "admin", pTerminalId As %String = "", pTerminalNome As %String = "") As %Status
{
    Set itens = []
    Set item = {}
    Set item.skuId = pSkuId
    Set item.quantidade = pQuantidade
    Do itens.%Push(item)
    Set carrinho = {}
    Set carrinho.itens = itens
    Set carrinho.usuario = pUsuario
    Set carrinho.terminalId = pTerminalId
    Set carrinho.terminalNome = pTerminalNome
    Return ..RegistrarCarrinho(carrinho)
}

ClassMethod RegistrarCarrinho(pJson As %DynamicObject) As %Status
{
    TSTART
    Try {
        If '$IsObject(pJson) {
            Throw ##class(%Exception.General).%New("Dados do carrinho inválidos.")
        }
        If '$IsObject(pJson.%Get("itens")) {
            Throw ##class(%Exception.General).%New("O carrinho não contém itens.")
        }
        If pJson.itens.%Size() = 0 {
            Throw ##class(%Exception.General).%New("O carrinho não contém itens.")
        }

        Set usuario = pJson.%Get("usuario", "admin")
        Set terminalId = pJson.%Get("terminalId", "")
        Set terminalNome = pJson.%Get("terminalNome", "")
        Set iterator = pJson.itens.%GetIterator()
        While iterator.%GetNext(.key, .item) {
            Set skuId = item.%Get("skuId", "")
            Set quantidade = +item.%Get("quantidade", 0)
            If (skuId = "") || (quantidade <= 0) {
                Throw ##class(%Exception.General).%New("SKU e quantidade positiva são obrigatórios.")
            }

            Set sku = ##class(ERP.Model.ItemGrade).%OpenId(skuId)
            If '$IsObject(sku) {
                Throw ##class(%Exception.General).%New("SKU não encontrado.")
            }
            If sku.QtdEstoque < quantidade {
                Throw ##class(%Exception.General).%New("Estoque insuficiente para uma das peças do carrinho.")
            }

            Set produto = sku.Produto
            If '$IsObject(produto) {
                Throw ##class(%Exception.General).%New("Produto associado ao SKU não encontrado.")
            }

            Set saldoAnterior = sku.QtdEstoque
            Set valorTotal = produto.PrecoBase * quantidade
            Set sku.QtdEstoque = saldoAnterior - quantidade
            $$$THROWONERROR(sc, sku.%Save())

            Set venda = ##class(ERP.Model.Venda).%New()
            Set venda.ItemGrade = sku
            Set venda.Quantidade = quantidade
            Set venda.ValorTotal = valorTotal
            Set venda.Usuario = usuario
            Set venda.TerminalId = terminalId
            Set venda.TerminalNome = terminalNome
            $$$THROWONERROR(sc, venda.%Save())

            $$$THROWONERROR(sc, ##class(ERP.Service.EstoqueService).RegistrarMovimento(sku, "Saida", quantidade, saldoAnterior, sku.QtdEstoque, "Venda", venda.%Id(), usuario, terminalId, terminalNome))

            Set movimento = ##class(ERP.Model.MovimentoCaixa).%New()
            Set movimento.Tipo = "Entrada"
            Set movimento.Descricao = "Venda #" _ venda.%Id()
            Set movimento.Valor = valorTotal
            Set movimento.Referencia = "Venda:" _ venda.%Id()
            Set movimento.Usuario = usuario
            $$$THROWONERROR(sc, movimento.%Save())
        }

        TCOMMIT
        Return $$$OK
    }
    Catch ex {
        TROLLBACK
        Return ex.AsStatus()
    }
}

ClassMethod Listar(pPeriodo As %String, pData As %String, pFuso As %Integer, ByRef pVendas As %DynamicArray) As %Status
{
    Set pVendas = []

    Try {
        Set sql = "SELECT ID, DataHora, ItemGrade, Quantidade, ValorTotal, Usuario, TerminalId, TerminalNome FROM ERP_Model.Venda"
        Set statement = ##class(%SQL.Statement).%New()
        $$$THROWONERROR(sc, statement.%Prepare(sql))

        Set rset = statement.%Execute()
        While rset.%Next() {
            Set dataHora = rset.%Get("DataHora")
            If ..DentroDoPeriodo(dataHora, pPeriodo, pData) {
                Set item = {}
                Set item.id = rset.%Get("ID")
                Set item.dataHora = dataHora
                Set item.quantidade = rset.%Get("Quantidade")
                Set item.valorTotal = rset.%Get("ValorTotal")
                Set item.usuario = rset.%Get("Usuario")
                Set item.terminalId = rset.%Get("TerminalId")
                Set item.terminalNome = rset.%Get("TerminalNome")

                Set itemGradeId = rset.%Get("ItemGrade")
                If itemGradeId '= "" {
                    Set grade = ##class(ERP.Model.ItemGrade).%OpenId(itemGradeId)
                    If $IsObject(grade) {
                        Set item.tamanho = grade.Tamanho
                        Set item.cor = grade.Cor
                        If $IsObject(grade.Produto) {
                            Set item.produto = grade.Produto.Nome
                        }
                    }
                }

                Do pVendas.%Push(item)
            }
        }

        Return $$$OK
    }
    Catch ex {
        Return ex.AsStatus()
    }
}

ClassMethod DentroDoPeriodo(pDataHora As %String, pPeriodo As %String, pData As %String) As %Boolean
{
    If pDataHora = "" {
        Quit 0
    }

    Set dataVenda = $PIECE(pDataHora, " ", 1)

    If pPeriodo = "dia" {
        Quit pData = dataVenda
    }

    If pPeriodo = "mes" {
        If pData = "" {
            Quit 1
        }
        Quit $PIECE(dataVenda, "-", 1, 2) = $PIECE(pData, "-", 1, 2)
    }

    If pPeriodo = "ano" {
        If pData = "" {
            Quit 1
        }
        Quit $PIECE(dataVenda, "-", 1) = pData
    }

    Quit 1
}

}
