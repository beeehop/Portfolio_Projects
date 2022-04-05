-- GM 2022 Q1 

-- Variables 
SET NOCOUNT ON
DECLARE @currentqtr CHAR(7)
DECLARE @baseqtr CHAR(7)
DECLARE @eoq CHAR(10)
DECLARE @boq CHAR(10)
DECLARE @daysinqtr FLOAT
DECLARE @days FLOAT
DECLARE @multiplier FLOAT  
-- Set beginning and end of qtr
SET @boq = '2022/01/01'
SET @eoq ='2022/03/31'

-- Set variable current quarter to 22 + -Q + 1 = 22-Q1
SET @currentqtr = 
            CONVERT(VARCHAR,DATEPART(yyyy,@eoq)) + 
            '-Q' + 
            CONVERT(VARCHAR,DATEPART(q,@eoq))
-- Set variable baseqtr to 21 + -Q + 1 = 21-Q1
SET @baseqtr = 
            CONVERT(VARCHAR,DATEPART(yyyy,DATEADD(yyyy,-1,@eoq))) + 
            '-Q' + 
            CONVERT(VARCHAR,DATEPART(q,@eoq));
-- Set days in qtr - if qtr 2 or 3 then 64, 1 then 63, otherwise 61 
SET @daysinqtr = 
			(
			CASE 
			WHEN DATEPART(q,@eoq) IN (2,3) THEN 64  
			WHEN DATEPART(q,@eoq) IN (1) THEN 63 
			ELSE 61 END
			)
-- Count current days excluding holidays  
SET @days = 
		    ( 
		    SELECT 
                COUNT(DISTINCT monthdayyear) 
		    FROM AM_SALE AS s 
            JOIN AM_CUST AS c 
            ON s.custnum = c.custnum 
		    WHERE monthdayyear BETWEEN @boq AND @eoq 
		    AND commissionable = 'y'  
		    AND zone IN ('BLUE RIDGE', 
                    'CONTINENTAL', 
                    'GREAT LAKES', 
                    'MID-ATLANTIC',
                    'MIDWEST', 
                    'NORTHEAST', 
                    'SOUTHEAST', 
                    'SOUTHWEST', 
                    'WESTERN') 
		    AND netrev NOT IN (0)
            AND NOT DATEPART(weekday,monthdayyear) IN (7,1)  
            AND NOT monthdayyear IN ('2022/02/21', 
                                '2022/05/30', 
                                '2022/07/04', 
                                '2022/09/05', 
                                '2022/11/24', 
                                '2022/11/25', 
                                '2022/12/23',
                                '2022/12/26',
                                '2022/12/31')  
		)

SET @multiplier = 
                @days / @daysinqtr;

-- End variables

