document.addEventListener('DOMContentLoaded', () => {
    const hoje = new Date();
    document.getElementById('vencimentoCompra').value =
        `${hoje.getFullYear()}-${String(hoje.getMonth() + 1).padStart(2, '0')}-${String(hoje.getDate()).padStart(2, '0')}`;
    carregarOpcoesFornecedores();
    carregarOpcoesSKU();
    carregarCompras();

    const formCompra = document.getElementById('formCompra');
    if (formCompra) {
        formCompra.addEventListener('submit', async (e) => {
            e.preventDefault();
            const payload = {
                fornecedorId: document.getElementById('selectFornecedor').value,
                status: 'Aberta',
                dataVencimento: document.getElementById('vencimentoCompra').value,
                observacao: document.getElementById('obsCompra').value,
                itens: [{
                    skuId: document.getElementById('selectSKUCompra').value,
                    quantidade: parseInt(document.getElementById('qtdCompra').value),
                    custoUnitario: parseFloat(document.getElementById('custoUnitarioCompra').value)
                }]
            };

            await apiRequest('/compras', 'POST', payload);
            alert('Compra / entrada de estoque registrada com sucesso!');
            formCompra.reset();
            document.getElementById('vencimentoCompra').value =
                `${hoje.getFullYear()}-${String(hoje.getMonth() + 1).padStart(2, '0')}-${String(hoje.getDate()).padStart(2, '0')}`;
            await carregarCompras();
        });
    }
});

async function carregarOpcoesFornecedores() {
    const select = document.getElementById('selectFornecedor');
    if (!select) return;

    try {
        const fornecedores = await apiRequest('/fornecedores');
        select.innerHTML = '<option value="">Selecione o fornecedor</option>';
        fornecedores.forEach((fornecedor) => {
            const opt = document.createElement('option');
            opt.value = fornecedor.id;
            opt.textContent = fornecedor.nome;
            select.appendChild(opt);
        });
    } catch (error) {
        console.error(error);
    }
}

async function carregarOpcoesSKU() {
    const select = document.getElementById('selectSKUCompra');
    if (!select) return;

    try {
        const produtos = await apiRequest('/produtos');
        select.innerHTML = '<option value="">Selecione a variante</option>';
        produtos.forEach((p) => {
            p.grades.forEach((g) => {
                const opt = document.createElement('option');
                opt.value = g.id;
                opt.textContent = `${p.nome} - ${g.tamanho} / ${g.cor}`;
                select.appendChild(opt);
            });
        });
    } catch (error) {
        console.error(error);
    }
}

async function carregarCompras() {
    const tabela = document.getElementById('tbodyCompras');
    if (!tabela) return;

    try {
        const compras = await apiRequest('/compras');
        tabela.replaceChildren();

        compras.forEach((compra) => {
            const tr = document.createElement('tr');
            const itens = (compra.itens || [])
                .map(item => `${item.produto} (${item.tamanho}/${item.cor}) x${item.quantidade}`)
                .join('\n') || '-';
            const valores = [
                `#${compra.id}`,
                compra.dataCompra,
                compra.fornecedor,
                itens,
                Number(compra.valorTotal || 0).toLocaleString('pt-BR', { style: 'currency', currency: 'BRL' }),
                compra.status || 'Aberta'
            ];
            valores.forEach((value, index) => {
                const td = document.createElement('td');
                td.textContent = value || '-';
                if (index === 3) td.className = 'purchase-items';
                tr.appendChild(td);
            });
            tabela.appendChild(tr);
        });
    } catch (error) {
        console.error(error);
    }
}
