Class ERP.Model.Fornecedor Extends %Persistent
{

Property Nome As %String(MAXLEN = 100) [ Required ];
Property Email As %String(MAXLEN = 100);
Property Telefone As %String(MAXLEN = 30);
Property Documento As %String(MAXLEN = 30);
Property Endereco As %String(MAXLEN = 200);
Property Ativo As %Boolean [ InitialExpression = 1 ];
Property Observacao As %String(MAXLEN = 200);
Property DataCadastro As %TimeStamp [ InitialExpression = {$ZDATETIME($HOROLOG,3,1)} ];

Index DocumentoIdx On Documento;

ClassMethod ObterPorId(pId As %String) As ERP.Model.Fornecedor
{
    Quit ..%OpenId(pId)
}

}
