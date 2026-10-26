-- Relatório: Comparação de Gastos com Fornecedores por Período
-- Descrição:
--   Compara o total gasto em compras por fornecedor entre dois períodos
--   distintos, permitindo analisar a variação de custos de vários fornecedores.
--
-- Contexto: ambiente ERP
-- Banco de dados: MySQL
--
-- Objetivo:
--   Analisar como o gasto com compras evolui entre períodos e identificar
--   aumentos ou reduções de custo total por fornecedor.
--
-- Regras de negócio:
--   - Aceita até três fornecedores como filtro
--   - Soma o valor total das compras por fornecedor e período
--   - Considera os valores financeiros das notas de compra
--   - O resultado pode incluir fornecedores presentes em apenas um dos períodos
--
-- Parâmetros:
--   $vendno1 -> Código do fornecedor (1)
--   $vendno2 -> Código do fornecedor (2)
--   $vendno3 -> Código do fornecedor (3)
--   $p1i     -> Data inicial do período 1
--   $p1f     -> Data final do período 1
--   $p2i     -> Data inicial do período 2
--   $p2f     -> Data final do período 2
--
-- Saída:
--   Fornecedor -> Nome do fornecedor
--   Periodo1  -> Total comprado no período 1
--   Periodo2  -> Total comprado no período 2
--   Diferenca -> Diferença percentual entre os períodos

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
