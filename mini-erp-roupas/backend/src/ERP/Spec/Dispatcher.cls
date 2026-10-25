Class ERP.Spec.Dispatcher Extends %CSP.REST
{

XData UrlMap [ XMLNamespace = "http://www.intersystems.com/urlmap" ]
{
<Routes>
    <Route Url="/login" Method="POST" Call="Login"/>
    <Route Url="/produtos" Method="GET" Call="ListarProdutos"/>
    <Route Url="/produtos" Method="POST" Call="SalvarProduto"/>
    <Route Url="/venda" Method="POST" Call="RealizarVenda"/>
    <Route Url="/vendas" Method="GET" Call="ListarVendas"/>
</Routes>
}

ClassMethod Login() As %Status
{
    Try {
        Set body = %request.Content
        Set json = ##class(%DynamicAbstractObject).%FromJSON(body)
        
        // Senha configurada: M1n1ERP@
        If (json.usuario = "admin") && (json.senha = "M1n1ERP@") {
            Set res = {}
            Set res.token = "auth-token-demo-12345"
            Set res.usuario = "admin"
            Return ##class(ERP.Util.Response).SendSuccess("Login realizado com sucesso!", res)
        } Else {
            Return ##class(ERP.Util.Response).SendError("401 Unauthorized", "Usuário ou senha incorretos!")
        }
    }
    Catch ex {
        Return ##class(ERP.Util.Response).SendError("500 Internal Error", ex.DisplayString())
    }
}

ClassMethod ListarProdutos() As %Status
{
    Try {
        Set lista = ##class(ERP.Service.ProdutoService).Listar()
        Return ##class(ERP.Util.Response).Send("200 OK", lista)
    }
    Catch ex {
        Return ##class(ERP.Util.Response).SendError("500 Internal Error", ex.DisplayString())
    }
}

ClassMethod SalvarProduto() As %Status
{
    Try {
        Set body = %request.Content
        Set json = ##class(%DynamicAbstractObject).%FromJSON(body)
        
        Set sc = ##class(ERP.Service.ProdutoService).CriarOuAtualizar(json)
        If $$$ISOK(sc) {
            Return ##class(ERP.Util.Response).SendSuccess("Produto/Estoque salvo com sucesso!")
        } Else {
            Return ##class(ERP.Util.Response).SendError("400 Bad Request", "Erro ao salvar produto.")
        }
    }
    Catch ex {
        Return ##class(ERP.Util.Response).SendError("500 Internal Error", ex.DisplayString())
    }
}

ClassMethod RealizarVenda() As %Status
{
    Try {
        Set body = %request.Content
        Set json = ##class(%DynamicAbstractObject).%FromJSON(body)
        
        Set sc = ##class(ERP.Service.VendaService).RegistrarVenda(json.skuId, json.quantidade)
        If $$$ISOK(sc) {
            Return ##class(ERP.Util.Response).SendSuccess("Venda realizada com sucesso!")
        } Else {
            Return ##class(ERP.Util.Response).SendError("400 Bad Request", "Falha na transação de venda.")
        }
    }
    Catch ex {
        Return ##class(ERP.Util.Response).SendError("500 Internal Error", ex.DisplayString())
    }
}

ClassMethod ListarVendas() As %Status
{
    Try {
        Set periodo = %request.Data("periodo", 1)
        Set data = %request.Data("data", 1)
        Set fuso = %request.Data("fuso", 1)
        If fuso = "" Set fuso = 0

        Set sc = ##class(ERP.Service.VendaService).Listar(periodo, data, fuso, .vendas)
        If $$$ISERR(sc) {
            Return ##class(ERP.Util.Response).SendError("400 Bad Request", $SYSTEM.Status.GetErrorText(sc))
        }

        Return ##class(ERP.Util.Response).Send("200 OK", vendas)
    }
    Catch ex {
        Return ##class(ERP.Util.Response).SendError("500 Internal Error", ex.DisplayString())
    }
}

}
