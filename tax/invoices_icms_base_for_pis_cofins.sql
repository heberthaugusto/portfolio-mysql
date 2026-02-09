-- Report: Invoices with ICMS Base for PIS/COFINS Calculation
-- Description:
--   Lists inbound invoices recorded within a selected period, highlighting
--   ICMS taxable base values used for PIS and COFINS calculation.
--
-- Context: ERP environment
-- Database: MySQL
--
-- Objective:
--   Provide fiscal visibility over invoice entries and their respective
--   tax bases to support PIS/COFINS calculation and tax reconciliation.
--
-- Business Rules:
--   - Considers inbound invoices within a date range
--   - Calculates accounting value, product value and ICMS base
--   - Excludes canceled or invalid CFOPs
--   - Applies fiscal flags stored in invoice bit fields
--   - Supports filtering by store and CFOP
--
-- Parameters:
--   $LJ -> Store
--   $CF -> CFOP (0 = All)
--   $DI -> Start entry date
--   $DF -> End entry date
--
-- Output:
--   CFOP             -> Fiscal operation code
--   Entrada          -> Entry date
--   N_Fiscal         -> Invoice number
--   Vlr_Contabil     -> Accounting value
--   Valor_Produtos   -> Product value
--   Valor_Base_ICMS  -> ICMS tax base
--   Valor_ICMS       -> ICMS amount
--   Base_Pis_Cofins  -> Tax base for PIS/COFINS
--   Fornecedor       -> Supplier

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
