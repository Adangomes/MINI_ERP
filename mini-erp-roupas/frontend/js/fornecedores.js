document.addEventListener('DOMContentLoaded', () => {
    carregarFornecedores();

    const form = document.getElementById('formFornecedor');
    if (form) {
        form.addEventListener('submit', async (e) => {
            e.preventDefault();
            const payload = {
                nome: document.getElementById('nomeFornecedor').value,
                email: document.getElementById('emailFornecedor').value,
                telefone: document.getElementById('telefoneFornecedor').value,
                documento: document.getElementById('documentoFornecedor').value,
                endereco: document.getElementById('enderecoFornecedor').value,
                observacao: document.getElementById('observacaoFornecedor').value,
                ativo: true
            };

            await apiRequest('/fornecedores', 'POST', payload);
            alert('Fornecedor salvo com sucesso!');
            form.reset();
            carregarFornecedores();
        });
    }
});

async function carregarFornecedores() {
    const tabela = document.getElementById('tbodyFornecedores');
    if (!tabela) return;

    try {
        const fornecedores = await apiRequest('/fornecedores');
        tabela.replaceChildren();

        fornecedores.forEach((fornecedor) => {
            const tr = document.createElement('tr');
            [`#${fornecedor.id}`, fornecedor.nome, fornecedor.documento, fornecedor.telefone, fornecedor.email,
                fornecedor.ativo ? 'Ativo' : 'Inativo'].forEach((value) => {
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
