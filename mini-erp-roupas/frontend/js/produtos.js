document.addEventListener('DOMContentLoaded', () => {
    carregarProdutos();

    const form = document.getElementById('formProduto');
    if (form) {
        form.addEventListener('submit', async (e) => {
            e.preventDefault();
            const payload = {
                nome: document.getElementById('nome').value,
                categoria: document.getElementById('categoria').value,
                precoBase: parseFloat(document.getElementById('precoBase').value),
                tamanho: document.getElementById('tamanho').value,
                cor: document.getElementById('cor').value,
                quantidade: parseInt(document.getElementById('quantidade').value),
                codigoBarra: document.getElementById('codigoBarra').value
            };

            await apiRequest('/produtos', 'POST', payload);
            alert('Produto/Estoque cadastrado com sucesso!');
            form.reset();
            carregarProdutos();
        });
    }
});

async function carregarProdutos() {
    const tabela = document.getElementById('tbodyProdutos');
    if (!tabela) return;

    try {
        const produtos = await apiRequest('/produtos');
        tabela.innerHTML = '';

        produtos.forEach(p => {
            let gradesHtml = p.grades.map(g => 
                `<span class="badge badge-stock">${g.tamanho} (${g.cor}): ${g.qtdEstoque} un</span>`
            ).join(' ');

            const tr = document.createElement('tr');
            tr.innerHTML = `
                <td>#${p.id}</td>
                <td><strong>${p.nome}</strong></td>
                <td>${p.categoria}</td>
                <td>R$ ${p.precoBase.toFixed(2)}</td>
                <td>${gradesHtml || 'Sem grade'}</td>
            `;
            tabela.appendChild(tr);
        });
    } catch (e) {
        console.error(e);
    }
}
