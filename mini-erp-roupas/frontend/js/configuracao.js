document.addEventListener('DOMContentLoaded', () => {
    const form = document.getElementById('formConfiguracao');
    const terminal = getTerminalContext();
    document.getElementById('terminalId').value = terminal.terminalId;
    document.getElementById('terminalNome').value = localStorage.getItem('erp-terminal-name') || terminal.terminalNome;
    document.getElementById('leitorAtivo').checked = localStorage.getItem('erp-scanner-enabled') !== 'false';
    document.getElementById('imprimirAutomatico').checked = localStorage.getItem('erp-auto-print') === 'true';

    form.addEventListener('submit', (event) => {
        event.preventDefault();
        const nome = document.getElementById('terminalNome').value.trim();
        if (!nome) {
            return;
        }

        localStorage.setItem('erp-terminal-name', nome);
        localStorage.setItem('erp-scanner-enabled', String(document.getElementById('leitorAtivo').checked));
        localStorage.setItem('erp-auto-print', String(document.getElementById('imprimirAutomatico').checked));
        document.getElementById('statusConfiguracao').textContent = 'Configuração salva neste navegador.';
    });

    document.getElementById('testarImpressao').addEventListener('click', () => {
        const area = document.getElementById('printArea');
        area.replaceChildren();
        const title = document.createElement('h2');
        title.textContent = 'Teste de impressão - Mini ERP';
        const details = document.createElement('p');
        details.textContent = `${document.getElementById('terminalNome').value} · ${new Date().toLocaleString('pt-BR')}`;
        area.append(title, details);
        window.print();
        document.getElementById('statusConfiguracao').textContent = 'Janela de impressão aberta. Selecione a impressora térmica instalada.';
    });
});
