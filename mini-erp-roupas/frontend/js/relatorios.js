let vendasPeriodo = [];

document.addEventListener('DOMContentLoaded', async () => {
    configurarPeriodo();
    document.getElementById('formFiltrosRelatorio').addEventListener('submit', async (event) => {
        event.preventDefault();
        await carregarRelatorio();
    });
    document.getElementById('periodoRelatorio').addEventListener('change', alternarPeriodo);
    document.getElementById('filtroProduto').addEventListener('change', renderizarRelatorio);
    document.getElementById('filtroTerminal').addEventListener('change', renderizarRelatorio);
    document.getElementById('exportarRelatorio').addEventListener('click', exportarCSV);
    await carregarProdutos();
    await carregarRelatorio();
});

function configurarPeriodo() {
    const hoje = new Date();
    const ano = hoje.getFullYear();
    const mes = String(hoje.getMonth() + 1).padStart(2, '0');
    const dia = String(hoje.getDate()).padStart(2, '0');
    document.getElementById('dataRelatorio').value = `${ano}-${mes}-${dia}`;
    document.getElementById('mesRelatorio').value = `${ano}-${mes}`;
    document.getElementById('anoRelatorio').value = ano;
    alternarPeriodo();
}

function alternarPeriodo() {
    const periodo = document.getElementById('periodoRelatorio').value;
    document.getElementById('campoData').hidden = periodo !== 'dia';
    document.getElementById('campoMes').hidden = periodo !== 'mes';
    document.getElementById('campoAno').hidden = periodo !== 'ano';
}

async function carregarProdutos() {
    try {
        const produtos = await apiRequest('/produtos');
        const select = document.getElementById('filtroProduto');
        const nomes = [...new Set(produtos.map((produto) => produto.nome))].sort();
        nomes.forEach((nome) => {
            const option = new Option(nome, nome);
            select.appendChild(option);
        });
    } catch (error) {
        mostrarStatus(`Não foi possível carregar os produtos para o filtro: ${error.message}`, true);
    }
}

async function carregarRelatorio() {
    const periodo = document.getElementById('periodoRelatorio').value;
    const data = periodo === 'dia'
        ? document.getElementById('dataRelatorio').value
        : periodo === 'mes'
            ? document.getElementById('mesRelatorio').value
            : document.getElementById('anoRelatorio').value;
    const params = new URLSearchParams({ periodo, data });
    mostrarStatus('Carregando relatório...', false);

    try {
        vendasPeriodo = await apiRequest(`/vendas?${params}`);
        atualizarOpcoesTerminal();
        renderizarRelatorio();
        mostrarStatus(vendasPeriodo.length ? '' : 'Não há vendas registradas neste período.', false);
    } catch (error) {
        vendasPeriodo = [];
        renderizarRelatorio();
        mostrarStatus(`Não foi possível carregar o relatório: ${error.message}`, true);
    }
}

function atualizarOpcoesTerminal() {
    const select = document.getElementById('filtroTerminal');
    const selecionado = select.value;
    const terminais = [...new Set(vendasPeriodo.map((venda) => venda.terminalNome).filter(Boolean))].sort();
    select.replaceChildren(new Option('Todos os caixas', ''));
    terminais.forEach((terminal) => select.appendChild(new Option(terminal, terminal)));
    if (terminais.includes(selecionado)) select.value = selecionado;
}

function obterVendasFiltradas() {
    const produto = document.getElementById('filtroProduto').value;
    const terminal = document.getElementById('filtroTerminal').value;
    return vendasPeriodo.filter((venda) =>
        (!produto || venda.produto === produto) &&
        (!terminal || venda.terminalNome === terminal)
    );
}

function renderizarRelatorio() {
    const vendas = obterVendasFiltradas();
    const total = vendas.reduce((soma, venda) => soma + Number(venda.valorTotal || 0), 0);
    const pecas = vendas.reduce((soma, venda) => soma + Number(venda.quantidade || 0), 0);
    const pedidos = new Map();
    vendas.forEach((venda) => {
        const id = venda.idVenda || `legacy-${venda.id}`;
        pedidos.set(id, (pedidos.get(id) || 0) + Number(venda.valorTotal || 0));
    });

    document.getElementById('kpiFaturamento').textContent = moeda(total);
    document.getElementById('kpiVendas').textContent = pedidos.size.toLocaleString('pt-BR');
    document.getElementById('kpiTicket').textContent = moeda(pedidos.size ? total / pedidos.size : 0);
    document.getElementById('kpiPecas').textContent = pecas.toLocaleString('pt-BR');
    document.getElementById('kpiPecasPorVenda').textContent = `${pedidos.size ? (pecas / pedidos.size).toFixed(1).replace('.', ',') : '0'} por pedido, em média`;
    renderizarGrafico(vendas);
    renderizarRanking(vendas);
    renderizarTabela(vendas);
}