-- Main Data Query
WITH main AS (
-- Select list
SELECT 
    cust.zone,
    netrev, 
    item.GroupForecast, 
    qtr, 
    USER_NAME
-- From tables and joined tables 
FROM AM_CUST AS cust
JOIN AM_SALE AS sale
ON cust.custnum = sale.custnum  
JOIN AM_ITEM AS item 
ON sale.itemnum = item.itemnum  

-- Filters
WHERE commissionable IN ('Y') 
AND sale.qtr IN (@baseqtr, @currentqtr, 
    (CASE 
    WHEN sale.monthdayyear IN ('2020-12-31 00:00:00.000')
    AND inv_no NOT IN (96820065,
                96820046,
                96820047,
                96820048,
                96820049,
                96820050,
                96820051,
                96820052,
                96820053,
                96819786) 
    THEN sale.qtr ELSE NULL END))
AND cust.zone IN ('BLUE RIDGE', 
                'CONTINENTAL', 
                'GREAT LAKES', 
                'MID-ATLANTIC',
                'MIDWEST', 
                'NORTHEAST', 
                'SOUTHEAST', 
                'SOUTHWEST', 
                'WESTERN') 
AND item.GroupForecast NOT IN ('RAPID RESPONSE',
                                 'OCCLUSION/ANGIO', 
                                 'EPIX S/I', 
                                 'UROLOGY',
                                 'VOYANT GENERATOR',
                                 'CATHETERS')
AND item.GroupForecast NOT LIKE '%REUS%'
AND item.GroupForecast NOT LIKE 'SIMSEI%'
AND item.GroupForecast NOT LIKE 'VASCULAR%'

UNION ALL
-- Select list
SELECT
    cust.zone,
    netrev, 
    item.GroupForecast, 
    qtr, 
    USER_NAME
-- Tables
FROM Back_Trace AS bt
JOIN AM_CUST AS cust
ON bt.custnum = cust.custnum  
JOIN AM_ITEM AS item 
ON bt.itemnum = item.itemnum  

--Filters
WHERE commissionable IN ('Y') 
AND qtr IN (@baseqtr, @currentqtr)
AND cust.zone IN ('BLUE RIDGE', 
                'CONTINENTAL', 
                'GREAT LAKES', 
                'MID-ATLANTIC',
                'MIDWEST', 
                'NORTHEAST', 
                'SOUTHEAST', 
                'SOUTHWEST', 
                'WESTERN') 
AND item.GroupForecast NOT IN ('RAPID RESPONSE',
                                 'OCCLUSION/ANGIO', 
                                 'EPIX S/I', 
                                 'UROLOGY',
                                 'VOYANT GENERATOR',
                                 'CATHETERS')
AND item.GroupForecast NOT LIKE '%REUS%'
AND item.GroupForecast NOT LIKE 'SIMSEI%'
AND item.GroupForecast NOT LIKE 'VASCULAR%'
),

gel AS (

SELECT 
    cust.zone,
    rep.region,
    rep.territory,
    rep.territory_no, 
    netrev, 
    qtr,
    cust.slspsn_no,
    USER_NAME

FROM AM_CUST AS cust 
JOIN AM_SALE AS sale 
ON cust.custnum = sale.custnum
JOIN AM_ITEM AS item
ON sale.itemnum = item.itemnum
JOIN AM_SLSPSN AS rep 
ON cust.slspsn_no = rep.slspsn_no 

WHERE commissionable IN ('Y') 
AND sale.qtr IN (@baseqtr, @currentqtr, 
    (CASE 
    WHEN sale.monthdayyear IN ('2020-12-31 00:00:00.000')
    AND inv_no NOT IN (96820065,
                96820046,
                96820047,
                96820048,
                96820049,
                96820050,
                96820051,
                96820052,
                96820053,
                96819786) 
    THEN sale.qtr ELSE NULL END))
-- AND cust.zone IN ('BLUE RIDGE', 
--                 'CONTINENTAL', 
--                 'GREAT LAKES', 
--                 'MID-ATLANTIC',
--                 'MIDWEST', 
--                 'NORTHEAST', 
--                 'SOUTHEAST', 
--                 'SOUTHWEST', 
--                 'WESTERN') 
AND (GroupForecast LIKE '%GEL%'
OR GroupForecast IN ('KITS MIGS')
OR GroupForecast IN ('CES ALEXIS TROCAR'))

UNION ALL 

SELECT 
    cust.zone,
    rep.region,
    rep.territory,
    rep.territory_no,  
    netrev, 
    qtr,
    cust.slspsn_no,
    USER_NAME

FROM Back_Trace AS bt
JOIN AM_CUST AS cust
ON bt.custnum = cust.custnum  
JOIN AM_ITEM AS item 
ON bt.itemnum = item.itemnum  
JOIN AM_SLSPSN AS rep 
ON cust.slspsn_no = rep.slspsn_no 

WHERE commissionable IN ('Y') 
AND qtr IN (@baseqtr, @currentqtr)
-- AND cust.zone IN ('BLUE RIDGE', 
--                 'CONTINENTAL', 
--                 'GREAT LAKES', 
--                 'MID-ATLANTIC',
--                 'MIDWEST', 
--                 'NORTHEAST', 
--                 'SOUTHEAST', 
--                 'SOUTHWEST', 
--                 'WESTERN') 
AND (item.GroupForecast LIKE '%GEL%'
OR item.GroupForecast IN ('KITS MIGS')
OR item.GroupForecast IN ('CES ALEXIS TROCAR'))

),

