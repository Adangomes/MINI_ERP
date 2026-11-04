Class ERP.Model.MovimentoEstoque Extends %Persistent
{

Property DataHora As %TimeStamp [ InitialExpression = {$ZDATETIME($HOROLOG,3,1)} ];
Property ItemGrade As ERP.Model.ItemGrade [ Required ];
Property Tipo As %String(VALUELIST = ",Entrada,Saida,Ajuste") [ Required ];
Property Quantidade As %Integer [ Required ];
Property SaldoAnterior As %Integer [ Required ];
Property SaldoAtual As %Integer [ Required ];
Property Origem As %String(MAXLEN = 60) [ Required ];
Property Referencia As %String(MAXLEN = 100);
Property Usuario As %String(MAXLEN = 50) [ InitialExpression = "admin" ];
Property TerminalId As %String(MAXLEN = 100);
Property TerminalNome As %String(MAXLEN = 100);

Index ItemDataIdx On (ItemGrade, DataHora);

}