function renderizarGrafico(vendas) {
    const container = document.getElementById('graficoVendas');
    container.replaceChildren();
    const buckets = new Map();
    vendas.forEach((venda) => {
        const dataHora = String(venda.dataHora || '');
        const chave = chaveIntervalo(dataHora);
        if (chave) buckets.set(chave, (buckets.get(chave) || 0) + Number(venda.valorTotal || 0));
    });

    const dados = [...buckets.entries()].sort(([a], [b]) => a.localeCompare(b));
    if (!dados.length) {
        container.appendChild(textoVazio('Sem vendas para exibir no gráfico.'));
        return;
    }

    const svg = document.createElementNS('http://www.w3.org/2000/svg', 'svg');
    svg.setAttribute('viewBox', '0 0 760 260');
    svg.setAttribute('role', 'img');
    svg.setAttribute('aria-label', 'Faturamento agregado ao longo do período selecionado');
    const largura = Math.max(760, dados.length * 54);
    const topo = 18;
    const base = 205;
    const graficoAltura = base - topo;
    const maior = Math.max(...dados.map(([, valor]) => valor), 1);
    const inicio = 52;
    const passo = (largura - inicio - 10) / dados.length;

    [0, 0.5, 1].forEach((fracao) => {
        const y = base - fracao * graficoAltura;
        const linha = svgElemento('line', { x1: 45, y1: y, x2: largura - 10, y2: y, class: 'chart-grid-line' });
        svg.appendChild(linha);
        const marca = svgElemento('text', { x: 40, y: y - 5, class: 'chart-axis-label', 'text-anchor': 'end' });
        marca.textContent = moedaCurta(maior * fracao);
        svg.appendChild(marca);
    });

    dados.forEach(([chave, valor], index) => {
        const altura = Math.max((valor / maior) * graficoAltura, 2);
        const x = inicio + index * passo;
        const barra = svgElemento('rect', {
            x,
            y: base - altura,
            width: Math.max(Math.min(passo * 0.58, 42), 8),
            height: altura,
            rx: 5,
            class: 'chart-bar'
        });
        const dica = svgElemento('title');
        dica.textContent = `${chave}: ${moeda(valor)}`;
        barra.appendChild(dica);
        svg.appendChild(barra);
        const rotulo = svgElemento('text', {
            x: x + Math.max(Math.min(passo * 0.58, 42), 8) / 2,
            y: 228,
            class: 'chart-axis-label',
            'text-anchor': 'middle'
        });
        rotulo.textContent = chave;
        svg.appendChild(rotulo);
    });

    svg.style.width = `${largura}px`;
    container.appendChild(svg);
}

function chaveIntervalo(dataHora) {
    if (!/^\d{4}-\d{2}-\d{2}/.test(dataHora)) return '';
    const periodo = document.getElementById('periodoRelatorio').value;
    if (periodo === 'ano') return dataHora.slice(5, 7);
    if (periodo === 'mes') return dataHora.slice(8, 10);
    const hora = dataHora.slice(11, 13);
    return /^\d{2}$/.test(hora) ? `${hora}h` : 'Dia';
}

