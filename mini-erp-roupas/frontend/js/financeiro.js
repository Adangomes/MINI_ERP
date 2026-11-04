let movimentosCaixa = [];
let contasFinanceiras = [];
let vendasRelatorio = [];

document.addEventListener('DOMContentLoaded', () => {
    const hoje = new Date();
    const hojeISO = dataLocalISO(hoje);
    document.getElementById('inicioCaixa').value = hojeISO;
    document.getElementById('fimCaixa').value = hojeISO;
    document.getElementById('dataRelatorio').value = hojeISO;
    document.getElementById('mesRelatorio').value = hojeISO.slice(0, 7);
    document.getElementById('anoRelatorio').value = hoje.getFullYear();

    document.getElementById('periodoRelatorio').addEventListener('change', atualizarCamposPeriodo);
    document.getElementById('formPeriodoVendas').addEventListener('submit', (event) => {
        event.preventDefault();
        carregarRelatorioVendas();
    });
    document.getElementById('formFiltroCaixa').addEventListener('submit', (event) => {
        event.preventDefault();
        carregarCaixa();
    });
    document.getElementById('exportarVendas').addEventListener('click', () => {
        exportarCSV('vendas.csv', ['Data e hora', 'Produto', 'Tamanho', 'Cor', 'Quantidade', 'Valor', 'Usuário'],
            vendasRelatorio.map(v => [v.dataHora, v.produto, v.tamanho, v.cor, v.quantidade, v.valorTotal, v.usuario]));
    });
    document.getElementById('exportarCaixa').addEventListener('click', () => {
        exportarCSV('movimentos-caixa.csv', ['Data e hora', 'Tipo', 'Descrição', 'Valor', 'Referência', 'Usuário'],
            movimentosCaixa.map(m => [m.dataHora, m.tipo, m.descricao, m.valor, m.referencia, m.usuario]));
    });
    document.getElementById('exportarContas').addEventListener('click', () => {
        exportarCSV('contas-financeiras.csv', ['Tipo', 'Descrição', 'Valor', 'Pago', 'Restante', 'Vencimento', 'Status', 'Origem'],
            contasFinanceiras.map(conta => [
                conta.tipo, conta.descricao, conta.valor, conta.valorPago, conta.valorRestante,
                conta.dataVencimento, conta.status, conta.origemNome
            ]));
    });

    document.getElementById('formCaixa').addEventListener('submit', salvarMovimento);
    document.getElementById('formConta').addEventListener('submit', salvarConta);
    document.getElementById('tbodyContas').addEventListener('click', registrarPagamento);

    atualizarCamposPeriodo();
    carregarResumoDRE();
    carregarCaixa();
    carregarContas();
    carregarRelatorioVendas();
});

function atualizarCamposPeriodo() {
    const periodo = document.getElementById('periodoRelatorio').value;
    document.getElementById('dataRelatorio').hidden = periodo !== 'dia';
    document.getElementById('mesRelatorio').hidden = periodo !== 'mes';
    document.getElementById('anoRelatorio').hidden = periodo !== 'ano';
    document.getElementById('dataRelatorio').required = periodo === 'dia';
    document.getElementById('mesRelatorio').required = periodo === 'mes';
    document.getElementById('anoRelatorio').required = periodo === 'ano';
}

async function salvarMovimento(event) {
    event.preventDefault();
    const form = event.currentTarget;
    try {
        await apiRequest('/caixa', 'POST', {
            tipo: document.getElementById('tipoCaixa').value,
            descricao: document.getElementById('descricaoCaixa').value.trim(),
            valor: Number(document.getElementById('valorCaixa').value),
            referencia: document.getElementById('referenciaCaixa').value.trim(),
            usuario: 'admin'
        });
        alert('Movimento de caixa salvo com sucesso!');
        form.reset();
        await Promise.all([carregarResumoDRE(), carregarCaixa()]);
    } catch (error) {
        console.error('Falha ao salvar movimento de caixa:', error);
    }
}

async function salvarConta(event) {
    event.preventDefault();
    const form = event.currentTarget;
    try {
        await apiRequest('/contas', 'POST', {
            tipo: document.getElementById('tipoConta').value,
            descricao: document.getElementById('descricaoConta').value.trim(),
            valor: Number(document.getElementById('valorConta').value),
            dataVencimento: document.getElementById('vencimentoConta').value,
            origemNome: document.getElementById('origemNomeConta').value.trim(),
            origemTipo: document.getElementById('tipoConta').value === 'Receber' ? 'Cliente' : 'Fornecedor',
            usuario: 'admin'
        });
        alert('Conta salva com sucesso!');
        form.reset();
        await Promise.all([carregarResumoDRE(), carregarContas()]);
    } catch (error) {
        console.error('Falha ao salvar conta:', error);
    }
}

