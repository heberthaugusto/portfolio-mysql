-- Report: Supplier Purchase Spending Comparison by Period
-- Description:
--   Compares total purchase spending per supplier between two distinct periods,
--   allowing the analysis of cost variations across multiple suppliers.
--
-- Context: ERP environment
-- Database: MySQL
--
-- Objective:
--   Analyze how purchase spending evolves between periods and identify increases
--   or decreases in total costs by supplier.
--
-- Business Rules:
--   - Supports up to three suppliers as filters
--   - Aggregates total purchase amounts per supplier and period
--   - Considers financial amounts from purchase invoices
--   - Results may include suppliers present in only one of the periods
--
-- Parameters:
--   $vendno1 -> Supplier ID (1)
--   $vendno2 -> Supplier ID (2)
--   $vendno3 -> Supplier ID (3)
--   $p1i     -> Period 1 start date
--   $p1f     -> Period 1 end date
--   $p2i     -> Period 2 start date
--   $p2f     -> Period 2 end date
--
-- Output:
--   Fornecedor -> Supplier name
--   Periodo1  -> Total purchase amount in period 1
--   Periodo2  -> Total purchase amount in period 2
--   Diferenca -> Percentage difference between periods

%vars
$vendno1={:s:Fornecedor_1}
$vendno2={:s:Fornecedor_2}
$vendno3={:s:Fornecedor_3}
$p1i={:d:P1_Inicio}
$p1f={:d:P1_Fim}
$p2i={:d:P2_Inicio}
$p2f={:d:P2_Fim}
%
SELECT
    LEFT(vend.name,10) AS Fornecedor,

    CONCAT(
        'R$ ',
        FORMAT(SUM(
            CASE 
                WHEN inv.date BETWEEN [$p1i] AND [$p1f]
                THEN invxa.amtdue 
                ELSE 0 
            END
        ) / 100, 2, 'de_DE')
    ) AS Periodo1,

    CONCAT(
        'R$ ',
        FORMAT(SUM(
            CASE 
                WHEN inv.date BETWEEN [$p2i] AND [$p2f]
                THEN invxa.amtdue 
                ELSE 0 
            END
        ) / 100, 2, 'de_DE')
    ) AS Periodo2,

    CASE
        WHEN SUM(
            CASE 
                WHEN inv.date BETWEEN [$p1i] AND [$p1f]
                THEN invxa.amtdue 
                ELSE 0 
            END
        ) = 0
        THEN 0
        ELSE (
            SUM(
                CASE 
                    WHEN inv.date BETWEEN [$p2i] AND [$p2f]
                    THEN invxa.amtdue 
                    ELSE 0 
                END
            )
            -
            SUM(
                CASE 
                    WHEN inv.date BETWEEN [$p1i] AND [$p1f]
                    THEN invxa.amtdue 
                    ELSE 0 
                END
            )
        ) * 100 /
        SUM(
            CASE 
                WHEN inv.date BETWEEN [$p1i] AND [$p1f]
                THEN invxa.amtdue 
                ELSE 0 
            END
        )
    END AS Diferenca

FROM
    sqldados.invxa
LEFT JOIN sqldados.inv
       ON inv.invno   = invxa.invno
      AND inv.storeno = invxa.storeno
LEFT JOIN sqldados.vend
       ON vend.no = inv.vendno

WHERE
    invxa.storeno >= 0
    AND vend.no IN ([$vendno1], [$vendno2], [$vendno3])
    AND (
            inv.date BETWEEN [$p1i] AND [$p1f]
         OR inv.date BETWEEN [$p2i] AND [$p2f]
        )

GROUP BY
    vend.no,
    vend.name

ORDER BY
    vend.name;
