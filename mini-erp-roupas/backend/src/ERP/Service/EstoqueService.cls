Class ERP.Service.EstoqueService
{

ClassMethod MigrarSaldoInicial() As %Status
{
    TSTART
    Try {
        Set stockSql = "SELECT ID, QtdEstoque FROM ERP_Model.ItemGrade WHERE QtdEstoque > 0"
        Set stockStmt = ##class(%SQL.Statement).%New()
        $$$THROWONERROR(sc, stockStmt.%Prepare(stockSql))
        Set stockRows = stockStmt.%Execute()

        Set checkStmt = ##class(%SQL.Statement).%New()
        $$$THROWONERROR(sc, checkStmt.%Prepare("SELECT ID FROM ERP_Model.MovimentoEstoque WHERE ItemGrade = ?"))
        While stockRows.%Next() {
            Set gradeId = stockRows.%Get("ID")
            Set saldoAtual = stockRows.%Get("QtdEstoque")
            Set movements = checkStmt.%Execute(gradeId)
            Set hasMovement = movements.%Next()
            If 'hasMovement {
                Set grade = ##class(ERP.Model.ItemGrade).%OpenId(gradeId)
                $$$THROWONERROR(sc, ..RegistrarMovimento(grade, "Ajuste", saldoAtual, 0, saldoAtual, "Saldo inicial migrado", "", "admin", "", ""))
            }
        }

        TCOMMIT
        Return $$$OK
    }
    Catch ex {
        TROLLBACK
        Return ex.AsStatus()
    }
}

ClassMethod RegistrarMovimento(pGrade As ERP.Model.ItemGrade, pTipo As %String, pQuantidade As %Integer, pSaldoAnterior As %Integer, pSaldoAtual As %Integer, pOrigem As %String, pReferencia As %String, pUsuario As %String, pTerminalId As %String, pTerminalNome As %String) As %Status
{
    Set movimento = ##class(ERP.Model.MovimentoEstoque).%New()
    Set movimento.ItemGrade = pGrade
    Set movimento.Tipo = pTipo
    Set movimento.Quantidade = pQuantidade
    Set movimento.SaldoAnterior = pSaldoAnterior
    Set movimento.SaldoAtual = pSaldoAtual
    Set movimento.Origem = pOrigem
    Set movimento.Referencia = pReferencia
    Set movimento.Usuario = pUsuario
    Set movimento.TerminalId = pTerminalId
    Set movimento.TerminalNome = pTerminalNome
    Return movimento.%Save()
}

ClassMethod ListarMovimentos() As %DynamicArray
{
    Set array = []
    Set sql = "SELECT ID, DataHora, ItemGrade, Tipo, Quantidade, SaldoAnterior, SaldoAtual, Origem, Referencia, Usuario, TerminalId, TerminalNome FROM ERP_Model.MovimentoEstoque ORDER BY DataHora DESC, ID DESC"
    Set statement = ##class(%SQL.Statement).%New()
    $$$THROWONERROR(sc, statement.%Prepare(sql))
    Set rset = statement.%Execute()

    While rset.%Next() {
        Set item = {}
        Set item.id = rset.%Get("ID")
        Set item.dataHora = rset.%Get("DataHora")
        Set item.tipo = rset.%Get("Tipo")
        Set item.quantidade = rset.%Get("Quantidade")
        Set item.saldoAnterior = rset.%Get("SaldoAnterior")
        Set item.saldoAtual = rset.%Get("SaldoAtual")
        Set item.origem = rset.%Get("Origem")
        Set item.referencia = rset.%Get("Referencia")
        Set item.usuario = rset.%Get("Usuario")
        Set item.terminalId = rset.%Get("TerminalId")
        Set item.terminalNome = rset.%Get("TerminalNome")

        Set grade = ##class(ERP.Model.ItemGrade).%OpenId(rset.%Get("ItemGrade"))
        If $IsObject(grade) {
            Set item.tamanho = grade.Tamanho
            Set item.cor = grade.Cor
            Set item.codigoBarra = grade.CodigoBarra
            If $IsObject(grade.Produto) {
                Set item.produto = grade.Produto.Nome
            }
        }
        Do array.%Push(item)
    }

    Quit array
}

}
