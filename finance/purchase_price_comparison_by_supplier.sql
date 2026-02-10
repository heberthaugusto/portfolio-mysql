-- Report: Purchase Price Comparison by Supplier
-- Description:
--   Compares the purchase price of products between two distinct periods
--   for a selected supplier, considering the last purchase price of each
--   product within each period.
--
-- Context: ERP environment
-- Database: MySQL
--
-- Objective:
--   Identify purchase price variations between periods, indicating whether
--   the product became more expensive, cheaper, or remained unchanged.
--
-- Business Rules:
--   - Considers only the last purchase of each product within each period
--   - Aggregates purchased quantity per product and period
--   - Ignores documents with invno <= 1
--   - Results may include products present in only one of the periods
--
-- Technical Note (Portfolio):
--   The duplicated subqueries for each period are intentional, prioritizing
--   clarity and explicit business rules over abstraction in ERP reports.
--
-- Parameters:
--   $Vend -> Supplier ID
--   $P1i  -> Period 1 start date
--   $P1f  -> Period 1 end date
--   $P2i  -> Period 2 start date
--   $P2f  -> Period 2 end date
--
-- Output:
--   RefFabr    -> Manufacturer reference
--   SKU        -> Product SKU
--   Descricao  -> Product description
--   Qtd_Per_1  -> Purchased quantity in period 1
--   Custo_Per_1-> Last purchase cost in period 1
--   Qtd_Per_2  -> Purchased quantity in period 2
--   Custo_Per_2-> Last purchase cost in period 2
--   Comparacao -> Price comparison result (More expensive / Cheaper / Same)

%vars
$Vend = {:s:Fornecedor}
$P1i  = {:d:P1_Inicio}
$P1f  = {:d:P1_Fim}
$P2i  = {:d:P2_Inicio}
$P2f  = {:d:P2_Fim}
%
SELECT
    p.mfno_ref       AS RefFabr,
    RIGHT(p.no,5)    AS SKU,
    LEFT(p.name,30) AS Descricao,

    p1.Qtd_P1 AS Qtd_Per_1,
    CONCAT('R$ ', FORMAT(p1.Custo_P1/100, 2, 'de_DE')) AS Custo_Per_1,

    p2.Qtd_P2 AS Qtd_Per_2,
    CONCAT('R$ ', FORMAT(p2.Custo_P2/100, 2, 'de_DE')) AS Custo_Per_2,

    CASE
        WHEN p1.Custo_P1 IS NULL OR p2.Custo_P2 IS NULL THEN NULL
        WHEN p2.Custo_P2 > p1.Custo_P1 THEN 'Mais caro'
        WHEN p2.Custo_P2 < p1.Custo_P1 THEN 'Mais barato'
        ELSE 'Igual'
    END AS Comparacao

FROM sqldados.prd p

LEFT JOIN (
    SELECT
        iprd.prdno,
        iprd.fob AS Custo_P1,
        SUM(iprd.qtty) AS Qtd_P1
    FROM sqldados.iprd iprd
    JOIN sqldados.inv inv ON inv.invno = iprd.invno
    JOIN (
        SELECT
            iprd.prdno,
            MAX(iprd.date) AS UltimaData
        FROM sqldados.iprd iprd
        JOIN sqldados.inv inv ON inv.invno = iprd.invno
        WHERE
            inv.vendno = [$Vend]
            AND iprd.date BETWEEN [$P1i] AND [$P1f]
            AND iprd.invno > 1
        GROUP BY iprd.prdno
    ) ult ON ult.prdno = iprd.prdno
         AND ult.UltimaData = iprd.date
    WHERE
        inv.vendno = [$Vend]
    GROUP BY
        iprd.prdno, iprd.fob
) p1 ON p1.prdno = p.no

LEFT JOIN (
    SELECT
        iprd.prdno,
        iprd.fob AS Custo_P2,
        SUM(iprd.qtty) AS Qtd_P2
    FROM sqldados.iprd iprd
    JOIN sqldados.inv inv ON inv.invno = iprd.invno
    JOIN (
        SELECT
            iprd.prdno,
            MAX(iprd.date) AS UltimaData
        FROM sqldados.iprd iprd
        JOIN sqldados.inv inv ON inv.invno = iprd.invno
        WHERE
            inv.vendno = [$Vend]
            AND iprd.date BETWEEN [$P2i] AND [$P2f]
            AND iprd.invno > 1
        GROUP BY iprd.prdno
    ) ult ON ult.prdno = iprd.prdno
         AND ult.UltimaData = iprd.date
    WHERE
        inv.vendno = [$Vend]
    GROUP BY
        iprd.prdno, iprd.fob
) p2 ON p2.prdno = p.no

WHERE
    p1.Custo_P1 IS NOT NULL
    OR p2.Custo_P2 IS NOT NULL

ORDER BY
    p.no;
