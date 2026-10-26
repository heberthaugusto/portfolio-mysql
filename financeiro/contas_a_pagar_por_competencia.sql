-- Relatório: Contas a Pagar por Período de Competência
-- Descrição:
--   Exibe as contas a pagar agrupadas por período de competência,
--   com o valor total a pagar por título, fornecedor e conta de despesa.
--
-- Contexto: ERP / módulo financeiro
-- Banco de dados: MySQL
--
-- Objetivo:
--   Apoiar a análise financeira e o acompanhamento de despesas pela
--   competência, e não pela data de vencimento.
--
-- Regras de negócio:
--   - Usa a data de competência do título (inv.date)
--   - Soma os valores a pagar por título
--   - Permite filtrar por intervalo de competência
--   - Inclui fornecedor e conta de despesa
--
-- Parâmetros:
--   $datai -> Data de competência inicial
--   $dataf -> Data de competência final
--
-- Saída:
--   CTP                   -> Número de controle do título a pagar
--   Fornecedor            -> Nome do fornecedor
--   ContaDespesa          -> Conta de despesa
--   Competencia           -> Data de competência
--   Valor Total Pagamento -> Valor total a pagar

%vars
$datai={:d:Data Competencia Inicial}
$dataf={:d:Data Competencia Final}
%
SELECT
    inv.invno AS "CTP",
    vend.name AS Fornecedor,
    CONCAT(acc.no,'-',acc.name) AS ContaDespesa,
    DATE_FORMAT(inv.date, '%d/%m/%y') AS Competencia,
    SUM(invxa.amtdue) AS "Valor Total Pagamento"
FROM
    sqldados.invxa
LEFT JOIN
    sqldados.inv ON inv.invno = invxa.invno AND inv.storeno = invxa.storeno
LEFT JOIN
    sqldados.vend ON vend.no = inv.vendno
LEFT JOIN
    sqldados.acc ON acc.no = inv.account
WHERE
    invxa.storeno >= 0 AND
    vendno >= 0 AND
    inv.date BETWEEN [$datai] AND [$dataf]
GROUP BY
    inv.invno, vend.name, acc.no, acc.name, inv.date
ORDER BY
    CONCAT(acc.no, '-', acc.name),
    inv.date;