async function registrarPagamento(event) {
    const botao = event.target.closest('button[data-conta-id]');
    if (!botao) return;

    const linha = botao.closest('tr');
    const valor = Number(linha.querySelector('input[data-valor-pagamento]').value);
    if (!Number.isFinite(valor) || valor <= 0) {
        alert('Informe um valor de pagamento maior que zero.');
        return;
    }

    botao.disabled = true;
    try {
        await apiRequest('/contas/pagamento', 'POST', {
            contaId: botao.dataset.contaId,
            valor,
            formaPagamento: linha.querySelector('select[data-forma-pagamento]').value,
            usuario: 'admin'
        });
        alert('Pagamento registrado e caixa atualizado.');
        await Promise.all([carregarResumoDRE(), carregarCaixa(), carregarContas()]);
    } catch (error) {
        console.error('Falha ao registrar pagamento:', error);
    } finally {
        botao.disabled = false;
    }
}

async function carregarResumoDRE() {
    const resumoNode = document.getElementById('dreResumo');
    try {
        const dre = await apiRequest('/dre');
        const cards = [
            ['Entradas acumuladas', formatCurrency(dre.receita)],
            ['Saídas acumuladas', formatCurrency(dre.despesas)],
            ['Saldo de caixa', formatCurrency(dre.saldoCaixa)],
            ['A receber', formatCurrency(dre.contasReceber)],
            ['A pagar', formatCurrency(dre.contasPagar)]
        ];
        renderizarCards(resumoNode, cards);
    } catch (error) {
        resumoNode.textContent = 'Não foi possível carregar o resumo financeiro.';
        console.error('Falha ao carregar resumo financeiro:', error);
    }
}

async function carregarRelatorioVendas() {
    const periodo = document.getElementById('periodoRelatorio').value;
    const data = periodo === 'dia'
        ? document.getElementById('dataRelatorio').value
        : periodo === 'mes'
            ? document.getElementById('mesRelatorio').value
            : document.getElementById('anoRelatorio').value;
    const params = new URLSearchParams({ periodo, data });

    try {
        vendasRelatorio = await apiRequest(`/vendas?${params}`);
        const quantidade = vendasRelatorio.reduce((total, venda) => total + Number(venda.quantidade || 0), 0);
        const faturamento = vendasRelatorio.reduce((total, venda) => total + Number(venda.valorTotal || 0), 0);
        const ticketMedio = vendasRelatorio.length ? faturamento / vendasRelatorio.length : 0;
        const valorMedioPeca = quantidade ? faturamento / quantidade : 0;
        renderizarCards(document.getElementById('resumoVendas'), [
            ['Vendas', String(vendasRelatorio.length)],
            ['Peças vendidas', String(quantidade)],
            ['Faturamento', formatCurrency(faturamento)],
            ['Ticket médio', formatCurrency(ticketMedio)],
            ['Valor médio por peça', formatCurrency(valorMedioPeca)]
        ]);
    } catch (error) {
        document.getElementById('resumoVendas').textContent = 'Não foi possível carregar o relatório de vendas.';
        console.error('Falha ao carregar relatório de vendas:', error);
    }
}

async function carregarCaixa() {
    const tabela = document.getElementById('tbodyCaixa');
    const inicio = document.getElementById('inicioCaixa').value;
    const fim = document.getElementById('fimCaixa').value;
    if (inicio && fim && inicio > fim) {
        alert('A data inicial não pode ser posterior à data final.');
        return;
    }

    const params = new URLSearchParams();
    if (inicio) params.set('inicio', inicio);
    if (fim) params.set('fim', fim);

    try {
        movimentosCaixa = await apiRequest(`/caixa?${params}`);
        tabela.replaceChildren();
        const entradas = movimentosCaixa
            .filter(movimento => movimento.tipo === 'Entrada')
            .reduce((total, movimento) => total + Number(movimento.valor || 0), 0);
        const saidas = movimentosCaixa
            .filter(movimento => movimento.tipo === 'Saida')
            .reduce((total, movimento) => total + Number(movimento.valor || 0), 0);
        renderizarCards(document.getElementById('resumoCaixa'), [
            ['Entradas no período', formatCurrency(entradas)],
            ['Saídas no período', formatCurrency(saidas)],
            ['Saldo do período', formatCurrency(entradas - saidas)]
        ]);
        movimentosCaixa.forEach((movimento) => {
            const linha = document.createElement('tr');
            adicionarCelula(linha, movimento.dataHora);
            adicionarCelula(linha, movimento.tipo);
            adicionarCelula(linha, movimento.descricao);
            adicionarCelula(linha, formatCurrency(movimento.valor));
            adicionarCelula(linha, movimento.referencia);
            tabela.appendChild(linha);
        });
    } catch (error) {
        console.error('Falha ao carregar caixa:', error);
    }
}