ortho AS (

SELECT 
    cust.zone,
    rep.region,
    rep.territory,
    rep.territory_no, 
    netrev, 
    qtr,
    rep.slspsn_no,
    USER_NAME

FROM AM_CUST AS cust 
JOIN AM_SALE AS sale 
ON cust.custnum = sale.custnum
JOIN AM_ITEM AS item
ON sale.itemnum = item.itemnum
JOIN AM_SLSPSN AS rep 
ON cust.slspsn_no = rep.slspsn_no 

WHERE commissionable IN ('Y') 
AND sale.qtr IN (@baseqtr, @currentqtr, 
    (CASE 
    WHEN sale.monthdayyear IN ('2020-12-31 00:00:00.000')
    AND inv_no NOT IN (96820065,
                96820046,
                96820047,
                96820048,
                96820049,
                96820050,
                96820051,
                96820052,
                96820053,
                96819786) 
    THEN sale.qtr ELSE NULL END))
-- AND cust.zone IN ('BLUE RIDGE', 
--                 'CONTINENTAL', 
--                 'GREAT LAKES', 
--                 'MID-ATLANTIC',
--                 'MIDWEST', 
--                 'NORTHEAST', 
--                 'SOUTHEAST', 
--                 'SOUTHWEST', 
--                 'WESTERN') 
AND item.GroupForecast LIKE 'ALEXIS%'

UNION ALL 

SELECT 
    cust.zone,
    rep.region,
    rep.territory,
    rep.territory_no,  
    netrev, 
    qtr,
    rep.slspsn_no,
    USER_NAME

FROM Back_Trace AS bt
JOIN AM_CUST AS cust
ON bt.custnum = cust.custnum  
JOIN AM_ITEM AS item 
ON bt.itemnum = item.itemnum  
JOIN AM_SLSPSN AS rep 
ON cust.slspsn_no = rep.slspsn_no 

WHERE commissionable IN ('Y') 
AND qtr IN (@baseqtr, @currentqtr)
-- AND cust.zone IN ('BLUE RIDGE', 
--                 'CONTINENTAL', 
--                 'GREAT LAKES', 
--                 'MID-ATLANTIC',
--                 'MIDWEST', 
--                 'NORTHEAST', 
--                 'SOUTHEAST', 
--                 'SOUTHWEST', 
--                 'WESTERN') 
AND item.GroupForecast LIKE 'ALEXIS%'

),

