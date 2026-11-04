Class ERP.Service.ClienteService
{

ClassMethod Listar() As %DynamicArray
{
    Set array = []
    Set sql = "SELECT ID, Nome, Email, Telefone, TipoDocumento, Documento, Endereco, Ativo, DataCadastro FROM ERP_Model.Cliente ORDER BY Nome"
    Set statement = ##class(%SQL.Statement).%New()
    $$$THROWONERROR(sc, statement.%Prepare(sql))
    Set rset = statement.%Execute()
    While rset.%Next() {
        Set item = {}
        Set item.id = rset.%Get("ID")
        Set item.nome = rset.%Get("Nome")
        Set item.email = rset.%Get("Email")
        Set item.telefone = rset.%Get("Telefone")
        Set item.tipoDocumento = rset.%Get("TipoDocumento")
        Set item.documento = rset.%Get("Documento")
        Set item.endereco = rset.%Get("Endereco")
        Set item.ativo = rset.%Get("Ativo")
        Set item.dataCadastro = rset.%Get("DataCadastro")
        Do array.%Push(item)
    }
    Quit array
}

ClassMethod CriarOuAtualizar(pJson As %DynamicObject) As %Status
{
    Try {
        If '$IsObject(pJson) {
            Return $$$ERROR($$$GeneralError, "Dados do cliente inválidos.")
        }

        Set cliente = ""
        If pJson.id '= "" {
            Set cliente = ##class(ERP.Model.Cliente).%OpenId(pJson.id)
        }
        If '$IsObject(cliente) {
            Set cliente = ##class(ERP.Model.Cliente).%New()
        }

        Set cliente.Nome = pJson.nome
        Set cliente.Email = $Get(pJson.email)
        Set cliente.Telefone = $Get(pJson.telefone)
        Set cliente.TipoDocumento = $Get(pJson.tipoDocumento, "CPF")
        Set cliente.Documento = $Get(pJson.documento)
        Set cliente.Endereco = $Get(pJson.endereco)
        Set cliente.Ativo = +$Get(pJson.ativo, 1)

        $$$THROWONERROR(sc, cliente.%Save())
        Return $$$OK
    }
    Catch ex {
        Return ex.AsStatus()
    }
}

}
