-- Report: Sales by Supplier with Stock and Product Reference
-- Description:
--   Displays sales quantities and current stock levels by supplier and product,
--   including product reference information, with optional grouping by store or product.
--
-- Context: ERP environment
-- Database: MySQL
--
-- Objective:
--   Analyze sales performance by supplier while correlating sold quantities
--   with current inventory levels to support operational and commercial decisions.
--
-- Business Rules:
--   - Supports dynamic grouping by store or product
--   - Allows filtering by store or consolidating all stores
--   - Considers only valid sales transactions
--   - Combines sales data with current stock balances
--
-- Parameters:
--   $fn   -> Supplier ID
--   $di   -> Start date
--   $df   -> End date
--   $loja -> Store ID (0 = all stores)
--   $grp  -> Grouping mode (0 = by store and product, 1 = by product)
--
-- Output:
--   Loja        -> Store
--   Fornecedor  -> Supplier name
--   Produto     -> Product SKU
--   Descricao   -> Product description
--   RefFabr     -> Manufacturer reference
--   Qtd.Vend    -> Sold quantity
--   Qtd.Estq    -> Current stock quantity

%vars
$fn={:vend:No.do Fornecedor;;s}
$di={:d:Data Inicial}
$df={:d:Data Final}
$loja = {:store:Loja;;}
$grp = {:m:Agrupar por;0;}|Loja|Produto|
%
#
SELECT_VARS
	IF([$grp] = 0,'stk.storeno,stk.prdno','stk.prdno') Grupotab1,
	IF([$grp] = 0,'xalog2.vendno,xalog2.storeno,xalog2.prdno','xalog2.vendno,xalog2.prdno') Grupotab2
#
#
SELECT
    stk.prdno AS "prdno",
    SUM(stk.qtty_atacado+stk.qtty_varejo) AS "qtty",
    stk.storeno Lj
FROM
	sqldados.stk
WHERE
	(stk.storeno = [$loja] OR [$loja] = 0)
GROUP BY
      [VAR1]
     /*  stk.storeno,stk.prdno */
#
SELECT
    IF([$grp] = 0,xalog2.storeno,0) Loja,
    vend.name AS "Fornecedor",
    RIGHT(xalog2.prdno,6) AS "Produto",
    prd.name AS "Descricao",
    prd.mfno_ref AS "RefFabr",
    SUM(xalog2.qtty) AS "Qtd.Vend",
    [tabela2].qtty AS "Qtd.Estq"
FROM
    sqldados.xalog2
LEFT JOIN
    sqldados.vend ON (xalog2.vendno = vend.no)
LEFT JOIN
    sqldados.prd ON (xalog2.prdno = prd.no)
LEFT JOIN
    [tabela2] ON (xalog2.prdno = [tabela2].prdno AND xalog2.storeno=[tabela2].Lj)
WHERE
    xalog2.vendno = [$fn] AND
    xalog2.date BETWEEN [$di] AND [$df] AND
    xalog2.xano >= 1000   AND
    xalog2.prdno >= 1     AND
    xalog2.grade >= ''    AND
    (xalog2.storeno = [$loja] OR [$loja] = 0)
GROUP BY
    [VAR2]
ORDER BY
    1, 5 DESC, prd.name
