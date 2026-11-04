let produtosPDV = [];
let carrinho = [];
let ultimoComprovante = [];

document.addEventListener('DOMContentLoaded', async () => {
    configurarFiltroHistorico();
    configurarTerminalPDV();
    await carregarOpcoesSKU();
    await carregarHistorico();

    document.getElementById('formLeitura').addEventListener('submit', (event) => {
        event.preventDefault();
        adicionarPorCodigo();
    });
    document.getElementById('adicionarManual').addEventListener('click', adicionarSelecaoManual);
    document.getElementById('limparCarrinho').addEventListener('click', limparCarrinho);
    document.getElementById('finalizarVenda').addEventListener('click', finalizarVenda);
    document.getElementById('imprimirComprovante').addEventListener('click', imprimirComprovante);
    document.getElementById('formFiltroVendas').addEventListener('submit', async (event) => {
        event.preventDefault();
        await carregarHistorico();
    });
    document.getElementById('codigoBipado').focus();
});

function configurarTerminalPDV() {
    const terminal = getTerminalContext();
    document.getElementById('terminalResumo').textContent = `${terminal.terminalNome} · ${terminal.terminalId.slice(0, 8)}`;
    if (localStorage.getItem('erp-scanner-enabled') === 'false') {
        const campo = document.getElementById('codigoBipado');
        campo.disabled = true;
        campo.placeholder = 'Leitor desativado nas configurações';
        document.querySelector('#formLeitura button').disabled = true;
        document.getElementById('scannerAjuda').textContent = 'Leitor desativado nas configurações. Selecione a peça manualmente para vender.';
    }
}

function configurarFiltroHistorico() {
    const periodo = document.getElementById('periodoVenda');
    const data = document.getElementById('dataVenda');
    const mes = document.getElementById('mesVenda');
    const ano = document.getElementById('anoVenda');
    const hoje = new Date();
    const anoAtual = hoje.getFullYear();
    const mesAtual = String(hoje.getMonth() + 1).padStart(2, '0');
    const diaAtual = String(hoje.getDate()).padStart(2, '0');

    data.value = `${anoAtual}-${mesAtual}-${diaAtual}`;
    mes.value = `${anoAtual}-${mesAtual}`;
    ano.value = anoAtual;

    const atualizarCampos = () => {
        data.hidden = periodo.value !== 'dia';
        mes.hidden = periodo.value !== 'mes';
        ano.hidden = periodo.value !== 'ano';
    };

    periodo.addEventListener('change', atualizarCampos);
    atualizarCampos();
}

async function carregarOpcoesSKU() {
    const select = document.getElementById('selectSKU');
    try {
        produtosPDV = await apiRequest('/produtos');
        select.replaceChildren(new Option('Selecione um produto', ''));

        produtosPDV.forEach((produto) => {
            (produto.grades || []).forEach((grade) => {
                const item = obterSKU(produto, grade);
                const option = new Option(
                    `${item.nome} · ${item.tamanho}/${item.cor} · ${item.estoque} un · ${formatarMoeda(item.preco)}`,
                    String(item.id)
                );
                option.disabled = item.estoque <= 0;
                select.appendChild(option);
            });
        });
    } catch (error) {
        mostrarStatus(`Não foi possível carregar os produtos: ${error.message}`, true);
    }
}

function obterSKU(produto, grade) {
    return {
        id: grade.id,
        nome: produto.nome,
        tamanho: grade.tamanho,
        cor: grade.cor,
        codigoBarra: String(grade.codigoBarra || '').trim(),
        estoque: Number(grade.qtdEstoque || 0),
        preco: Number(produto.precoBase || 0)
    };
}

function encontrarSKUPorId(id) {
    for (const produto of produtosPDV) {
        const grade = (produto.grades || []).find((item) => String(item.id) === String(id));
        if (grade) return obterSKU(produto, grade);
    }
    return null;
}

