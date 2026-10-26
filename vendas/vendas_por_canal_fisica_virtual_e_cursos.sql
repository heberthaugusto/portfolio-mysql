-- Relatório: Vendas por Canal: Loja Física, Loja Virtual e Cursos
-- Descrição:
--   Exibe os totais de venda segmentados por canal (loja física, loja virtual
--   e cursos) em um período, com valor de produtos, frete e totais.
--
-- Contexto: ambiente ERP
-- Banco de dados: MySQL
--
-- Objetivo:
--   Analisar a distribuição das vendas entre os canais e avaliar a
--   contribuição de cada modalidade para o faturamento total.
--
-- Regras de negócio:
--   - Separa as vendas por canal com base no PDV e na empresa
--   - Calcula valor de produtos, frete e total por canal
--   - Considera apenas notas válidas e emitidas
--   - Agrupa os dados por loja e data de emissão
--
-- Parâmetros:
--   $datai -> Data inicial
--   $dataf -> Data final
--
-- Saída:
--   ProdVirtual  -> Valor de produtos (loja virtual)
--   FreteVirtual -> Valor de frete (loja virtual)
--   TotalVirtual -> Total da loja virtual
--   ProdFisica   -> Valor de produtos (loja física)
--   FreteFisica  -> Valor de frete (loja física)
--   Total Fisica -> Total da loja física
--   Curso        -> Total de vendas de cursos
--   VTotal       -> Total geral de vendas

%vars
$datai={:d:Data Inicial}
$dataf={:d:Data Final}
%
#
SELECT
  nf.storeno Lj,
  nf.nfno Nota,
  nf.nfse Sr,
  SUM(IF(nf.pdvno<>1045 AND nf.empno=12, nf.grossamt-nf.fre_amt, 0)) ProdVirtual,
  SUM(IF(nf.empno<>681, nf.fre_amt, 0)) FreteVirtual,
  SUM(IF(nf.pdvno<>1045 AND nf.empno=12, nf.grossamt, 0)) TotalVirtual,
  SUM(IF(nf.pdvno<>1045 AND nf.empno<>12, nf.grossamt-nf.fre_amt, 0)) ProdFisica,
  SUM(IF(nf.empno<>12, nf.fre_amt, 0)) FreteFisica,
  SUM(IF(nf.pdvno=1045, nf.grossamt-nf.fre_amt, 0)) Curso,
  SUM(nf.grossamt) VTotal,
  nf.issuedate Data,
  DATE_FORMAT(nf.issuedate, '%d/%m/%Y') AS Dia
FROM
  sqldados.nf
WHERE
  nf.issuedate BETWEEN [$datai] AND [$dataf]
  AND nf.storeno >= 0
  AND nf.pdvno >= 0
  AND nf.xano > 100
  AND (nf.cfo IN (5102,5405,5933,6102,6108,6933) OR (nf.cfo=5929 AND nfse = 11))
  AND nf.status = 0
GROUP BY
  nf.storeno, nf.issuedate
ORDER BY
  nf.storeno, nf.issuedate, nf.nfno, nf.nfse;
#
SELECT
  Dia,
  ProdVirtual "|Produtos Virtual|",
  FreteVirtual "|Frete Virtual|",
  TotalVirtual "|Total Virtual|",
  ProdFisica "|Produtos Fisica|",
  FreteFisica "|Frete Fisica|",
  (ProdFisica + FreteFisica) AS "|Total Fisica|",
  (TotalVirtual + (ProdFisica + FreteFisica)) AS "|_TOTAL VIRTUAL + FISICA_|",
  Curso "|Total Cursos|",
  VTotal "|___TOTAL GERAL___|"
FROM
  [tabela];
