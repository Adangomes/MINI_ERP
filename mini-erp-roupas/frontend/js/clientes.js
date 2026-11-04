document.addEventListener('DOMContentLoaded', () => {
    carregarClientes();

    const form = document.getElementById('formCliente');
    if (form) {
        form.addEventListener('submit', async (e) => {
            e.preventDefault();
            const payload = {
                nome: document.getElementById('nomeCliente').value,
                email: document.getElementById('emailCliente').value,
                telefone: document.getElementById('telefoneCliente').value,
                tipoDocumento: document.getElementById('tipoDocumentoCliente').value,
                documento: document.getElementById('documentoCliente').value,
                endereco: document.getElementById('enderecoCliente').value,
                ativo: true
            };

            await apiRequest('/clientes', 'POST', payload);
            alert('Cliente salvo com sucesso!');
            form.reset();
            carregarClientes();
        });
    }
});

async function carregarClientes() {
    const tabela = document.getElementById('tbodyClientes');
    if (!tabela) return;

    try {
        const clientes = await apiRequest('/clientes');
        tabela.replaceChildren();

        clientes.forEach((cliente) => {
            const tr = document.createElement('tr');
            [`#${cliente.id}`, cliente.nome, cliente.documento, cliente.telefone, cliente.email,
                cliente.ativo ? 'Ativo' : 'Inativo'].forEach((value) => {
                const td = document.createElement('td');
                td.textContent = value || '-';
                tr.appendChild(td);
            });
            tabela.appendChild(tr);
        });
    } catch (error) {
        console.error(error);
    }
}
