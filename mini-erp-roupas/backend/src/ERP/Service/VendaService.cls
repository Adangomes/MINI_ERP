Class ERP.Service.VendaService
{

ClassMethod RegistrarVenda(pSkuId As %String, pQuantidade As %Integer) As %Status
{
    // Stock, sale record, and cash entry must either all persist or all roll back.
    TSTART
    Try {
        If (pSkuId = "") || (pQuantidade <= 0) {
            Throw ##class(%Exception.General).%New("SKU e quantidade são obrigatórios.")
        }

        Set sku = ##class(ERP.Model.ItemGrade).%OpenId(pSkuId)
        If '$IsObject(sku) {
            Throw ##class(%Exception.General).%New("SKU não encontrado.")
        }

        If sku.QtdEstoque < pQuantidade {
            Throw ##class(%Exception.General).%New("Estoque insuficiente para esta venda.")
        }

        Set produto = sku.Produto
        If '$IsObject(produto) {
            Throw ##class(%Exception.General).%New("Produto associado ao SKU não encontrado.")
        }

        Set valorTotal = produto.PrecoBase * pQuantidade

        Set sku.QtdEstoque = sku.QtdEstoque - pQuantidade
        $$$THROWONERROR(sc, sku.%Save())

        Set venda = ##class(ERP.Model.Venda).%New()
        Set venda.ItemGrade = sku
        Set venda.Quantidade = pQuantidade
        Set venda.ValorTotal = valorTotal
        Set venda.Usuario = "admin"
        $$$THROWONERROR(sc, venda.%Save())

        Set movimento = ##class(ERP.Model.MovimentoCaixa).%New()
        Set movimento.Tipo = "Entrada"
        Set movimento.Descricao = "Venda #" _ venda.%Id()
        Set movimento.Valor = valorTotal
        Set movimento.Referencia = "Venda:" _ venda.%Id()
        Set movimento.Usuario = venda.Usuario
        $$$THROWONERROR(sc, movimento.%Save())

        TCOMMIT
        Quit $$$OK
    }
    Catch ex {
        TROLLBACK
        Quit ex.AsStatus()
    }
}

ClassMethod Listar(pPeriodo As %String, pData As %String, pFuso As %Integer, ByRef pVendas As %DynamicArray) As %Status
{
    Set pVendas = []

    Try {
        Set sql = "SELECT ID, DataHora, ItemGrade, Quantidade, ValorTotal, Usuario FROM ERP_Model.Venda"
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

        Quit $$$OK
    }
    Catch ex {
        Quit ex.AsStatus()
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
