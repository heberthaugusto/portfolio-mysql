-- Relatório: Comparação de Preço de Compra por Fornecedor
-- Descrição:
--   Compara o preço de compra dos produtos entre dois períodos distintos
--   para um fornecedor, considerando o último preço de compra de cada
--   produto dentro de cada período.
--
-- Contexto: ambiente ERP
-- Banco de dados: MySQL
--
-- Objetivo:
--   Identificar variações de preço de compra entre períodos, indicando se
--   o produto ficou mais caro, mais barato ou manteve o preço.
--
-- Regras de negócio:
--   - Considera apenas a última compra de cada produto em cada período
--   - Soma a quantidade comprada por produto e período
--   - Ignora documentos com invno <= 1
--   - O resultado pode incluir produtos presentes em apenas um dos períodos
--
-- Nota técnica (portfólio):
--   As subconsultas duplicadas para cada período são intencionais. Em relatórios
--   de ERP, priorizei clareza e regras de negócio explícitas em vez de abstração.
--
-- Parâmetros:
--   $Vend -> Código do fornecedor
--   $P1i  -> Data inicial do período 1
--   $P1f  -> Data final do período 1
--   $P2i  -> Data inicial do período 2
--   $P2f  -> Data final do período 2
--
-- Saída:
--   RefFabr    -> Referência do fabricante
--   SKU        -> SKU do produto
--   Descricao  -> Descrição do produto
--   Qtd_Per_1  -> Quantidade comprada no período 1
--   Custo_Per_1-> Último custo de compra no período 1
--   Qtd_Per_2  -> Quantidade comprada no período 2
--   Custo_Per_2-> Último custo de compra no período 2
--   Comparacao -> Resultado da comparação (Mais caro / Mais barato / Igual)

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
