Class ERP.Model.Compra Extends %Persistent
{

Property DataCompra As %TimeStamp [ InitialExpression = {$ZDATETIME($HOROLOG,3,1)} ];
Property Fornecedor As ERP.Model.Fornecedor [ Required ];
Property ValorTotal As %Currency [ Required ];
Property Status As %String(VALUELIST = ",Aberta,Confirmada,Cancelada") [ InitialExpression = "Aberta" ];
Property Observacao As %String(MAXLEN = 200);
Property Usuario As %String(MAXLEN = 50) [ InitialExpression = "admin" ];
Property TerminalId As %String(MAXLEN = 100);
Property TerminalNome As %String(MAXLEN = 100);

Index FornecedorIdx On Fornecedor;

ClassMethod ObterPorId(pId As %String) As ERP.Model.Compra
{
    Quit ..%OpenId(pId)
}

}
