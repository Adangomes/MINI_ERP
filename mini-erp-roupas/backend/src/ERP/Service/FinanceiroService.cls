Class ERP.Service.FinanceiroService
{

ClassMethod ListarCaixa(pInicio As %String = "", pFim As %String = "") As %DynamicArray
{
    Set array = []
    Set sql = "SELECT ID, Tipo, Descricao, Valor, DataHora, Referencia, Usuario FROM ERP_Model.MovimentoCaixa ORDER BY DataHora DESC"
    Set statement = ##class(%SQL.Statement).%New()
    $$$THROWONERROR(sc, statement.%Prepare(sql))
    Set rset = statement.%Execute()
    While rset.%Next() {
        Set dataHora = rset.%Get("DataHora")
        Set dataMovimento = $PIECE(dataHora, " ", 1)
        If ((pInicio = "") || (dataMovimento >= pInicio)) && ((pFim = "") || (dataMovimento <= pFim)) {
            Set item = {}
            Set item.id = rset.%Get("ID")
            Set item.tipo = rset.%Get("Tipo")
            Set item.descricao = rset.%Get("Descricao")
            Set item.valor = rset.%Get("Valor")
            Set item.dataHora = dataHora
            Set item.referencia = rset.%Get("Referencia")
            Set item.usuario = rset.%Get("Usuario")
            Do array.%Push(item)
        }
    }
    Quit array
}

ClassMethod RegistrarMovimentoCaixa(pJson As %DynamicObject) As %Status
{
    Try {
        If '$IsObject(pJson) Return $$$ERROR($$$GeneralError, "Dados do caixa inválidos.")
        If (pJson.tipo '= "Entrada") && (pJson.tipo '= "Saida") Return $$$ERROR($$$GeneralError, "Tipo de movimento inválido.")
        If (pJson.descricao = "") Return $$$ERROR($$$GeneralError, "Descrição é obrigatória.")
        Set valor = +$Get(pJson.valor)
        If valor <= 0 Return $$$ERROR($$$GeneralError, "Valor do movimento deve ser maior que zero.")

        Set movimento = ##class(ERP.Model.MovimentoCaixa).%New()
        Set movimento.Tipo = pJson.tipo
        Set movimento.Descricao = pJson.descricao
        Set movimento.Valor = valor
        Set movimento.Referencia = $Get(pJson.referencia, "")
        Set movimento.Usuario = $Get(pJson.usuario, "admin")
        $$$THROWONERROR(sc, movimento.%Save())
        Return $$$OK
    }
    Catch ex {
        Return ex.AsStatus()
    }
}

ClassMethod ListarContas() As %DynamicArray
{
    Set array = []
    Set sql = "SELECT ID, Tipo, Descricao, Valor, ValorPago, Status, DataVencimento, OrigemTipo, OrigemNome, Usuario FROM ERP_Model.Conta ORDER BY DataVencimento ASC, ID ASC"
    Set statement = ##class(%SQL.Statement).%New()
    $$$THROWONERROR(sc, statement.%Prepare(sql))
    Set rset = statement.%Execute()
    While rset.%Next() {
        Set item = {}
        Set item.id = rset.%Get("ID")
        Set item.tipo = rset.%Get("Tipo")
        Set item.descricao = rset.%Get("Descricao")
        Set item.valor = rset.%Get("Valor")
        Set item.valorPago = rset.%Get("ValorPago")
        Set item.valorRestante = rset.%Get("Valor") - rset.%Get("ValorPago")
        Set item.dataVencimento = rset.%Get("DataVencimento")
        Set item.status = rset.%Get("Status")
        If (item.status '= "Paga") && (item.dataVencimento < $ZDATE($HOROLOG,3)) {
            Set item.status = "Vencida"
        }
        Set item.origemTipo = rset.%Get("OrigemTipo")
        Set item.origemNome = rset.%Get("OrigemNome")
        Set item.usuario = rset.%Get("Usuario")
        Set pagamentos = []
        Set pagamentoSql = "SELECT ID, Valor, DataHora, FormaPagamento, Referencia FROM ERP_Model.ContaPagamento WHERE Conta = ? ORDER BY DataHora"
        Set pagamentoStmt = ##class(%SQL.Statement).%New()
        $$$THROWONERROR(sc, pagamentoStmt.%Prepare(pagamentoSql))
        Set pagamentoRset = pagamentoStmt.%Execute(rset.%Get("ID"))
        While pagamentoRset.%Next() {
            Set pagamento = {}
            Set pagamento.id = pagamentoRset.%Get("ID")
            Set pagamento.valor = pagamentoRset.%Get("Valor")
            Set pagamento.dataHora = pagamentoRset.%Get("DataHora")
            Set pagamento.formaPagamento = pagamentoRset.%Get("FormaPagamento")
            Set pagamento.referencia = pagamentoRset.%Get("Referencia")
            Do pagamentos.%Push(pagamento)
        }
        Set item.pagamentos = pagamentos
        Do array.%Push(item)
    }
    Quit array
}

ClassMethod RegistrarConta(pJson As %DynamicObject) As %Status
{
    Try {
        If '$IsObject(pJson) Return $$$ERROR($$$GeneralError, "Dados da conta inválidos.")
        If (pJson.tipo '= "Receber") && (pJson.tipo '= "Pagar") Return $$$ERROR($$$GeneralError, "Tipo de conta inválido.")
        If (pJson.descricao = "") || (pJson.dataVencimento = "") Return $$$ERROR($$$GeneralError, "Descrição e vencimento são obrigatórios.")
        Set valor = +$Get(pJson.valor)
        If valor <= 0 Return $$$ERROR($$$GeneralError, "Valor da conta deve ser maior que zero.")

        Set conta = ##class(ERP.Model.Conta).%New()
        Set conta.Tipo = pJson.tipo
        Set conta.Descricao = pJson.descricao
        Set conta.Valor = valor
        Set conta.ValorPago = 0
        Set conta.Status = "Aberta"
        Set conta.DataVencimento = pJson.dataVencimento
        Set conta.OrigemTipo = $Get(pJson.origemTipo, "")
        Set conta.OrigemNome = $Get(pJson.origemNome, "")
        Set conta.Usuario = $Get(pJson.usuario, "admin")
        $$$THROWONERROR(sc, conta.%Save())
        Return $$$OK
    }
    Catch ex {
        Return ex.AsStatus()
    }
}

ClassMethod RegistrarPagamento(pJson As %DynamicObject) As %Status
{
    // A payment must update its balance and cash movement atomically to avoid financial drift.
    TSTART
    Try {
        If '$IsObject(pJson) {
            Throw ##class(%Exception.General).%New("Dados do pagamento inválidos.")
        }
        If pJson.contaId = "" {
            Throw ##class(%Exception.General).%New("Conta obrigatória.")
        }
        Set valor = +$Get(pJson.valor)
        If valor <= 0 {
            Throw ##class(%Exception.General).%New("O valor do pagamento deve ser maior que zero.")
        }

        Set conta = ##class(ERP.Model.Conta).%OpenId(pJson.contaId)
        If '$IsObject(conta) {
            Throw ##class(%Exception.General).%New("Conta não encontrada.")
        }
        If (conta.Status = "Paga") || (conta.ValorPago >= conta.Valor) {
            Throw ##class(%Exception.General).%New("Esta conta já está totalmente paga.")
        }
        If valor > (conta.Valor - conta.ValorPago) {
            Throw ##class(%Exception.General).%New("O pagamento não pode exceder o saldo restante.")
        }

        Set pagamento = ##class(ERP.Model.ContaPagamento).%New()
        Set pagamento.Conta = conta
        Set pagamento.Valor = valor
        Set pagamento.FormaPagamento = $Get(pJson.formaPagamento, "")
        Set pagamento.Referencia = $Get(pJson.referencia, "")
        Set pagamento.Usuario = $Get(pJson.usuario, "admin")
        $$$THROWONERROR(sc, pagamento.%Save())

        Set conta.ValorPago = conta.ValorPago + valor
        If conta.ValorPago = conta.Valor {
            Set conta.Status = "Paga"
        } Else {
            Set conta.Status = "Parcial"
        }
        $$$THROWONERROR(sc, conta.%Save())

        Set movimento = ##class(ERP.Model.MovimentoCaixa).%New()
        If conta.Tipo = "Receber" {
            Set movimento.Tipo = "Entrada"
        } Else {
            Set movimento.Tipo = "Saida"
        }
        Set movimento.Descricao = "Pagamento de conta: " _ conta.Descricao
        Set movimento.Valor = valor
        Set movimento.Referencia = "Conta:" _ conta.%Id()
        Set movimento.Usuario = pagamento.Usuario
        $$$THROWONERROR(sc, movimento.%Save())

        TCOMMIT
        Return $$$OK
    }
    Catch ex {
        TROLLBACK
        Return ex.AsStatus()
    }
}

