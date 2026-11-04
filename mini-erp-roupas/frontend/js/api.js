const API_URL = '/api';

function getTerminalContext() {
    let terminalId = localStorage.getItem('erp-terminal-id');
    if (!terminalId) {
        terminalId = typeof crypto !== 'undefined' && crypto.randomUUID
            ? crypto.randomUUID()
            : `terminal-${Date.now()}-${Math.random().toString(36).slice(2, 10)}`;
        localStorage.setItem('erp-terminal-id', terminalId);
    }

    return {
        usuario: localStorage.getItem('usuario') || 'admin',
        terminalId,
        terminalNome: localStorage.getItem('erp-terminal-name') || `Caixa ${terminalId.slice(0, 8)}`
    };
}

async function apiRequest(endpoint, method = 'GET', body = null) {
    const headers = { 'Content-Type': 'application/json' };
    const token = localStorage.getItem('token');
    if (token) headers['Authorization'] = `Bearer ${token}`;

    const config = { method, headers };
    if (body) {
        const requestBody = method !== 'GET' && endpoint !== '/login'
            ? { ...body, ...getTerminalContext() }
            : body;
        config.body = JSON.stringify(requestBody);
    }

    try {
        const response = await fetch(`${API_URL}${endpoint}`, config);
        
        // Lê o texto primeiro para garantir que não rebenta se vier HTML do Nginx (502)
        const textResponse = await response.text();
        let data;
        try {
            data = JSON.parse(textResponse);
        } catch (e) {
            throw new Error("Servidor backend indisponível (502 Bad Gateway).");
        }

        if (!response.ok) {
            throw new Error(data.mensagem || 'Erro na requisição');
        }
        return data;
    } catch (err) {
        alert(err.message || 'Erro de comunicação com o servidor');
        throw err;
    }
}