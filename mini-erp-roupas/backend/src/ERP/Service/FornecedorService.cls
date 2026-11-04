Class ERP.Service.FornecedorService
{

ClassMethod Listar() As %DynamicArray
{
    Set array = []
    Set sql = "SELECT ID, Nome, Email, Telefone, Documento, Endereco, Ativo, Observacao, DataCadastro FROM ERP_Model.Fornecedor ORDER BY Nome"
    Set statement = ##class(%SQL.Statement).%New()
    $$$THROWONERROR(sc, statement.%Prepare(sql))
    Set rset = statement.%Execute()
    While rset.%Next() {
        Set item = {}
        Set item.id = rset.%Get("ID")
        Set item.nome = rset.%Get("Nome")
        Set item.email = rset.%Get("Email")
        Set item.telefone = rset.%Get("Telefone")
        Set item.documento = rset.%Get("Documento")
        Set item.endereco = rset.%Get("Endereco")
        Set item.ativo = rset.%Get("Ativo")
        Set item.observacao = rset.%Get("Observacao")
        Set item.dataCadastro = rset.%Get("DataCadastro")
        Do array.%Push(item)
    }
    Quit array
}

ClassMethod CriarOuAtualizar(pJson As %DynamicObject) As %Status
{
    Try {
        If '$IsObject(pJson) {
            Return $$$ERROR($$$GeneralError, "Dados do fornecedor inválidos.")
        }

        Set fornecedor = ""
        If pJson.id '= "" {
            Set fornecedor = ##class(ERP.Model.Fornecedor).%OpenId(pJson.id)
        }
        If '$IsObject(fornecedor) {
            Set fornecedor = ##class(ERP.Model.Fornecedor).%New()
        }

        Set fornecedor.Nome = pJson.nome
        Set fornecedor.Email = $Get(pJson.email)
        Set fornecedor.Telefone = $Get(pJson.telefone)
        Set fornecedor.Documento = $Get(pJson.documento)
        Set fornecedor.Endereco = $Get(pJson.endereco)
        Set fornecedor.Observacao = $Get(pJson.observacao)
        Set fornecedor.Ativo = +$Get(pJson.ativo, 1)

        $$$THROWONERROR(sc, fornecedor.%Save())
        Return $$$OK
    }
    Catch ex {
        Return ex.AsStatus()
    }
}

}