async function carregarContas() {
    const tabela = document.getElementById('tbodyContas');
    try {
        contasFinanceiras = await apiRequest('/contas');
        tabela.replaceChildren();
        contasFinanceiras.forEach((conta) => {
            const linha = document.createElement('tr');
            adicionarCelula(linha, conta.tipo);
            adicionarCelula(linha, conta.descricao);
            adicionarCelula(linha, formatCurrency(conta.valor));
            adicionarCelula(linha, formatCurrency(conta.valorPago));
            adicionarCelula(linha, formatCurrency(conta.valorRestante));
            adicionarCelula(linha, conta.dataVencimento);
            adicionarCelula(linha, conta.status);
            adicionarCelula(linha, conta.origemNome);

            const celulaHistorico = document.createElement('td');
            const historico = (conta.pagamentos || [])
                .map(pagamento => `${pagamento.dataHora}: ${formatCurrency(pagamento.valor)}${pagamento.formaPagamento ? ` (${pagamento.formaPagamento})` : ''}`)
                .join('\n');
            celulaHistorico.className = 'payment-history';
            celulaHistorico.textContent = historico || '-';
            linha.appendChild(celulaHistorico);

            const celulaPagamento = document.createElement('td');
            if (Number(conta.valorRestante) > 0) {
                const valor = document.createElement('input');
                valor.type = 'number';
                valor.min = '0.01';
                valor.max = String(conta.valorRestante);
                valor.step = '0.01';
                valor.placeholder = 'Valor';
                valor.setAttribute('aria-label', `Valor a pagar: ${conta.descricao}`);
                valor.dataset.valorPagamento = '';

                const forma = document.createElement('select');
                forma.dataset.formaPagamento = '';
                ['Dinheiro', 'Pix', 'Cartão', 'Transferência', 'Outro'].forEach((opcao) => {
                    const option = document.createElement('option');
                    option.value = opcao;
                    option.textContent = opcao;
                    forma.appendChild(option);
                });

                const botao = document.createElement('button');
                botao.type = 'button';
                botao.textContent = 'Baixar';
                botao.dataset.contaId = conta.id;

                celulaPagamento.append(valor, forma, botao);
            } else {
                celulaPagamento.textContent = 'Quitada';
            }
            linha.appendChild(celulaPagamento);
            tabela.appendChild(linha);
        });
    } catch (error) {
        console.error('Falha ao carregar contas:', error);
    }
}

function renderizarCards(container, cards) {
    container.replaceChildren();
    cards.forEach(([label, valor]) => {
        const card = document.createElement('div');
        card.className = 'stat-box';
        const titulo = document.createElement('span');
        titulo.textContent = label;
        const conteudo = document.createElement('strong');
        conteudo.textContent = valor;
        card.append(titulo, conteudo);
        container.appendChild(card);
    });
}

function adicionarCelula(linha, valor) {
    const celula = document.createElement('td');
    celula.textContent = valor === null || valor === undefined || valor === '' ? '-' : String(valor);
    linha.appendChild(celula);
}

function exportarCSV(nomeArquivo, cabecalho, linhas) {
    const csv = [cabecalho, ...linhas]
        .map(linha => linha.map(valor => escaparCSV(valor)).join(','))
        .join('\r\n');
    const blob = new Blob(['\uFEFF', csv], { type: 'text/csv;charset=utf-8' });
    const link = document.createElement('a');
    link.href = URL.createObjectURL(blob);
    link.download = nomeArquivo;
    document.body.appendChild(link);
    link.click();
    link.remove();
    setTimeout(() => URL.revokeObjectURL(link.href), 0);
}

function escaparCSV(valor) {
    let texto = String(valor ?? '');
    if (/^[\s]*[=+\-@]/.test(texto)) texto = `'${texto}`;
    return `"${texto.replaceAll('"', '""')}"`;
}

function formatCurrency(value) {
    return Number(value || 0).toLocaleString('pt-BR', {
        style: 'currency',
        currency: 'BRL'
    });
}

function dataLocalISO(data) {
    const ano = data.getFullYear();
    const mes = String(data.getMonth() + 1).padStart(2, '0');
    const dia = String(data.getDate()).padStart(2, '0');
    return `${ano}-${mes}-${dia}`;
}
