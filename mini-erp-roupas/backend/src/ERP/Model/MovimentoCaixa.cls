Class ERP.Model.MovimentoCaixa Extends %Persistent
{

Property Tipo As %String(VALUELIST = ",Entrada,Saida") [ Required ];
Property Descricao As %String(MAXLEN = 200) [ Required ];
Property Valor As %Currency [ Required ];
Property DataHora As %TimeStamp [ InitialExpression = {$ZDATETIME($HOROLOG,3,1)} ];
Property Referencia As %String(MAXLEN = 100);
Property Usuario As %String(MAXLEN = 50) [ InitialExpression = "admin" ];

Index TipoDataIdx On (Tipo, DataHora);

ClassMethod ObterPorId(pId As %String) As ERP.Model.MovimentoCaixa
{
    Quit ..%OpenId(pId)
}

}
