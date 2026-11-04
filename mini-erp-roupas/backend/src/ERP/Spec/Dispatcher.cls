Class ERP.Spec.Dispatcher Extends %CSP.REST
{

XData UrlMap [ XMLNamespace = "http://www.intersystems.com/urlmap" ]
{
<Routes>
    <Route Url="/login" Method="POST" Call="Login"/>
    <Route Url="/produtos" Method="GET" Call="ListarProdutos"/>
    <Route Url="/produtos" Method="POST" Call="SalvarProduto"/>
    <Route Url="/estoque/movimentos" Method="GET" Call="ListarMovimentosEstoque"/>
    <Route Url="/clientes" Method="GET" Call="ListarClientes"/>
    <Route Url="/clientes" Method="POST" Call="SalvarCliente"/>
    <Route Url="/fornecedores" Method="GET" Call="ListarFornecedores"/>
    <Route Url="/fornecedores" Method="POST" Call="SalvarFornecedor"/>
    <Route Url="/compras" Method="GET" Call="ListarCompras"/>
    <Route Url="/compras" Method="POST" Call="SalvarCompra"/>
    <Route Url="/caixa" Method="GET" Call="ListarCaixa"/>
    <Route Url="/caixa" Method="POST" Call="SalvarMovimentoCaixa"/>
    <Route Url="/contas" Method="GET" Call="ListarContas"/>
    <Route Url="/contas" Method="POST" Call="SalvarConta"/>
    <Route Url="/contas/pagamento" Method="POST" Call="PagarConta"/>
    <Route Url="/dre" Method="GET" Call="ResumoDRE"/>
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

ClassMethod ListarMovimentosEstoque() As %Status
{
    Try {
        Set lista = ##class(ERP.Service.EstoqueService).ListarMovimentos()
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

ClassMethod ListarClientes() As %Status
{
    Try {
        Set lista = ##class(ERP.Service.ClienteService).Listar()
        Return ##class(ERP.Util.Response).Send("200 OK", lista)
    }
    Catch ex {
        Return ##class(ERP.Util.Response).SendError("500 Internal Error", ex.DisplayString())
    }
}

ClassMethod SalvarCliente() As %Status
{
    Try {
        Set body = %request.Content
        Set json = ##class(%DynamicAbstractObject).%FromJSON(body)
        Set sc = ##class(ERP.Service.ClienteService).CriarOuAtualizar(json)
        If $$$ISOK(sc) {
            Return ##class(ERP.Util.Response).SendSuccess("Cliente salvo com sucesso!")
        } Else {
            Return ##class(ERP.Util.Response).SendError("400 Bad Request", "Erro ao salvar cliente.")
        }
    }
    Catch ex {
        Return ##class(ERP.Util.Response).SendError("500 Internal Error", ex.DisplayString())
    }
}

ClassMethod ListarFornecedores() As %Status
{
    Try {
        Set lista = ##class(ERP.Service.FornecedorService).Listar()
        Return ##class(ERP.Util.Response).Send("200 OK", lista)
    }
    Catch ex {
        Return ##class(ERP.Util.Response).SendError("500 Internal Error", ex.DisplayString())
    }
}

ClassMethod SalvarFornecedor() As %Status
{
    Try {
        Set body = %request.Content
        Set json = ##class(%DynamicAbstractObject).%FromJSON(body)
        Set sc = ##class(ERP.Service.FornecedorService).CriarOuAtualizar(json)
        If $$$ISOK(sc) {
            Return ##class(ERP.Util.Response).SendSuccess("Fornecedor salvo com sucesso!")
        } Else {
            Return ##class(ERP.Util.Response).SendError("400 Bad Request", "Erro ao salvar fornecedor.")
        }
    }
    Catch ex {
        Return ##class(ERP.Util.Response).SendError("500 Internal Error", ex.DisplayString())
    }
}

ClassMethod ListarCompras() As %Status
{
    Try {
        Set lista = ##class(ERP.Service.CompraService).Listar()
        Return ##class(ERP.Util.Response).Send("200 OK", lista)
    }
    Catch ex {
        Return ##class(ERP.Util.Response).SendError("500 Internal Error", ex.DisplayString())
    }
}

ClassMethod SalvarCompra() As %Status
{
    Try {
        Set body = %request.Content
        Set json = ##class(%DynamicAbstractObject).%FromJSON(body)
        Set sc = ##class(ERP.Service.CompraService).RegistrarCompra(json)
        If $$$ISOK(sc) {
            Return ##class(ERP.Util.Response).SendSuccess("Compra registrada com sucesso!")
        } Else {
            Return ##class(ERP.Util.Response).SendError("400 Bad Request", $SYSTEM.Status.GetErrorText(sc))
        }
    }
    Catch ex {
        Return ##class(ERP.Util.Response).SendError("500 Internal Error", ex.DisplayString())
    }
}

ClassMethod ListarCaixa() As %Status
{
    Try {
        Set inicio = %request.Data("inicio", 1)
        Set fim = %request.Data("fim", 1)
        Set lista = ##class(ERP.Service.FinanceiroService).ListarCaixa(inicio, fim)
        Return ##class(ERP.Util.Response).Send("200 OK", lista)
    }
    Catch ex {
        Return ##class(ERP.Util.Response).SendError("500 Internal Error", ex.DisplayString())
    }
}

ClassMethod SalvarMovimentoCaixa() As %Status
{
    Try {
        Set body = %request.Content
        Set json = ##class(%DynamicAbstractObject).%FromJSON(body)
        Set sc = ##class(ERP.Service.FinanceiroService).RegistrarMovimentoCaixa(json)
        If $$$ISOK(sc) {
            Return ##class(ERP.Util.Response).SendSuccess("Movimento de caixa registrado com sucesso!")
        } Else {
            Return ##class(ERP.Util.Response).SendError("400 Bad Request", $SYSTEM.Status.GetErrorText(sc))
        }
    }
    Catch ex {
        Return ##class(ERP.Util.Response).SendError("500 Internal Error", ex.DisplayString())
    }
}

ClassMethod ListarContas() As %Status
{
    Try {
        Set lista = ##class(ERP.Service.FinanceiroService).ListarContas()
        Return ##class(ERP.Util.Response).Send("200 OK", lista)
    }
    Catch ex {
        Return ##class(ERP.Util.Response).SendError("500 Internal Error", ex.DisplayString())
    }
}

ClassMethod SalvarConta() As %Status
{
    Try {
        Set body = %request.Content
        Set json = ##class(%DynamicAbstractObject).%FromJSON(body)
        Set sc = ##class(ERP.Service.FinanceiroService).RegistrarConta(json)
        If $$$ISOK(sc) {
            Return ##class(ERP.Util.Response).SendSuccess("Conta salva com sucesso!")
        } Else {
            Return ##class(ERP.Util.Response).SendError("400 Bad Request", $SYSTEM.Status.GetErrorText(sc))
        }
    }
    Catch ex {
        Return ##class(ERP.Util.Response).SendError("500 Internal Error", ex.DisplayString())
    }
}

ClassMethod PagarConta() As %Status
{
    Try {
        Set body = %request.Content
        Set json = ##class(%DynamicAbstractObject).%FromJSON(body)
        Set sc = ##class(ERP.Service.FinanceiroService).RegistrarPagamento(json)
        If $$$ISOK(sc) {
            Return ##class(ERP.Util.Response).SendSuccess("Pagamento registrado e caixa atualizado.")
        } Else {
            Return ##class(ERP.Util.Response).SendError("400 Bad Request", $SYSTEM.Status.GetErrorText(sc))
        }
    }
    Catch ex {
        Return ##class(ERP.Util.Response).SendError("500 Internal Error", ex.DisplayString())
    }
}

ClassMethod ResumoDRE() As %Status
{
    Try {
        Set resumo = ##class(ERP.Service.FinanceiroService).ResumoDRE()
        Return ##class(ERP.Util.Response).Send("200 OK", resumo)
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
        
        If $IsObject(json.%Get("itens")) {
            Set sc = ##class(ERP.Service.VendaService).RegistrarCarrinho(json)
        } Else {
            Set sc = ##class(ERP.Service.VendaService).RegistrarVenda(json.%Get("skuId", ""), +json.%Get("quantidade", 0), json.%Get("usuario", "admin"), json.%Get("terminalId", ""), json.%Get("terminalNome", ""))
        }
        If $$$ISOK(sc) {
            Return ##class(ERP.Util.Response).SendSuccess("Venda realizada com sucesso!")
        } Else {
            Return ##class(ERP.Util.Response).SendError("400 Bad Request", $SYSTEM.Status.GetErrorText(sc))
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
        Set fuso = 0

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
