-- Report: High-Risk Online Order and Fraud Detection Monitoring
-- Description:
--    Identifies potential fraudulent orders by monitoring specific high-risk 
--    products and analyzing customer purchase history for potential chargebacks.
--
-- Context: ERP environment
-- Database: MySQL
--
-- Objective:
--    Mitigate financial loss by identifying suspicious orders that may be 
--    contested (chargeback) in the future. It focuses on high-risk items and 
--    new customers with low purchase frequency.
--
-- Business Rules:
--    - Highlights "Targeted Products" (Prod_Visados) frequently involved in fraud
--    - Identifies if an order contains only high-risk items or mixed goods
--    - Filters for new or low-frequency customers (3 or fewer successful sales)
--    - Excludes PIX payments (lower contestation risk) and filters by specific order flags
--    - Simplifies carrier identification to assist in logistics verification
--
-- Parameters:
--    $LJ -> Store number
--    $DI -> Start date
--    $DF -> End date
--
-- Output:
--    Pedido          -> Internal order number
--    Emissao         -> Issue date (DD/MM/YY)
--    Cliente         -> Customer name (truncated)
--    Pedido_Site     -> Online platform order ID
--    Valor_Total     -> Total order amount (items + extras)
--    Status_Pedido   -> Current order status (Reserved, Sold, Canceled)
--    Quant_Vendas_Cl -> Total successful sales history (helps identify new users)
--    Prod_Visados    -> Flag (YES/NO) if order contains high-risk/targeted products
--    Outros_Prod     -> Flag (YES/NO) if order contains common (non-targeted) products
--    Transporte      -> Simplified carrier name or delivery method
%vars
$LJ = {:store:Loja;1;s}
$DI = {:d:Data Inicial}
$DF = {:d:Data    Final}
%
SELECT
  eord.ordno AS Pedido,
  DATE_FORMAT(eord.date,"%d/%m/%y") AS Emissao,
  LEFT(custp.name,20) AS Cliente,
  LPAD(eord.auxLong6,11," ") AS Pedido_Site,
  (eord.amount + eord.other) AS Valor_Total,
  
  CASE eord.status
    WHEN 2 THEN 'Reservado'
    WHEN 3 THEN 'Vendido'
    WHEN 5 THEN 'Cancelado'
    ELSE CONCAT('Status ', eord.status) 
  END AS Status_Pedido,

  (SELECT COUNT(*) 
   FROM sqldados.eord eord_vendas 
   WHERE eord_vendas.custno = eord.custno 
     AND eord_vendas.status = 3
  ) AS Quant_Vendas_Cl,

  IF(EXISTS(
    SELECT 1 
    FROM sqldados.eoprd 
    WHERE eoprd.storeno = eord.storeno 
      AND eoprd.ordno = eord.ordno 
      AND CAST(eoprd.prdno AS UNSIGNED) IN (
        52489, 62413, 62853, 67, 62, 70, 6980, 18740, 7091, 5149, 7058, 60772,
        11721, 58159, 58207, 58220, 58818, 58161, 25683, 25684, 25682, 25688,
        58209, 59617, 58125, 32939, 58211, 59618, 61303, 61302, 59008, 58215,
        59193, 58214, 58213, 58205, 58217, 25689, 32940, 51077, 11314, 10120,
        20352, 10121, 58718, 58719, 58720, 52385, 58721, 55908, 52384, 51742,
        51744, 51743, 51746, 51745, 59571, 59573, 59572, 57417, 58562, 57416,
        57419, 51948, 51950, 51947, 57418, 43305, 43308, 59726, 46438, 15180, 
        19068, 45217, 18632, 58080, 58082, 59262, 61808, 61809, 48049, 59836, 
        59837, 59838, 61996, 61811, 61810, 58311, 59263, 58727, 58085, 58087, 
        58010, 14901, 14903, 43277, 38516, 39870, 55601, 60231, 51862, 52934, 
        52935, 60228, 61297, 58916, 58918, 62467, 55881, 51740, 60033, 5265, 
        27218, 44571, 27219, 61403, 27217, 55081, 60936, 58917, 53237, 60229,
        53236, 61550, 8554, 56274)
  ), 'SIM', 'NAO') AS Prod_Visados,

  CASE
    WHEN NOT EXISTS (
      SELECT 1
      FROM sqldados.eoprd op_vis
      WHERE op_vis.storeno = eord.storeno
        AND op_vis.ordno   = eord.ordno
        AND CAST(op_vis.prdno AS UNSIGNED) IN (
        52489, 62413, 62853, 67, 62, 70, 6980, 18740, 7091, 5149, 7058, 60772,
        11721, 58159, 58207, 58220, 58818, 58161, 25683, 25684, 25682, 25688,
        58209, 59617, 58125, 32939, 58211, 59618, 61303, 61302, 59008, 58215,
        59193, 58214, 58213, 58205, 58217, 25689, 32940, 51077, 11314, 10120,
        20352, 10121, 58718, 58719, 58720, 52385, 58721, 55908, 52384, 51742,
        51744, 51743, 51746, 51745, 59571, 59573, 59572, 57417, 58562, 57416,
        57419, 51948, 51950, 51947, 57418, 43305, 43308, 59726, 46438, 15180, 
        19068, 45217, 18632, 58080, 58082, 59262, 61808, 61809, 48049, 59836, 
        59837, 59838, 61996, 61811, 61810, 58311, 59263, 58727, 58085, 58087, 
        58010, 14901, 14903, 43277, 38516, 39870, 55601, 60231, 51862, 52934, 
        52935, 60228, 61297, 58916, 58918, 62467, 55881, 51740, 60033, 5265, 
        27218, 44571, 27219, 61403, 27217, 55081, 60936, 58917, 53237, 60229,
        53236, 61550, 8554, 56274)
    ) THEN NULL

    WHEN EXISTS (
      SELECT 1
      FROM sqldados.eoprd op_out
      WHERE op_out.storeno = eord.storeno
        AND op_out.ordno   = eord.ordno
        AND CAST(op_out.prdno AS UNSIGNED) NOT IN (
        52489, 62413, 62853, 67, 62, 70, 6980, 18740, 7091, 5149, 7058, 60772,
        11721, 58159, 58207, 58220, 58818, 58161, 25683, 25684, 25682, 25688,
        58209, 59617, 58125, 32939, 58211, 59618, 61303, 61302, 59008, 58215,
        59193, 58214, 58213, 58205, 58217, 25689, 32940, 51077, 11314, 10120,
        20352, 10121, 58718, 58719, 58720, 52385, 58721, 55908, 52384, 51742,
        51744, 51743, 51746, 51745, 59571, 59573, 59572, 57417, 58562, 57416,
        57419, 51948, 51950, 51947, 57418, 43305, 43308, 59726, 46438, 15180, 
        19068, 45217, 18632, 58080, 58082, 59262, 61808, 61809, 48049, 59836, 
        59837, 59838, 61996, 61811, 61810, 58311, 59263, 58727, 58085, 58087, 
        58010, 14901, 14903, 43277, 38516, 39870, 55601, 60231, 51862, 52934, 
        52935, 60228, 61297, 58916, 58918, 62467, 55881, 51740, 60033, 5265, 
        27218, 44571, 27219, 61403, 27217, 55081, 60936, 58917, 53237, 60229,
        53236, 61550, 8554, 56274)
    ) THEN 'SIM'

    ELSE 'NAO'
  END AS Outros_Prod,

  CASE 
    WHEN carr.name = 'COOP. MOTOCICLISTAS DE BH E RM LTDA' THEN 'Coopermoto'
    WHEN carr.name = 'MANDAE SERVICOS DE CONSULTORIA' THEN 'Mandae'
    WHEN carr.name = 'EMPRESA BRAS CORREIOS E TELEGRAFOS' THEN 'Correios'
    WHEN carr.name = 'MARIA CHOCOLATE LTDA' THEN 'Lamamove'
    WHEN carr.name IS NULL OR TRIM(carr.name) = '' THEN 'Retirada ou Curso'
    ELSE carr.name 
  END AS Transporte

FROM
  sqldados.eord
LEFT JOIN
  sqldados.custp ON (eord.custno = custp.no)
LEFT JOIN
  sqldados.carr ON (carr.no = eord.padbyte)
LEFT JOIN
  sqldados.paym ON (paym.no = eord.paymno)

WHERE
  eord.storeno = [$LJ] AND
  (eord.date BETWEEN [$DI] AND [$DF]) AND
  eord.bits2&4096 = 4096 AND
  eord.auxLong6 > 0 AND
  paym.name <> 'PIX'

HAVING Quant_Vendas_Cl <= 3

ORDER BY
  Quant_Vendas_Cl ASC,
  Pedido_Site DESC
