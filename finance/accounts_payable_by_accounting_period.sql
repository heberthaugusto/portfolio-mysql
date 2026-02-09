-- Report: Accounts Payable by Accounting Period
-- Description:
--   Displays accounts payable grouped by accounting period (competence date),
--   showing total payable amounts per invoice, supplier and expense account.
--
-- Context: ERP / Financial module
-- Database: MySQL
--
-- Objective:
--   Support financial analysis and expense tracking based on
--   accounting period rather than due date.
--
-- Business Rules:
--   - Uses invoice competence date (inv.date)
--   - Aggregates payable amounts per invoice
--   - Allows filtering by accounting period range
--   - Includes supplier and expense account information
--
-- Parameters:
--   $datai -> Accounting period start date
--   $dataf -> Accounting period end date
--
-- Output:
--   CTP                   -> Accounts payable control number
--   Fornecedor            -> Supplier name
--   ContaDespesa          -> Expense account
--   Competencia           -> Accounting period date
--   Valor Total Pagamento -> Total payable amount

%vars
$datai={:d:Data Competencia Inicial}
$dataf={:d:Data Competencia Final}
%
SELECT
    inv.invno AS "CTP",
    vend.name AS Fornecedor,
    CONCAT(acc.no,'-',acc.name) AS ContaDespesa,
    DATE_FORMAT(inv.date, '%d/%m/%y') AS Competencia,
    SUM(invxa.amtdue) AS "Valor Total Pagamento"
FROM
    sqldados.invxa
LEFT JOIN
    sqldados.inv ON inv.invno = invxa.invno AND inv.storeno = invxa.storeno
LEFT JOIN
    sqldados.vend ON vend.no = inv.vendno
LEFT JOIN
    sqldados.acc ON acc.no = inv.account
WHERE
    invxa.storeno >= 0 AND
    vendno >= 0 AND
    inv.date BETWEEN [$datai] AND [$dataf]
GROUP BY
    inv.invno, vend.name, acc.no, acc.name, inv.date
ORDER BY
    CONCAT(acc.no, '-', acc.name),
    inv.date;
