#!/usr/bin/env bash
set -euo pipefail

iris session IRIS -U%SYS <<'OBJECTSCRIPT'
zn "USER"
set sc = $system.OBJ.LoadDir("/opt/app/src", "ck", "", 1)
if $SYSTEM.Status.IsError(sc) do $SYSTEM.OBJ.DisplayError(sc)
if $SYSTEM.Status.IsError(sc) halt 1
set result = $SYSTEM.SQL.Execute("GRANT SELECT, INSERT, UPDATE, DELETE ON ERP_Model.Produto TO %DB_USER")
if result.%SQLCODE < 0 write result.%Message,!
if result.%SQLCODE < 0 halt 1
set result = $SYSTEM.SQL.Execute("GRANT SELECT, INSERT, UPDATE, DELETE ON ERP_Model.ItemGrade TO %DB_USER")
if result.%SQLCODE < 0 write result.%Message,!
if result.%SQLCODE < 0 halt 1
set result = $SYSTEM.SQL.Execute("GRANT SELECT, INSERT, UPDATE, DELETE ON ERP_Model.MovimentoEstoque TO %DB_USER")
if result.%SQLCODE < 0 write result.%Message,!
if result.%SQLCODE < 0 halt 1
set result = $SYSTEM.SQL.Execute("GRANT SELECT, INSERT, UPDATE, DELETE ON ERP_Model.Venda TO %DB_USER")
if result.%SQLCODE < 0 write result.%Message,!
if result.%SQLCODE < 0 halt 1
set result = $SYSTEM.SQL.Execute("GRANT SELECT, INSERT, UPDATE, DELETE ON ERP_Model.PedidoVenda TO %DB_USER")
if result.%SQLCODE < 0 write result.%Message,!
if result.%SQLCODE < 0 halt 1
set result = $SYSTEM.SQL.Execute("GRANT SELECT, INSERT, UPDATE, DELETE ON ERP_Model.Cliente TO %DB_USER")
if result.%SQLCODE < 0 write result.%Message,!
if result.%SQLCODE < 0 halt 1
set result = $SYSTEM.SQL.Execute("GRANT SELECT, INSERT, UPDATE, DELETE ON ERP_Model.Fornecedor TO %DB_USER")
if result.%SQLCODE < 0 write result.%Message,!
if result.%SQLCODE < 0 halt 1
set result = $SYSTEM.SQL.Execute("GRANT SELECT, INSERT, UPDATE, DELETE ON ERP_Model.Compra TO %DB_USER")
if result.%SQLCODE < 0 write result.%Message,!
if result.%SQLCODE < 0 halt 1
set result = $SYSTEM.SQL.Execute("GRANT SELECT, INSERT, UPDATE, DELETE ON ERP_Model.CompraItem TO %DB_USER")
if result.%SQLCODE < 0 write result.%Message,!
if result.%SQLCODE < 0 halt 1
set result = $SYSTEM.SQL.Execute("GRANT SELECT, INSERT, UPDATE, DELETE ON ERP_Model.Conta TO %DB_USER")
if result.%SQLCODE < 0 write result.%Message,!
if result.%SQLCODE < 0 halt 1
set result = $SYSTEM.SQL.Execute("GRANT SELECT, INSERT, UPDATE, DELETE ON ERP_Model.ContaPagamento TO %DB_USER")
if result.%SQLCODE < 0 write result.%Message,!
if result.%SQLCODE < 0 halt 1
set result = $SYSTEM.SQL.Execute("GRANT SELECT, INSERT, UPDATE, DELETE ON ERP_Model.MovimentoCaixa TO %DB_USER")
if result.%SQLCODE < 0 write result.%Message,!
if result.%SQLCODE < 0 halt 1
set sc = ##class(ERP.Service.EstoqueService).MigrarSaldoInicial()
if $SYSTEM.Status.IsError(sc) do $SYSTEM.OBJ.DisplayError(sc)
if $SYSTEM.Status.IsError(sc) halt 1
halt
OBJECTSCRIPT

iris session IRIS -U%SYS <<'OBJECTSCRIPT'
set applicationName = "/api/erp"
set sc = ##class(Security.Applications).Get(applicationName, .properties)
kill properties
set properties("NameSpace") = "USER"
set properties("DispatchClass") = "ERP.Spec.Dispatcher"
set properties("Enabled") = 1
set properties("AutheEnabled") = 96
set properties("MatchRoles") = ":%DB_USER"
if $SYSTEM.Status.IsError(sc) set sc = ##class(Security.Applications).Create(applicationName, .properties)
if '$SYSTEM.Status.IsError(sc) set sc = ##class(Security.Applications).Modify(applicationName, .properties)
if $SYSTEM.Status.IsError(sc) do $SYSTEM.OBJ.DisplayError(sc)
if $SYSTEM.Status.IsError(sc) halt 1
halt
OBJECTSCRIPT
