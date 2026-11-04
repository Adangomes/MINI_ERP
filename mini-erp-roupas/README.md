# Mini ERP Moda

ERP modular para varejo de moda, com backend em InterSystems IRIS ObjectScript/COS e frontend HTML/JavaScript.

## Módulos atuais

- Produtos, variantes de tamanho/cor e estoque
- PDV com carrinho, leitor USB em modo teclado e histórico de vendas
- Livro-razão de entradas e saídas do estoque com data/hora, usuário e terminal
- Configuração local do terminal e impressão de comprovantes pelo navegador
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

Na tela **Configuração**, cada navegador cria um identificador persistente para a estação de caixa. O PDV aceita leitores USB que funcionam como teclado e enviam Enter após o código. Para imprimir, instale e configure a impressora térmica no sistema operacional; a impressão abre a caixa de diálogo padrão do navegador, que não permite ao site enumerar nem escolher impressoras silenciosamente.

Na primeira inicialização após esta atualização, os saldos existentes sem histórico recebem um lançamento **Saldo inicial migrado**. Isso registra o saldo observado na migração, mas não recria datas ou responsáveis de movimentações anteriores que não estavam armazenadas.

O login atual é apenas demonstrativo, com credenciais fixas no código. Não exponha este ambiente na internet nem use dados reais até implementar autenticação segura, permissões e gestão de segredos.

## API financeira

- `GET /api/caixa?inicio=AAAA-MM-DD&fim=AAAA-MM-DD` — movimentos de caixa filtrados por data
- `POST /api/caixa` — lançamento manual de entrada/saída
- `GET /api/contas` — contas com saldo aberto e histórico de pagamentos
- `POST /api/contas` — cadastro de conta a pagar/receber
- `POST /api/contas/pagamento` — baixa parcial ou total, atualizando a conta e o caixa na mesma transação
- `GET /api/dre` — resumo operacional de caixa e saldos a pagar/receber
- `GET /api/vendas?periodo=dia|mes|ano&data=...` — vendas para indicadores e exportação
- `GET /api/estoque/movimentos` — trilha de entradas e saídas com saldo anterior/atual, origem, usuário e terminal

As exportações CSV são geradas pelo navegador para vendas, contas e movimentos de caixa. PDF/XLSX, emissão fiscal, conciliação bancária e controles comerciais ainda não estão implementados.
