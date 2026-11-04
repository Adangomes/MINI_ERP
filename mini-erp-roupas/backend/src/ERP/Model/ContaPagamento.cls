Class ERP.Model.ContaPagamento Extends %Persistent
{

Property Conta As ERP.Model.Conta [ Required ];
Property Valor As %Currency [ Required ];
Property DataHora As %TimeStamp [ InitialExpression = {$ZDATETIME($HOROLOG,3,1)} ];
Property FormaPagamento As %String(MAXLEN = 30);
Property Referencia As %String(MAXLEN = 100);
Property Usuario As %String(MAXLEN = 50) [ InitialExpression = "admin" ];

Index ContaDataIdx On (Conta, DataHora);

}
