Class ERP.Model.Cliente Extends %Persistent
{

Property Nome As %String(MAXLEN = 100) [ Required ];
Property Email As %String(MAXLEN = 100);
Property Telefone As %String(MAXLEN = 30);
Property TipoDocumento As %String(VALUELIST = ",CPF,CNPJ") [ InitialExpression = "CPF" ];
Property Documento As %String(MAXLEN = 30);
Property Endereco As %String(MAXLEN = 200);
Property Ativo As %Boolean [ InitialExpression = 1 ];
Property DataCadastro As %TimeStamp [ InitialExpression = {$ZDATETIME($HOROLOG,3,1)} ];

Index DocumentoIdx On Documento;

ClassMethod ObterPorId(pId As %String) As ERP.Model.Cliente
{
    Quit ..%OpenId(pId)
}

}
