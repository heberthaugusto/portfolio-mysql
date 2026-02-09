-- Report: E-commerce Sales by City with Percentage Share
-- Description:
--   Displays e-commerce sales grouped by city and state, including
--   the percentage contribution of each city to total sales.
--
-- Context: ERP / POS integrated environment
-- Database: MySQL
--
-- Objective:
--   Provide a geographic sales analysis for the online store,
--   highlighting sales concentration and regional performance.
--
-- Business Rules:
--   - Considers only valid sales (status = 0)
--   - Filters by store, POS and date range
--   - Allows optional filtering by city and state
--   - Calculates percentage share based on total sales in the period
--   - Adds a "Total Geral" row using UNION ALL
--
-- Parameters:
--   $loja   -> Store
--   $pdv    -> POS / Sales channel
--   $datai  -> Start date
--   $dataf  -> End date
--   $cidade -> City filter (optional)
--   $estado -> State filter (optional)
--
-- Output:
--   Cidade                  -> Customer city
--   Estado                  -> Customer state
--   Valor_Venda             -> Sales amount
--   Porcentagem_Vendas(%)   -> Percentage share of total sales

%vars
$loja={:store:LOJA;1;S;}
$pdv={PDV,5;2222;S;}
$datai={:d:Dada inicial;;S;}
$dataf={:d:Dada final;;S;}
$cidade={Cidade (Todas);Todas;N}
$estado={Estado (Todos);Todos;N}
%
SELECT
    custp.city1 AS Cidade,
    custp.state1 AS Estado,
    TRUNCATE(SUM(pxanf.grossamt) / 100, 2) AS Valor_Venda,
    TRUNCATE((SUM(pxanf.grossamt) / total_vendas.total) * 100, 2) AS 'Porcentagem_Vendas(%)'
FROM
    [BANCOPDV].pxanf
LEFT JOIN
    [BANCO].custp ON custp.no = pxanf.custno
CROSS JOIN (
    SELECT
        SUM(pxanf.grossamt) AS total
    FROM
        [BANCOPDV].pxanf
    LEFT JOIN
        [BANCO].custp ON custp.no = pxanf.custno
    WHERE
        pxanf.storeno = [$loja] AND
        pxanf.pdvno   = [$pdv]  AND
        pxanf.issuedate BETWEEN [$datai] AND [$dataf] AND
        pxanf.status  = 0 AND
        (custp.state1 LIKE "%[$estado]%" OR "[$estado]" = "Todos") AND
        (custp.city1  LIKE "%[$cidade]%" OR "[$cidade]" = "Todas")
) AS total_vendas
WHERE
    pxanf.storeno = [$loja] AND
    pxanf.pdvno   = [$pdv]  AND
    pxanf.issuedate BETWEEN [$datai] AND [$dataf] AND
    pxanf.status  = 0 AND
    (custp.state1 LIKE "%[$estado]%" OR "[$estado]" = "Todos") AND
    (custp.city1  LIKE "%[$cidade]%" OR "[$cidade]" = "Todas")
GROUP BY
    custp.city1, custp.state1

UNION ALL

SELECT
    'Total Geral' AS Cidade,
    'Total Geral' AS Estado,
    TRUNCATE(SUM(pxanf.grossamt) / 100, 2) AS Valor_Venda,
    100 AS 'Porcentagem_Vendas(%)'
FROM
    [BANCOPDV].pxanf
LEFT JOIN
    [BANCO].custp ON custp.no = pxanf.custno
WHERE
    pxanf.storeno = [$loja] AND
    pxanf.pdvno   = [$pdv]  AND
    pxanf.issuedate BETWEEN [$datai] AND [$dataf] AND
    pxanf.status  = 0 AND
    (custp.state1 LIKE "%[$estado]%" OR "[$estado]" = "Todos") AND
    (custp.city1  LIKE "%[$cidade]%" OR "[$cidade]" = "Todas")

ORDER BY
    Valor_Venda DESC;
