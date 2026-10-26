-- Relatório: Notas com Base de ICMS para Cálculo de PIS/COFINS
-- Descrição:
--   Lista as notas de entrada registradas em um período, destacando a base
--   de cálculo do ICMS usada na apuração de PIS e COFINS.
--
-- Contexto: ambiente ERP
-- Banco de dados: MySQL
--
-- Objetivo:
--   Dar visibilidade fiscal às entradas de notas e às respectivas bases de
--   cálculo, apoiando a apuração de PIS/COFINS e a conciliação fiscal.
--
-- Regras de negócio:
--   - Considera notas de entrada dentro do intervalo de datas
--   - Calcula valor contábil, valor dos produtos e base de ICMS
--   - Exclui CFOPs cancelados ou inválidos
--   - Aplica as flags fiscais gravadas nos campos de bits da nota
--   - Permite filtrar por loja e CFOP
--
-- Parâmetros:
--   $LJ -> Loja
--   $CF -> CFOP (0 = todos)
--   $DI -> Data de entrada inicial
--   $DF -> Data de entrada final
--
-- Saída:
--   CFOP             -> Código fiscal de operação
--   Entrada          -> Data de entrada
--   N_Fiscal         -> Número da nota fiscal
--   Vlr_Contabil     -> Valor contábil
--   Valor_Produtos   -> Valor dos produtos
--   Valor_Base_ICMS  -> Base de cálculo do ICMS
--   Valor_ICMS       -> Valor do ICMS
--   Base_Pis_Cofins  -> Base de cálculo de PIS/COFINS
--   Fornecedor       -> Fornecedor

%vars
$LJ = {:store:Loja;1;S}
$CF = {CFOP <ENTER>=Todos,4}
$DI = {:d:Data Ent Inicial}
$DF = {:d:Data Ent Final}
%
SELECT
    iprd.cfop CFOP,
    DATE_FORMAT(iprd.date,"%d/%m/%y") AS Entrada,
    LPAD(inv.nfname,8," ") AS N_Fiscal,
    (iprd.qtty / 1000) * (iprd.fob4 / 100) + iprd.icmsSubst + iprd.ipiamt - iprd.discount + IF(MID(LPAD(BIN(inv.bits), 16, '0'), 6, 1) = 1, iprd.m6, 0) + inv.despesas + inv.auxMoney2 AS Vlr_Contabil,
    (iprd.qtty / 1000) * (iprd.fob4 / 100) AS Valor_Produtos,
    iprd.baseICMS AS Valor_Base_ICMS,
    iprd.icms AS Valor_ICMS,
    (iprd.qtty / 1000) * (iprd.fob4 / 100) + iprd.icmsSubst + iprd.ipiamt - iprd.discount + IF(MID(LPAD(BIN(inv.bits), 16, '0'), 6, 1) = 1, iprd.m6, 0) + inv.despesas + inv.auxMoney2 - iprd.icms AS Base_Pis_Cofins,
    CONCAT(inv.vendno,"-",vend.sname) AS Fornecedor
FROM
    sqldados.iprd
LEFT JOIN
    sqldados.inv ON (iprd.invno = inv.invno AND inv.storeno = iprd.storeno)
LEFT JOIN
    sqldados.vend ON (inv.vendno = vend.no)
WHERE
    iprd.storeno = [$LJ]                 AND
    (iprd.date BETWEEN [$DI] AND [$DF])  AND
    (iprd.cfop = "[$CF]" OR "[$CF]" = 0) AND
    (iprd.cfop NOT IN (0,101,202))       AND
    inv.cfo NOT IN (0,101,202)           AND
    MID(LPAD(BIN(inv.bits),16,'0'),12,1) = '0' AND
    IF("[$CF]" = 0, iprd.cfop NOT IN (1253,1303,2303,1353,2353,1933,2933), 0=0)
ORDER BY
    iprd.storeno, iprd.cfop, inv.nfname;