mainRev AS (

SELECT
    zone,
    
    -- Qtrly Growth Coms
        SUM(netrev*
        (CASE 
        WHEN qtr IN (@currentqtr)
        THEN 1 ELSE 0 END))
    AS CurrentRev,
        (SUM(netrev*
        (CASE 
        WHEN qtr IN (@currentqtr)
        AND USER_NAME NOT IN ('TRACE TEAM')
        THEN 1 ELSE 0 END)) / @multiplier + 
        SUM(netrev*
        (CASE
        WHEN qtr IN (@currentqtr)
        AND USER_NAME IN ('TRACE TEAM')
        THEN 1 ELSE 0 END)))
    AS ProjRev,
        ROUND(SUM(netrev*
        (CASE
        WHEN qtr IN ('2020-Q4', @baseqtr)
        THEN 1 ELSE 0 END)),0) 
    AS BaseRev,

    -- Voyant Growth Rev Bonus
        SUM(netrev*
        (CASE 
        WHEN qtr IN (@currentqtr)
        AND GroupForecast IN ('KIT VOYANT','VOYANT DISPOSABLES')
        THEN 1 ELSE 0 END))
    AS CurrentVoyantRev,
        (SUM(netrev*
        (CASE 
        WHEN qtr IN (@currentqtr)
        AND USER_NAME NOT IN ('TRACE TEAM')
        AND GroupForecast IN ('KIT VOYANT','VOYANT DISPOSABLES')
        THEN 1 ELSE 0 END)) / @multiplier + 
        SUM(netrev*
        (CASE
        WHEN qtr IN (@currentqtr)
        AND GroupForecast IN ('KIT VOYANT','VOYANT DISPOSABLES')
        AND USER_NAME IN ('TRACE TEAM')
        THEN 1 ELSE 0 END)))
    AS ProjVoyantRev,
        ROUND(SUM(netrev*
        (CASE
        WHEN qtr IN ('2020-Q4', @baseqtr)
        AND GroupForecast IN ('KIT VOYANT','VOYANT DISPOSABLES')
        THEN 1 ELSE 0 END)),0) 
    AS BaseVoyantRev


FROM main

GROUP BY zone 

),

gelRev AS (

SELECT 
    zone,
        -- Gel Qtrly Growth Coms
        SUM(netrev*
        (CASE 
        WHEN qtr IN (@currentqtr)
        THEN 1 ELSE 0 END))
    AS CurrentGelRev,
        (SUM(netrev*
        (CASE 
        WHEN qtr IN (@currentqtr)
        AND USER_NAME NOT IN ('TRACE TEAM')
        THEN 1 ELSE 0 END)) / @multiplier + 
        SUM(netrev*
        (CASE
        WHEN qtr IN (@currentqtr)
        AND USER_NAME IN ('TRACE TEAM')
        THEN 1 ELSE 0 END)))
    AS ProjGelRev,
        SUM(netrev*
        (CASE
        WHEN qtr IN ('2020-Q4', @baseqtr)
        THEN 1 ELSE 0 END))
    AS BaseGelRev

FROM gel

GROUP BY zone

),

orthoRev AS (

SELECT 
    zone,
        -- Horizon Qtrly Growth Coms
        SUM(netrev*
        (CASE 
        WHEN qtr IN (@currentqtr)
        THEN 1 ELSE 0 END))
    AS CurrentOrthoRev,
        (SUM(netrev*
        (CASE 
        WHEN qtr IN (@currentqtr)
        AND USER_NAME NOT IN ('TRACE TEAM')
        THEN 1 ELSE 0 END)) / @multiplier + 
        SUM(netrev*
        (CASE
        WHEN qtr IN (@currentqtr)
        AND USER_NAME IN ('TRACE TEAM')
        THEN 1 ELSE 0 END)))
    AS ProjOrthoRev,
        SUM(netrev*
        (CASE
        WHEN qtr IN ('2020-Q4', @baseqtr)
        THEN 1 ELSE 0 END))
    AS BaseOrthoRev

FROM ortho

GROUP BY zone

),

HorizonRev AS (

SELECT 
    g.zone,
        (CurrentGelRev + CurrentOrthoRev)
    AS CurrentHorizonRev,
        (ProjGelRev + ProjOrthoRev)
    AS ProjHorizonRev,
        (BaseGelRev + BaseOrthoRev)
    AS BaseHorizonRev

FROM gelRev AS g 
JOIN orthoRev AS o 
ON g.zone = o.zone

)

SELECT 
    m.zone,
    CurrentRev,
    ProjRev,
    BaseRev,
    CurrentHorizonRev,
    ProjHorizonRev,
    BaseHorizonRev,
    CurrentVoyantRev,
    ProjVoyantRev,
    BaseVoyantRev

FROM mainRev AS m 
JOIN HorizonRev AS h 
ON m.zone = h.zone 

ORDER BY h.zone 