function adicionarPorCodigo() {
    const campo = document.getElementById('codigoBipado');
    const codigo = campo.value.trim();
    if (!codigo) return;

    const encontrados = [];
    produtosPDV.forEach((produto) => (produto.grades || []).forEach((grade) => {
        if (String(grade.codigoBarra || '').trim() === codigo) {
            encontrados.push(obterSKU(produto, grade));
        }
    }));

    campo.value = '';
    if (encontrados.length === 0) {
        mostrarStatus(`Código ${codigo} não encontrado. Confira o cadastro do produto.`, true);
        campo.focus();
        return;
    }
    if (encontrados.length > 1) {
        mostrarStatus(`O código ${codigo} está cadastrado em mais de uma variante. Corrija os códigos duplicados no estoque.`, true);
        campo.focus();
        return;
    }
    adicionarAoCarrinho(encontrados[0], 1);
    campo.focus();
}

function adicionarSelecaoManual() {
    const id = document.getElementById('selectSKU').value;
    const quantidade = Number.parseInt(document.getElementById('qtdVenda').value, 10);
    const sku = encontrarSKUPorId(id);
    if (!sku) {
        mostrarStatus('Selecione uma variante para adicionar.', true);
        return;
    }
    adicionarAoCarrinho(sku, quantidade);
    document.getElementById('qtdVenda').value = '1';
}

function adicionarAoCarrinho(sku, quantidade) {
    if (!Number.isInteger(quantidade) || quantidade < 1) {
        mostrarStatus('Informe uma quantidade inteira maior que zero.', true);
        return;
    }
    const linha = carrinho.find((item) => String(item.id) === String(sku.id));
    const quantidadeAtual = (linha ? linha.quantidade : 0) + quantidade;
    if (quantidadeAtual > sku.estoque) {
        mostrarStatus(`Estoque insuficiente de ${sku.nome} (${sku.tamanho}/${sku.cor}). Disponível: ${sku.estoque}.`, true);
        return;
    }

    if (linha) linha.quantidade = quantidadeAtual;
    else carrinho.push({ ...sku, quantidade });
    renderizarCarrinho();
    mostrarStatus(`${sku.nome} (${sku.tamanho}/${sku.cor}) adicionado ao carrinho.`, false);
}

function renderizarCarrinho() {
    const tabela = document.getElementById('tbodyCarrinho');
    tabela.replaceChildren();
    carrinho.forEach((item, index) => {
        const linha = document.createElement('tr');
        const descricao = document.createElement('td');
        descricao.className = 'cart-product';
        descricao.textContent = `${item.nome} · ${item.tamanho}/${item.cor}`;
        const quantidade = document.createElement('td');
        quantidade.textContent = item.quantidade;
        const unitario = document.createElement('td');
        unitario.textContent = formatarMoeda(item.preco);
        const subtotal = document.createElement('td');
        subtotal.textContent = formatarMoeda(item.preco * item.quantidade);
        const acao = document.createElement('td');
        const remover = document.createElement('button');
        remover.type = 'button';
        remover.className = 'remove-item';
        remover.textContent = 'Remover';
        remover.setAttribute('aria-label', `Remover ${item.nome} do carrinho`);
        remover.addEventListener('click', () => {
            carrinho.splice(index, 1);
            renderizarCarrinho();
        });
        acao.appendChild(remover);
        linha.append(descricao, quantidade, unitario, subtotal, acao);
        tabela.appendChild(linha);
    });

    const total = carrinho.reduce((soma, item) => soma + item.preco * item.quantidade, 0);
    document.getElementById('totalVenda').textContent = formatarMoeda(total);
    document.getElementById('carrinhoVazio').hidden = carrinho.length > 0;
    document.getElementById('finalizarVenda').disabled = carrinho.length === 0;
}

