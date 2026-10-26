-- Relatório: Peso do Estoque Atual por Fornecedor
-- Descrição:
--   Exibe a quantidade em estoque e o peso total agrupados por produto,
--   filtrados por fornecedor e loja.
--
-- Contexto: ambiente ERP
-- Banco de dados: MySQL
--
-- Objetivo:
--   Dar visibilidade ao estoque por fornecedor, apoiando o controle
--   de estoque e a análise logística.
--
-- Regras de negócio:
--   - Considera as quantidades de atacado e varejo
--   - Permite filtrar por loja (0 = todas as lojas)
--   - Exclui produtos descontinuados
--   - Calcula o peso total do estoque em KG
--
-- Parâmetros:
--   $fn   -> Código do fornecedor
--   $loja -> Loja (0 = todas)
--
-- Saída:
--   Loja          -> Loja
--   Produto       -> SKU do produto
--   Descricao     -> Descrição do produto
--   RefFabr       -> Referência do fabricante
--   PesoUnitKG    -> Peso unitário em KG
--   QtdeEstoque   -> Quantidade em estoque
--   PesoEstoqueKG -> Peso total do estoque em KG

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
