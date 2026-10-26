-- Relatório: Saldo de Estoque por Mês/Ano e Fornecedor
-- Descrição: Exibe o saldo de estoque agrupado por produto para um período e fornecedor selecionados.
-- Contexto: ambiente ERP
-- Banco de dados: MySQL
-- Parâmetros:
--   $data  -> Data de referência do estoque (mês/ano)
--   $forn  -> Código do fornecedor
-- Observações:
--   - Exclui produtos descontinuados
--   - Considera apenas a loja 1
--   - SKU formatado com 6 dígitos

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