ClassMethod ResumoDRE() As %DynamicObject
{
    Set resumo = {}

    Set sqlEntrada = "SELECT COALESCE(SUM(Valor), 0) AS total FROM ERP_Model.MovimentoCaixa WHERE Tipo = 'Entrada'"
    Set stmtEntrada = ##class(%SQL.Statement).%New()
    $$$THROWONERROR(sc, stmtEntrada.%Prepare(sqlEntrada))
    Set rsetEntrada = stmtEntrada.%Execute()
    If rsetEntrada.%Next() {
        Set resumo.receita = rsetEntrada.%Get("total")
    } Else {
        Set resumo.receita = 0
    }

    Set sqlSaida = "SELECT COALESCE(SUM(Valor), 0) AS total FROM ERP_Model.MovimentoCaixa WHERE Tipo = 'Saida'"
    Set stmtSaida = ##class(%SQL.Statement).%New()
    $$$THROWONERROR(sc, stmtSaida.%Prepare(sqlSaida))
    Set rsetSaida = stmtSaida.%Execute()
    If rsetSaida.%Next() {
        Set resumo.despesas = rsetSaida.%Get("total")
    } Else {
        Set resumo.despesas = 0
    }

    Set sqlReceber = "SELECT COALESCE(SUM(Valor - ValorPago), 0) AS total FROM ERP_Model.Conta WHERE Tipo = 'Receber' AND Status <> 'Paga'"
    Set stmtReceber = ##class(%SQL.Statement).%New()
    $$$THROWONERROR(sc, stmtReceber.%Prepare(sqlReceber))
    Set rsetReceber = stmtReceber.%Execute()
    If rsetReceber.%Next() {
        Set resumo.contasReceber = rsetReceber.%Get("total")
    } Else {
        Set resumo.contasReceber = 0
    }

    Set sqlPagar = "SELECT COALESCE(SUM(Valor - ValorPago), 0) AS total FROM ERP_Model.Conta WHERE Tipo = 'Pagar' AND Status <> 'Paga'"
    Set stmtPagar = ##class(%SQL.Statement).%New()
    $$$THROWONERROR(sc, stmtPagar.%Prepare(sqlPagar))
    Set rsetPagar = stmtPagar.%Execute()
    If rsetPagar.%Next() {
        Set resumo.contasPagar = rsetPagar.%Get("total")
    } Else {
        Set resumo.contasPagar = 0
    }

    Set resumo.saldoCaixa = resumo.receita - resumo.despesas

    Quit resumo
}

}
