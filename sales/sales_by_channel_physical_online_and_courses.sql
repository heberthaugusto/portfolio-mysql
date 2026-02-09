-- Report: Sales by Channel: Physical Store, Online Store and Courses
-- Description:
--   Displays sales totals segmented by sales channel (physical store, online store
--   and courses) for a selected period, including product value, freight and totals.
--
-- Context: ERP environment
-- Database: MySQL
--
-- Objective:
--   Analyze sales distribution across different sales channels and evaluate
--   the contribution of each modality to total revenue.
--
-- Business Rules:
--   - Separates sales by channel based on PDV and company identifiers
--   - Calculates product value, freight and total amounts per channel
--   - Considers only valid and issued invoices
--   - Aggregates data by store and issue date
--
-- Parameters:
--   $datai -> Start date
--   $dataf -> End date
--
-- Output:
--   ProdVirtual  -> Product value (online sales)
--   FreteVirtual -> Freight value (online sales)
--   TotalVirtual -> Total online sales
--   ProdFisica   -> Product value (physical store)
--   FreteFisica  -> Freight value (physical store)
--   Total Fisica -> Total physical store sales
--   Curso        -> Course sales total
--   VTotal       -> Overall total sales

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
