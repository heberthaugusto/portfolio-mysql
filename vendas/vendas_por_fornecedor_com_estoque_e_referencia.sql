-- Relatório: Vendas por Fornecedor com Estoque e Referência do Produto
-- Descrição:
--   Exibe as quantidades vendidas e o estoque atual por fornecedor e produto,
--   com a referência do fabricante e agrupamento opcional por loja ou produto.
--
-- Contexto: ambiente ERP
-- Banco de dados: MySQL
--
-- Objetivo:
--   Analisar o desempenho de vendas por fornecedor relacionando as quantidades
--   vendidas com o estoque atual, para apoiar decisões operacionais e comerciais.
--
-- Regras de negócio:
--   - Agrupamento dinâmico por loja ou por produto
--   - Permite filtrar por loja ou consolidar todas as lojas
--   - Considera apenas transações de venda válidas
--   - Combina os dados de venda com o saldo atual de estoque
--
-- Parâmetros:
--   $fn   -> Código do fornecedor
--   $di   -> Data inicial
--   $df   -> Data final
--   $loja -> Loja (0 = todas as lojas)
--   $grp  -> Modo de agrupamento (0 = por loja e produto, 1 = por produto)
--
-- Saída:
--   Loja        -> Loja
--   Fornecedor  -> Nome do fornecedor
--   Produto     -> SKU do produto
--   Descricao   -> Descrição do produto
--   RefFabr     -> Referência do fabricante
--   Qtd.Vend    -> Quantidade vendida
--   Qtd.Estq    -> Quantidade atual em estoque

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
