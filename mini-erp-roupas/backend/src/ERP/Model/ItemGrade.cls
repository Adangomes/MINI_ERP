/// Define a classe persistente que representa uma variante de produto no estoque.
Class ERP.Model.ItemGrade Extends %Persistent
{

/// Guarda o produto ao qual esta variante pertence; a referência é obrigatória.
Property Produto As ERP.Model.Produto [ Required ];
/// Guarda um dos tamanhos aceitos e exige seu preenchimento.
Property Tamanho As %String(VALUELIST = ",PP,P,M,G,GG,XGG") [ Required ];
/// Guarda a cor da variante e limita o texto a 30 caracteres.
Property Cor As %String(MAXLEN = 30) [ Required ];
/// Guarda a quantidade disponível; começa em zero e é obrigatória.
Property QtdEstoque As %Integer [ InitialExpression = 0, Required ];
/// Guarda o código de barras, que é opcional e limitado a 50 caracteres.
Property CodigoBarra As %String(MAXLEN = 50);

/// Declara um índice composto para localizar cada combinação de produto, tamanho e cor.
Index SKUIndex On (Produto, Tamanho, Cor) [ Unique ];

/// Fecha a definição da classe.
}
