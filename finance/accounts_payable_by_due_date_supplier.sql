-- Report: Accounts Payable by Due Date and Supplier
-- Description:
--   Displays outstanding accounts payable grouped by supplier,
--   ordered by due date, allowing expense account filtering.
--
-- Context: ERP / Financial module
-- Database: MySQL
--
-- Objective:
--   Provide visibility into upcoming payables, supporting
--   cash flow control and financial planning.
--
-- Business Rules:
--   - Considers installment due dates (invxa.duedate)
--   - Allows filtering by supplier and expense account
--   - Supports a due date range
--   - Displays invoice, supplier and payable amount details
--
-- Parameters:
--   $datini -> Due date start
--   $datfin -> Due date end
--   $Forn   -> Supplier (optional)
--   $conta  -> Expense account (optional)
--
-- Output:
--   CTP           -> Accounts payable control number
--   Fornecedor    -> Supplier name
--   CNPJ/CPF      -> Supplier tax ID
--   NotaFiscal    -> Invoice number
--   ContaDespesa  -> Expense account
--   Vencimento    -> Due date
--   ValorParcela  -> Installment amount

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