async function finalizarVenda() {
    if (carrinho.length === 0) return;
    const botao = document.getElementById('finalizarVenda');
    botao.disabled = true;
    botao.textContent = 'Registrando...';
    const venda = carrinho.map(({ id, quantidade }) => ({ skuId: String(id), quantidade }));
    try {
        await apiRequest('/venda', 'POST', { itens: venda });
        ultimoComprovante = carrinho.map((item) => ({ ...item }));
        document.getElementById('imprimirComprovante').hidden = false;
        carrinho = [];
        renderizarCarrinho();
        mostrarStatus('Venda concluída. Estoque e movimentações foram registrados.', false);
        await Promise.all([carregarOpcoesSKU(), carregarHistorico()]);
        if (localStorage.getItem('erp-auto-print') === 'true') imprimirComprovante();
    } catch (error) {
        mostrarStatus(`Não foi possível concluir a venda: ${error.message}`, true);
    } finally {
        botao.textContent = 'Finalizar venda';
        botao.disabled = carrinho.length === 0;
        if (!document.getElementById('codigoBipado').disabled) {
            document.getElementById('codigoBipado').focus();
        }
    }
}

function limparCarrinho() {
    carrinho = [];
    renderizarCarrinho();
    document.getElementById('codigoBipado').focus();
}

function imprimirComprovante() {
    if (!ultimoComprovante.length) return;
    const area = document.getElementById('printArea');
    area.replaceChildren();
    const terminal = getTerminalContext();
    const titulo = document.createElement('h2');
    titulo.textContent = 'Comprovante de venda';
    const nomeTerminal = document.createElement('p');
    nomeTerminal.textContent = `${terminal.terminalNome} · ${new Date().toLocaleString('pt-BR')}`;
    area.append(titulo, nomeTerminal);

    let total = 0;
    ultimoComprovante.forEach((item) => {
        const linha = document.createElement('p');
        const subtotal = item.preco * item.quantidade;
        total += subtotal;
        linha.textContent = `${item.nome} ${item.tamanho}/${item.cor} · ${item.quantidade} x ${formatarMoeda(item.preco)} = ${formatarMoeda(subtotal)}`;
        area.appendChild(linha);
    });
    const totalLinha = document.createElement('strong');
    totalLinha.textContent = `TOTAL: ${formatarMoeda(total)}`;
    area.appendChild(totalLinha);
    window.print();
}

async function carregarHistorico() {
    const periodo = document.getElementById('periodoVenda').value;
    const data = periodo === 'dia'
        ? document.getElementById('dataVenda').value
        : periodo === 'mes'
            ? document.getElementById('mesVenda').value
            : document.getElementById('anoVenda').value;
    const params = new URLSearchParams({ periodo, data });
    const tabela = document.getElementById('tbodyVendas');
    const resumo = document.getElementById('resumoVendas');

    try {
        const vendas = await apiRequest(`/vendas?${params}`);
        tabela.replaceChildren();
        let total = 0;
        vendas.forEach((venda) => {
            total += Number(venda.valorTotal);
            const linha = document.createElement('tr');
            const dataHora = new Date(`${String(venda.dataHora).replace(' ', 'T')}Z`);
            [
                Number.isNaN(dataHora.getTime()) ? venda.dataHora : dataHora.toLocaleString('pt-BR'),
                venda.produto || '-',
                `${venda.tamanho || '-'} / ${venda.cor || '-'}`,
                venda.quantidade,
                formatarMoeda(Number(venda.valorTotal)),
                venda.usuario || '-',
                venda.terminalNome || '-'
            ].forEach((valor) => {
                const celula = document.createElement('td');
                celula.textContent = valor;
                linha.appendChild(celula);
            });
            tabela.appendChild(linha);
        });

        resumo.textContent = vendas.length
            ? `${vendas.length} item(ns) vendido(s) · Total: ${formatarMoeda(total)}`
            : 'Nenhuma venda encontrada para o período.';
    } catch (error) {
        resumo.textContent = 'Não foi possível carregar o histórico de vendas.';
        console.error('Falha ao carregar histórico de vendas:', error);
    }
}

function formatarMoeda(valor) {
    return Number(valor || 0).toLocaleString('pt-BR', { style: 'currency', currency: 'BRL' });
}

function mostrarStatus(mensagem, erro) {
    const status = document.getElementById('statusPDV');
    status.textContent = mensagem;
    status.classList.toggle('status-error', erro);
}
