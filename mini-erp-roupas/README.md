# Mini ERP Moda

ERP modular para varejo de moda, com backend em InterSystems IRIS ObjectScript/COS e frontend HTML/JavaScript.

## Módulos atuais

- Produtos, variantes de tamanho/cor e estoque
- PDV e histórico de vendas
- Clientes e fornecedores
- Compras com entrada de estoque e geração de conta a pagar
- Caixa, contas a pagar/receber e registro de pagamentos parciais
- Resumo financeiro operacional, indicadores de vendas e exportação CSV

O resumo financeiro é operacional e baseado nos movimentos registrados no caixa; não substitui uma DRE contábil. Vendas registradas no PDV geram entrada no caixa. Compras geram conta a pagar; a saída de caixa é registrada quando o pagamento da conta é baixado.

## Rodar localmente

Com Docker Desktop ativo:

```sh
docker compose up --build
```

Abra `http://localhost:8080`. A API é servida pelo Nginx em `/api` e encaminhada para o IRIS. Para parar os serviços, use `docker compose down`; os dados persistem no volume Docker `mini-erp-roupas-iris-user-data`.

O login atual é apenas demonstrativo, com credenciais fixas no código. Não exponha este ambiente na internet nem use dados reais até implementar autenticação segura, permissões e gestão de segredos.

## API financeira

- `GET /api/caixa?inicio=AAAA-MM-DD&fim=AAAA-MM-DD` — movimentos de caixa filtrados por data
- `POST /api/caixa` — lançamento manual de entrada/saída
- `GET /api/contas` — contas com saldo aberto e histórico de pagamentos
- `POST /api/contas` — cadastro de conta a pagar/receber
- `POST /api/contas/pagamento` — baixa parcial ou total, atualizando a conta e o caixa na mesma transação
- `GET /api/dre` — resumo operacional de caixa e saldos a pagar/receber
- `GET /api/vendas?periodo=dia|mes|ano&data=...` — vendas para indicadores e exportação

As exportações CSV são geradas pelo navegador para vendas, contas e movimentos de caixa. PDF/XLSX, emissão fiscal, conciliação bancária e controles comerciais ainda não estão implementados.
