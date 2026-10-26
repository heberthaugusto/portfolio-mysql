-- Relatório: Vendas do E-commerce por Cidade com Participação Percentual
-- Descrição:
--   Exibe as vendas do e-commerce agrupadas por cidade e estado, com a
--   participação percentual de cada cidade no total vendido.
--
-- Contexto: ERP integrado ao PDV
-- Banco de dados: MySQL
--
-- Objetivo:
--   Fornecer uma análise geográfica das vendas da loja virtual,
--   destacando a concentração de vendas e o desempenho por região.
--
-- Regras de negócio:
--   - Considera apenas vendas válidas (status = 0)
--   - Filtra por loja, PDV e intervalo de datas
--   - Permite filtro opcional por cidade e estado
--   - Calcula a participação percentual sobre o total vendido no período
--   - Adiciona a linha "Total Geral" com UNION ALL
--
-- Parâmetros:
--   $loja   -> Loja
--   $pdv    -> PDV / canal de venda
--   $datai  -> Data inicial
--   $dataf  -> Data final
--   $cidade -> Filtro por cidade (opcional)
--   $estado -> Filtro por estado (opcional)
--
-- Saída:
--   Cidade                  -> Cidade do cliente
--   Estado                  -> Estado do cliente
--   Valor_Venda             -> Valor vendido
--   Porcentagem_Vendas(%)   -> Participação percentual no total de vendas

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
