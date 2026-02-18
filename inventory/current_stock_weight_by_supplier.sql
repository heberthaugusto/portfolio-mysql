-- Report: Current Stock Weight by Supplier
-- Description:
--   Displays current stock quantity and total weight grouped by product,
--   filtered by supplier and store.
--
-- Context: ERP environment
-- Database: MySQL
--
-- Objective:
--   Provide inventory visibility by supplier, supporting
--   stock control and logistics analysis.
--
-- Business Rules:
--   - Considers wholesale and retail quantities
--   - Allows filtering by store (0 = all stores)
--   - Excludes discontinued products
--   - Calculates total stock weight in KG
--
-- Parameters:
--   $fn   -> Supplier ID
--   $loja -> Store (0 = all)

%vars
$fn   = {:vend:No.do Fornecedor;;s}
$loja = {:store:Loja;;}
%
SELECT
      stk.storeno AS Loja,
      vend.name AS Fornecedor,
      RIGHT(stk.prdno, 6) AS Produto,
      prd.name AS Descricao,
      prd.mfno_ref AS RefFabr,
      prd.weight_g AS PesoUnitKG,
      SUM(stk.qtty_atacado + stk.qtty_varejo) AS QtdeEstoque,
      prd.weight_g * SUM(stk.qtty_atacado + stk.qtty_varejo) / 10 AS PesoEstoqueKG
FROM
      sqldados.stk
LEFT JOIN
      sqldados.prd ON prd.no = stk.prdno
LEFT JOIN
      sqldados.vend ON vend.no = prd.mfno
WHERE
      prd.mfno = [$fn]
      AND (stk.storeno = [$loja] OR [$loja] = 0)
      AND (prd.dereg & 4) <> 4
GROUP BY
      stk.storeno,
      stk.prdno
ORDER BY
      QtdeEstoque DESC;
