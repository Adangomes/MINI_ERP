document.addEventListener('DOMContentLoaded', () => {
    configurarFiltroHistorico();
    carregarOpcoesSKU();
    carregarHistorico();

    const formVenda = document.getElementById('formVenda');
    if (formVenda) {
        formVenda.addEventListener('submit', async (e) => {
            e.preventDefault();
            const payload = {
                skuId: document.getElementById('selectSKU').value,
                quantidade: parseInt(document.getElementById('qtdVenda').value)
            };

            try {
                await apiRequest('/venda', 'POST', payload);
                alert('Venda e baixa de estoque realizadas com sucesso!');
                formVenda.reset();
                await carregarOpcoesSKU();
                await carregarHistorico();
            } catch (error) {
                console.error('Não foi possível registrar a venda:', error);
            }
        });
    }

    document.getElementById('formFiltroVendas').addEventListener('submit', async (e) => {
        e.preventDefault();
        await carregarHistorico();
    });
});

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
    if (!select) return;

    try {
        const produtos = await apiRequest('/produtos');
        select.innerHTML = '<option value="">Selecione a variante (Tamanho/Cor)</option>';

        produtos.forEach(p => {
            p.grades.forEach(g => {
                const opt = document.createElement('option');
                opt.value = g.id;
                opt.textContent = `${p.nome} - Tamanho: ${g.tamanho} | Cor: ${g.cor} (Estoque: ${g.qtdEstoque})`;
                select.appendChild(opt);
            });
        });
    } catch (e) {
        console.error(e);
    }
}

async function carregarHistorico() {
    const periodo = document.getElementById('periodoVenda').value;
    const data = periodo === 'dia'
        ? document.getElementById('dataVenda').value
        : periodo === 'mes'
            ? document.getElementById('mesVenda').value
            : document.getElementById('anoVenda').value;
    const fuso = new Date().getTimezoneOffset();
    const params = new URLSearchParams({ periodo, data, fuso: String(fuso) });
    const tabela = document.getElementById('tbodyVendas');
    const resumo = document.getElementById('resumoVendas');

    try {
        const vendas = await apiRequest(`/vendas?${params}`);
        tabela.replaceChildren();

        let total = 0;
        vendas.forEach((venda) => {
            total += Number(venda.valorTotal);
            const linha = document.createElement('tr');
            const dataHora = new Date(`${venda.dataHora.replace(' ', 'T')}Z`);
            const valores = [
                Number.isNaN(dataHora.getTime())
                    ? venda.dataHora
                    : dataHora.toLocaleString('pt-BR'),
                venda.produto,
                `${venda.tamanho} / ${venda.cor}`,
                venda.quantidade,
                Number(venda.valorTotal).toLocaleString('pt-BR', {
                    style: 'currency',
                    currency: 'BRL'
                }),
                venda.usuario
            ];

            valores.forEach((valor) => {
                const celula = document.createElement('td');
                celula.textContent = valor;
                linha.appendChild(celula);
            });
            tabela.appendChild(linha);
        });

        resumo.textContent = vendas.length
            ? `${vendas.length} venda(s) no período · Total: ${total.toLocaleString('pt-BR', { style: 'currency', currency: 'BRL' })}`
            : 'Nenhuma venda encontrada para o período.';
    } catch (error) {
        resumo.textContent = 'Não foi possível carregar o histórico de vendas.';
        console.error('Falha ao carregar histórico de vendas:', error);
    }
}
