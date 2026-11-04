Class ERP.Model.CompraItem Extends %Persistent
{

Property Compra As ERP.Model.Compra [ Required ];
Property ItemGrade As ERP.Model.ItemGrade [ Required ];
Property Quantidade As %Integer [ Required ];
Property CustoUnitario As %Currency [ Required ];
Property ValorTotal As %Currency [ Required ];

Index CompraIdx On Compra;
Index GradeIdx On ItemGrade;

ClassMethod ObterPorId(pId As %String) As ERP.Model.CompraItem
{
    Quit ..%OpenId(pId)
}

}