function renderizarRanking(vendas) {
    const container = document.getElementById('rankingProdutos');
    container.replaceChildren();
    const ranking = new Map();
    vendas.forEach((venda) => {
        const nome = venda.produto || 'Produto não identificado';
        const atual = ranking.get(nome) || { quantidade: 0, valor: 0 };
        atual.quantidade += Number(venda.quantidade || 0);
        atual.valor += Number(venda.valorTotal || 0);
        ranking.set(nome, atual);
    });
    const dados = [...ranking.entries()].sort((a, b) => b[1].quantidade - a[1].quantidade).slice(0, 6);
    if (!dados.length) {
        container.appendChild(textoVazio('Ainda não há produtos vendidos neste período.'));
        return;
    }

    const maior = Math.max(...dados.map(([, item]) => item.quantidade), 1);
    dados.forEach(([nome, item], index) => {
        const linha = document.createElement('div');
        linha.className = 'ranking-row';
        const cabecalho = document.createElement('div');
        cabecalho.className = 'ranking-heading';
        const titulo = document.createElement('strong');
        titulo.textContent = `${index + 1}. ${nome}`;
        const quantidade = document.createElement('span');
        quantidade.textContent = `${item.quantidade} un`;
        cabecalho.append(titulo, quantidade);
        const trilho = document.createElement('div');
        trilho.className = 'ranking-track';
        const barra = document.createElement('span');
        barra.style.width = `${Math.max((item.quantidade / maior) * 100, 2)}%`;
        trilho.appendChild(barra);
        const detalhe = document.createElement('small');
        detalhe.textContent = moeda(item.valor);
        linha.append(cabecalho, trilho, detalhe);
        container.appendChild(linha);
    });
}

function renderizarTabela(vendas) {
    const tabela = document.getElementById('tbodyRelatorio');
    tabela.replaceChildren();
    const ordenadas = [...vendas].sort((a, b) => String(b.dataHora).localeCompare(String(a.dataHora)));
    ordenadas.forEach((venda) => {
        const data = new Date(String(venda.dataHora || '').replace(' ', 'T'));
        const linha = document.createElement('tr');
        [
            Number.isNaN(data.getTime()) ? venda.dataHora : data.toLocaleString('pt-BR'),
            venda.idVenda || `#${venda.id}`,
            venda.produto || '-',
            `${venda.tamanho || '-'} / ${venda.cor || '-'}`,
            venda.quantidade,
            moeda(venda.valorTotal),
            venda.usuario || '-',
            venda.terminalNome || '-'
        ].forEach((valor) => {
            const celula = document.createElement('td');
            celula.textContent = valor;
            linha.appendChild(celula);
        });
        tabela.appendChild(linha);
    });
    document.getElementById('resumoDetalhe').textContent = `${vendas.length} item(ns) · ${new Set(vendas.map((item) => item.idVenda || `legacy-${item.id}`)).size} venda(s)`;
}

function exportarCSV() {
    const vendas = obterVendasFiltradas();
    const cabecalho = ['Data e hora', 'Venda', 'Produto', 'Tamanho', 'Cor', 'Quantidade', 'Valor', 'Usuário', 'Caixa'];
    const linhas = vendas.map((venda) => [
        venda.dataHora,
        venda.idVenda || venda.id,
        venda.produto,
        venda.tamanho,
        venda.cor,
        venda.quantidade,
        venda.valorTotal,
        venda.usuario,
        venda.terminalNome
    ]);
    const csv = [cabecalho, ...linhas].map((linha) => linha.map(csvCampo).join(';')).join('\r\n');
    const arquivo = new Blob(['\uFEFF', csv], { type: 'text/csv;charset=utf-8' });
    const link = document.createElement('a');
    link.href = URL.createObjectURL(arquivo);
    link.download = `relatorio-vendas-${document.getElementById('periodoRelatorio').value}.csv`;
    link.click();
    URL.revokeObjectURL(link.href);
}

function csvCampo(valor) {
    const texto = String(valor ?? '');
    return `"${texto.replaceAll('"', '""')}"`;
}

function svgElemento(nome, atributos = {}) {
    const elemento = document.createElementNS('http://www.w3.org/2000/svg', nome);
    Object.entries(atributos).forEach(([chave, valor]) => elemento.setAttribute(chave, String(valor)));
    return elemento;
}

function textoVazio(texto) {
    const mensagem = document.createElement('p');
    mensagem.className = 'empty-state';
    mensagem.textContent = texto;
    return mensagem;
}

function moeda(valor) {
    return Number(valor || 0).toLocaleString('pt-BR', { style: 'currency', currency: 'BRL' });
}

function moedaCurta(valor) {
    if (valor >= 1000) return `R$ ${(valor / 1000).toLocaleString('pt-BR', { maximumFractionDigits: 1 })} mil`;
    return `R$ ${Math.round(valor)}`;
}

function mostrarStatus(mensagem, erro) {
    const status = document.getElementById('statusRelatorio');
    status.textContent = mensagem;
    status.classList.toggle('status-error', erro);
}
