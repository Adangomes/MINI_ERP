/// Define Venda como entidade persistente que registra cada operação do caixa.
Class ERP.Model.Venda Extends %Persistent
{

/// Registra a data e a hora da venda; a expressão inicial usa o horário atual do IRIS.
Property DataHora As %TimeStamp [ InitialExpression = {$ZDATETIME($HOROLOG,3,1)} ];
/// Guarda a variante vendida e exige que ela exista.
Property ItemGrade As ERP.Model.ItemGrade [ Required ];
/// Guarda a quantidade de unidades vendidas e exige seu preenchimento.
Property Quantidade As %Integer [ Required ];
/// Guarda o total cobrado pela venda e exige seu preenchimento.
Property ValorTotal As %Currency [ Required ];
/// Guarda o usuário responsável e assume admin quando não informado.
Property Usuario As %String [ InitialExpression = "admin" ];

/// Fecha a definição da classe.
}
