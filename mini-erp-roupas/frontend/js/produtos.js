document.addEventListener('DOMContentLoaded', () => {
    carregarProdutos();
    carregarMovimentosEstoque();
    document.getElementById('atualizarMovimentos')?.addEventListener('click', carregarMovimentosEstoque);

    const form = document.getElementById('formProduto');
    form?.addEventListener('submit', async (event) => {
        event.preventDefault();
        const payload = {
            nome: document.getElementById('nome').value.trim(),
            categoria: document.getElementById('categoria').value.trim(),
            precoBase: Number.parseFloat(document.getElementById('precoBase').value),
            tamanho: document.getElementById('tamanho').value,
            cor: document.getElementById('cor').value.trim(),
            quantidade: Number.parseInt(document.getElementById('quantidade').value, 10),
            codigoBarra: document.getElementById('codigoBarra').value.trim()
        };

        try {
            await apiRequest('/produtos', 'POST', payload);
            alert('Produto/estoque cadastrado com sucesso!');
            form.reset();
            await Promise.all([carregarProdutos(), carregarMovimentosEstoque()]);
        } catch (error) {
            console.error('Não foi possível salvar o produto:', error);
        }
    });
});

async function carregarProdutos() {
    const tabela = document.getElementById('tbodyProdutos');
    if (!tabela) return;

    try {
        const produtos = await apiRequest('/produtos');
        tabela.replaceChildren();
        produtos.forEach((produto) => {
            const linha = document.createElement('tr');
            const valores = [
                `#${produto.id}`,
                produto.nome,
                produto.categoria,
                Number(produto.precoBase || 0).toLocaleString('pt-BR', { style: 'currency', currency: 'BRL' })
            ];
            valores.forEach((valor) => {
                const celula = document.createElement('td');
                celula.textContent = valor || '-';
                linha.appendChild(celula);
            });
            const grades = document.createElement('td');
            (produto.grades || []).forEach((grade) => {
                const badge = document.createElement('span');
                badge.className = 'badge badge-stock';
                badge.textContent = `${grade.tamanho} (${grade.cor}): ${grade.qtdEstoque} un`;
                grades.appendChild(badge);
                grades.append(' ');
            });
            if (!produto.grades?.length) grades.textContent = 'Sem grade';
            linha.appendChild(grades);
            tabela.appendChild(linha);
        });
    } catch (error) {
        console.error('Não foi possível carregar os produtos:', error);
    }
}

async function carregarMovimentosEstoque() {
    const tabela = document.getElementById('tbodyMovimentosEstoque');
    const resumo = document.getElementById('resumoMovimentos');
    if (!tabela || !resumo) return;

    try {
        const movimentos = await apiRequest('/estoque/movimentos');
        tabela.replaceChildren();
        movimentos.forEach((movimento) => {
            const dataHora = new Date(`${String(movimento.dataHora).replace(' ', 'T')}Z`);
            const terminal = movimento.terminalNome
                ? `${movimento.terminalNome} (${String(movimento.terminalId || '').slice(0, 8) || 'sem ID'})`
                : 'Não identificado';
            const linha = document.createElement('tr');
            [
                Number.isNaN(dataHora.getTime()) ? movimento.dataHora : dataHora.toLocaleString('pt-BR'),
                movimento.tipo,
                `${movimento.produto || 'Produto'} · ${movimento.tamanho || '-'} / ${movimento.cor || '-'}`,
                `${movimento.tipo === 'Saida' ? '-' : '+'}${movimento.quantidade}`,
                movimento.saldoAtual,
                movimento.origem || '-',
                movimento.usuario || '-',
                terminal
            ].forEach((valor) => {
                const celula = document.createElement('td');
                celula.textContent = valor;
                linha.appendChild(celula);
            });
            tabela.appendChild(linha);
        });
        resumo.textContent = movimentos.length
            ? `${movimentos.length} movimentação(ões) registrada(s).`
            : 'Ainda não há movimentações registradas.';
    } catch (error) {
        resumo.textContent = 'Não foi possível carregar as movimentações de estoque.';
        console.error('Falha ao carregar movimentações:', error);
    }
}
