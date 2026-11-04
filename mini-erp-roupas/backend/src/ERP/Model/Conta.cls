Class ERP.Model.Conta Extends %Persistent
{

Property Tipo As %String(VALUELIST = ",Receber,Pagar") [ Required ];
Property Descricao As %String(MAXLEN = 200) [ Required ];
Property Valor As %Currency [ Required ];
Property ValorPago As %Currency [ InitialExpression = 0 ];
Property Status As %String(VALUELIST = ",Aberta,Parcial,Paga,Vencida") [ InitialExpression = "Aberta" ];
Property DataVencimento As %Date [ Required ];
Property DataCadastro As %TimeStamp [ InitialExpression = {$ZDATETIME($HOROLOG,3,1)} ];
Property OrigemTipo As %String(MAXLEN = 30);
Property OrigemNome As %String(MAXLEN = 100);
Property Usuario As %String(MAXLEN = 50) [ InitialExpression = "admin" ];

Index TipoVencimentoIdx On (Tipo, DataVencimento);

ClassMethod ObterPorId(pId As %String) As ERP.Model.Conta
{
    Quit ..%OpenId(pId)
}

}
