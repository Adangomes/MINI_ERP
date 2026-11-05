Class ERP.Model.PedidoVenda Extends %Persistent
{

Property DataHora As %TimeStamp [ InitialExpression = {$ZDATETIME($HOROLOG,3,1)} ];
Property ValorTotal As %Currency [ InitialExpression = 0 ];
Property QuantidadeItens As %Integer [ InitialExpression = 0 ];
Property Usuario As %String(MAXLEN = 50) [ InitialExpression = "admin" ];
Property TerminalId As %String(MAXLEN = 100);
Property TerminalNome As %String(MAXLEN = 100);

Index DataHoraIdx On DataHora;

}
