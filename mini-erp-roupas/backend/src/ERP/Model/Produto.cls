// Define Produto como entidade persistente armazenada no banco de dados do IRIS.
Class ERP.Model.Produto Extends %Persistent
{

// Armazena o nome obrigatório do produto, limitado a 100 caracteres.
Property Nome As %String(MAXLEN = 100) [ Required ];
// Armazena a categoria obrigatória do produto, limitada a 50 caracteres.
Property Categoria As %String(MAXLEN = 50) [ Required ];
// Armazena o preço base obrigatório usando o tipo monetário do IRIS.
Property PrecoBase As %Currency [ Required ];

// Cria um índice para filtrar produtos pela categoria.
Index CategoriaIdx On Categoria;

// Define um método de classe que recebe o identificador do produto e devolve o objeto persistido.
ClassMethod ObterPorId(pId As %String) As ERP.Model.Produto
{
    // Abre o registro correspondente ao ID e retorna o objeto, ou vazio se não existir.
    Quit ..%OpenId(pId)
}

// Fecha a definição da classe.
}
