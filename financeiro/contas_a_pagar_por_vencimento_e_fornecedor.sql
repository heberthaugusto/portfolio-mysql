-- Relatório: Contas a Pagar por Vencimento e Fornecedor
-- Descrição:
--   Exibe as contas a pagar em aberto agrupadas por fornecedor,
--   ordenadas por vencimento, com filtro opcional por conta de despesa.
--
-- Contexto: ERP / módulo financeiro
-- Banco de dados: MySQL
--
-- Objetivo:
--   Dar visibilidade aos pagamentos futuros, apoiando o controle
--   do fluxo de caixa e o planejamento financeiro.
--
-- Regras de negócio:
--   - Considera a data de vencimento das parcelas (invxa.duedate)
--   - Permite filtrar por fornecedor e conta de despesa
--   - Aceita um intervalo de vencimento
--   - Exibe título, fornecedor e valor da parcela
--
-- Parâmetros:
--   $datini -> Vencimento inicial
--   $datfin -> Vencimento final
--   $Forn   -> Fornecedor (opcional)
--   $conta  -> Conta de despesa (opcional)
--
-- Saída:
--   CTP           -> Número de controle do título a pagar
--   Fornecedor    -> Nome do fornecedor
--   CNPJ/CPF      -> Documento do fornecedor
--   NotaFiscal    -> Número da nota fiscal
--   ContaDespesa  -> Conta de despesa
--   Vencimento    -> Data de vencimento
--   ValorParcela  -> Valor da parcela

%vars
$datini  = {:d:Data Vencimento inicial}
$datfin  = {:d:Data Vencimento final}
$Forn   = {:vend:Fornecedor}
$conta  = {:acc:Conta Despesa}
%
select
    LPAD(inv.invno,7, " ") CTP,
    LEFT(vend.name,25) Forncedor,
    vend.cgc  "CNPJ/CPF",
    LEFT(inv.nfname,10) NotaFiscal,
    inv.account ContaDespesa,
    DATE_FORMAT(invxa.duedate, '%d/%m/%y') Vencimento,
    invxa.amtdue ValorParcela
FROM
    sqldados.invxa
LEFT JOIN
    sqldados.inv on inv.invno = invxa.invno AND inv.storeno = invxa.storeno
LEFT JOIN
    sqldados.vend ON vend.no = inv.vendno
WHERE
    (inv.vendno = [$Forn] OR [$Forn] = 0) AND
    invxa.duedate BETWEEN [$datini] AND [$datfin] AND
    (inv.account IN ('[$conta]') OR '[$conta]' = '')
ORDER BY
    invxa.storeno, inv.vendno, invxa.duedate;
