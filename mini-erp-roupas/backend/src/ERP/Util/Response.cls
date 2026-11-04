/// Define utilitários compartilhados para responder às requisições HTTP da API.
Class ERP.Util.Response
{

/// Envia um status HTTP e serializa o objeto dinâmico como JSON.
ClassMethod Send(pStatus As %String = "200 OK", pData As %DynamicAbstractObject = "") As %Status
{
    // Define o código e o texto do status HTTP da resposta.
    Set %response.Status = pStatus
    // Informa ao cliente que o conteúdo retornado está no formato JSON.
    Set %response.ContentType = "application/json"
    
    // Permite que clientes web de qualquer origem acessem esta API.
    Do %response.SetHeader("Access-Control-Allow-Origin", "*")
    // Declara os métodos HTTP aceitos pela API.
    Do %response.SetHeader("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
    // Declara os cabeçalhos HTTP que o navegador pode enviar.
    Do %response.SetHeader("Access-Control-Allow-Headers", "Content-Type, Authorization")
    
    // Verifica se os dados recebidos são um objeto dinâmico.
    If $IsObject(pData) {
        // Converte o objeto ou array dinâmico para texto JSON e o escreve na resposta.
        Write pData.%ToJSON()
    } Else {
        // Devolve um objeto JSON vazio quando não há dados serializáveis.
        Write "{}"
    }
    // Indica que o método de resposta terminou sem erro.
    Quit $$$OK
}

/// Cria e envia uma resposta JSON padronizada para erros.
ClassMethod SendError(pStatus As %String = "400 Bad Request", pMessage As %String = "Erro desconhecido") As %Status
{
    // Cria o objeto JSON que representa o resultado da operação.
    Set res = {}
    // Marca a operação como malsucedida.
    Set res.sucesso = 0
    // Inclui a mensagem que explica a falha.
    Set res.mensagem = pMessage
    // Reutiliza Send para escrever o status HTTP e o corpo JSON.
    Quit ..Send(pStatus, res)
}

/// Cria e envia uma resposta JSON padronizada para operações bem-sucedidas.
ClassMethod SendSuccess(pMessage As %String = "Sucesso", pData As %DynamicObject = "") As %Status
{
    // Cria o objeto JSON que representa o resultado da operação.
    Set res = {}
    // Marca a operação como bem-sucedida.
    Set res.sucesso = 1
    // Inclui a mensagem de sucesso.
    Set res.mensagem = pMessage
    // Inclui dados adicionais somente quando foi recebido um objeto.
    If $IsObject(pData) {
        // Mantém os dados em "dados" para o frontend encontrar de forma consistente.
        Set res.dados = pData
    }
    // Envia a resposta de sucesso com status HTTP 200.
    Quit ..Send("200 OK", res)
}

/// Fecha a definição da classe.
}
