-- Report: Stock Balance by Month/Year and Supplier
-- Description: Displays the stock balance grouped by product for a selected period and supplier.
-- Context: ERP environment
-- Database: MySQL
-- Parameters:
--   $data  -> Stock reference date (month/year)
--   $forn  -> Supplier ID
-- Notes:
--   - Excludes discontinued products
--   - Considers only store 1
--   - SKU formatted with 6 digits
--   - ALIAS in brazilian portugues

%vars
$data = {:d:Data do estoque;;}
$forn = {:s:Fornecedor;;}
%
SELECT
    DATE_FORMAT([$data], '%m/%Y') AS Periodo,
    RIGHT(CONCAT('000000', prd.no), 6) AS SKU,
    prd.name AS Produto,
    SUM(stkchk.qtty2) AS Saldo
FROM
    sqldados.stkchk
INNER JOIN sqldados.prd
        ON prd.no = stkchk.prdno
INNER JOIN sqldados.vend
        ON vend.no = prd.mfno
WHERE
    stkchk.ym = DATE_FORMAT([$data], '%Y%m')
    AND stkchk.storeno = 1
    AND vend.no = [$forn]
    AND (prd.dereg & 4) <> 4
GROUP BY
    prd.no,
    prd.name
ORDER BY
    Saldo DESC;
