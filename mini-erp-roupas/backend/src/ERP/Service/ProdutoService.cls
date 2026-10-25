Class ERP.Service.ProdutoService
{

ClassMethod Listar() As %DynamicArray
{
    Set array = []
    
    Set sql = "SELECT ID, Nome, Categoria, PrecoBase FROM ERP_Model.Produto"
    Set statement = ##class(%SQL.Statement).%New()
    Set status = statement.%Prepare(sql)
    $$$THROWONERROR(sc, status)

    Set rset = statement.%Execute()
    While rset.%Next() {
        Set item = {}
        Set item.id = rset.%Get("ID")
        Set item.nome = rset.%Get("Nome")
        Set item.categoria = rset.%Get("Categoria")
        Set item.precoBase = rset.%Get("PrecoBase")

        Set item.grades = ..ObterGrades(item.id)

        Do array.%Push(item)
    }
    Quit array
}

ClassMethod ObterGrades(pProdutoId As %String) As %DynamicArray
{
    Set array = []
    Set sql = "SELECT ID, Tamanho, Cor, QtdEstoque, CodigoBarra FROM ERP_Model.ItemGrade WHERE Produto = ?"
    Set statement = ##class(%SQL.Statement).%New()
    $$$THROWONERROR(sc, statement.%Prepare(sql))

    Set rset = statement.%Execute(pProdutoId)
    While rset.%Next() {
        Set g = {}
        Set g.id = rset.%Get("ID")
        Set g.tamanho = rset.%Get("Tamanho")
        Set g.cor = rset.%Get("Cor")
        Set g.qtdEstoque = rset.%Get("QtdEstoque")
        Set g.codigoBarra = rset.%Get("CodigoBarra")
        Do array.%Push(g)
    }
    Quit array
}

ClassMethod CriarOuAtualizar(pJson As %DynamicObject) As %Status
{
    TSTART
    Try {
        Set prod = ""
        If pJson.id '= "" {
            Set prod = ##class(ERP.Model.Produto).%OpenId(pJson.id)
        }
        Else {
            Set sql = "SELECT ID FROM ERP_Model.Produto WHERE Nome = ? AND Categoria = ?"
            Set statement = ##class(%SQL.Statement).%New()
            $$$THROWONERROR(sc, statement.%Prepare(sql))
            Set rset = statement.%Execute(pJson.nome, pJson.categoria)
            If rset.%Next() {
                Set prod = ##class(ERP.Model.Produto).%OpenId(rset.%Get("ID"))
            }
        }
        If '$IsObject(prod) {
            Set prod = ##class(ERP.Model.Produto).%New()
        }
        
        Set prod.Nome = pJson.nome
        Set prod.Categoria = pJson.categoria
        Set prod.PrecoBase = pJson.precoBase
        
        $$$THROWONERROR(sc, prod.%Save())
        
        // Criar ou Atualizar Grade SKU
        Set sku = ""
        Set sql = "SELECT ID FROM ERP_Model.ItemGrade WHERE Produto = ? AND Tamanho = ? AND Cor = ?"
        Set stmt = ##class(%SQL.Statement).%New()
        $$$THROWONERROR(sc, stmt.%Prepare(sql))
        Set rset = stmt.%Execute(prod.%Id(), pJson.tamanho, pJson.cor)
        If rset.%Next() {
            Set sku = ##class(ERP.Model.ItemGrade).%OpenId(rset.%Get("ID"))
        }
        
        If '$IsObject(sku) {
            Set sku = ##class(ERP.Model.ItemGrade).%New()
            Set sku.Produto = prod
            Set sku.Tamanho = pJson.tamanho
            Set sku.Cor = pJson.cor
        }
        
        Set sku.QtdEstoque = sku.QtdEstoque + pJson.quantidade
        Set sku.CodigoBarra = pJson.codigoBarra
        
        $$$THROWONERROR(sc, sku.%Save())
        
        TCOMMIT
        Return $$$OK
    }
    Catch ex {
        TROLLBACK
        Return ex.AsStatus()
    }
}

}
