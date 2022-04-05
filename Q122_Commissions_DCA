-- DCA 2022 Q1 

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


WITH repZone AS (

    SELECT *
    FROM (
        VALUES
            (00010388, 'RAY DUPLAIN', 322, 'MID-ATLANTIC' ),
            (00003159, 'STAN HUEY', 325, 'BLUE RIDGE' ),
            (00007300, 'MATT DIAL', 298, 'GREAT LAKES' ),
            (00003463, 'CHRISTOPHER LYONS', 329, 'MID-ATLANTIC' ),
            (00014739, 'MICHAEL MACKEY', 295, 'GREAT LAKES' ),
            (00018369, 'MICHAEL MARCUM', 317, 'BLUE RIDGE' ),
            (00010062, 'JUSTIN RANKIN', 328, 'BLUE RIDGE' ),
            (00003256, 'STEVE KOEHNE', 332, 'SOUTHEAST' ),
            (00010266, 'JASON INESTROZA', 461, 'GREAT LAKES' ),
            (00007641, 'RENEE BARTOLOMEI', 324, 'NORTHEAST' ),
            (00003332, 'CRAIG PURSER', 297, 'CONTINENTAL' ),
            (00003973, 'NICOLE VORKAPIC', 318, 'SOUTHWEST' ),
            (00011742, 'KATHY SAWYERS', 460, 'GREAT LAKES' ),
            (00006443, 'ANDY TAYLOR', 558, 'CONTINENTAL' ),
            (00015638, 'SHAWN ASUNCION', 291, 'WESTERN' ),
            (00015667, 'RODNEY VIETZ', 287, 'WESTERN' ),
            (00010892, 'ZACH MITCHELL', 290, 'WESTERN' ),
            (00016251, 'KORTNEE VIRUS', 293, 'WESTERN' ),
            (00003256, 'OPEN DCA #327 Atlantic S', 327, 'MID-ATLANTIC'),
            (00003256, 'OPEN DCA #292 Rocky Mountains', 292, NULL),
            (00003256, 'OPEN DCA #330 Ozarks', 330, 'MIDWEST')
        ) AS a (pernr, rep_name, territory_no, primary_zone)
    ),

-- Main Data Query
main AS (
-- Select list
SELECT 
    RTRIM(rep.region) AS region,
   -- cust.zone,
    RTRIM(cust.slspsn_name_6) AS rep,
	rep.slspsn_pernr,
    territory_no,
    rep.territory, 
    netrev, 
    rep.qtrquota,
    item.GroupForecast, 
    qtr, 
    USER_NAME
-- From tables and joined tables 
FROM AM_CUST AS cust
JOIN AM_SALE AS sale
ON cust.custnum = sale.custnum  
JOIN AM_ITEM AS item 
ON sale.itemnum = item.itemnum  
JOIN AM_SLSPSN AS rep 
ON cust.slspsn_no_6 = rep.slspsn_no
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
AND slspsn_name_6 NOT IN ('') 
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
    RTRIM(rep.region) AS region,
   -- cust.zone,
    RTRIM(cust.slspsn_name_6) AS rep,
	rep.slspsn_pernr,
    territory_no,
    rep.territory, 
    netrev, 
    rep.qtrquota,
    item.GroupForecast, 
    qtr, 
    USER_NAME
-- Tables
FROM Back_Trace AS bt
JOIN AM_CUST AS cust
ON bt.custnum = cust.custnum  
JOIN AM_ITEM AS item 
ON bt.itemnum = item.itemnum  
JOIN AM_SLSPSN AS rep 
ON cust.slspsn_no_6 = rep.slspsn_no
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

zoneMain AS (

SELECT 
    cust.zone, 
    netrev,
    USER_NAME
    
FROM AM_SALE AS sale
JOIN AM_CUST AS cust 
ON sale.custnum = cust.custnum
JOIN AM_ITEM AS item 
ON sale.itemnum = item.itemnum

WHERE commissionable IN ('Y') 
AND sale.qtr IN ( @currentqtr)
    
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

SELECT 
    cust.zone, 
    netrev,
    USER_NAME
    
FROM Back_Trace AS bt
JOIN AM_CUST AS cust 
ON bt.custnum = cust.custnum
JOIN AM_ITEM AS item 
ON bt.itemnum = item.itemnum

WHERE commissionable IN ('Y') 
AND qtr IN ( @currentqtr) 
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

zoneTarget AS (

SELECT 
    zone,
    qtrquota AS TargetZoneRev
    
FROM AM_SLSPSN
WHERE zone IN ('BLUE RIDGE', 
                'CONTINENTAL', 
                'GREAT LAKES', 
                'MID-ATLANTIC',
                'MIDWEST', 
                'NORTHEAST', 
                'SOUTHEAST', 
                'SOUTHWEST', 
                'WESTERN')
AND reptype_no IN ('19')
),

zoneRev AS (

SELECT 
    zonemain.zone, 
        ROUND(SUM(netrev),0)
    AS CurrentZoneRev,
        ROUND(SUM(netrev) / @multiplier,0)
    AS ProjZoneRev,
   TargetZoneRev

FROM zoneMain
--FULL OUTER JOIN repZone
--ON zoneMain.zone = primary_zone 
JOIN zoneTarget 
ON zonemain.zone = zoneTarget.zone

GROUP BY zonemain.zone, TargetZoneRev
),

mainRev AS (

SELECT  
    region,
    territory_no, 
    territory,
    rep,
    slspsn_pernr,
    -- Current Voyant Disposable Rev
        SUM(netrev*
        (CASE 
        WHEN qtr IN (@currentqtr)
        AND GroupForecast IN ('KIT VOYANT','VOYANT DISPOSABLES')
        THEN 1 ELSE 0 END)) 
    AS CurrentVoyantRev,
        --Projected DispVoyant Rev 
        ROUND((SUM(netrev*
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
        THEN 1 ELSE 0 END))),0)
    AS ProjVoyantRev,
    -- Base/Target Voyant Disposable Rev
        SUM(netrev*
        (CASE
        WHEN qtr IN ('2020-Q4', @baseqtr)
        AND GroupForecast IN ('KIT VOYANT','VOYANT DISPOSABLES')
        THEN 1 ELSE 0 END)) 
    AS BaseVoyantRev,
    -- Current revenue
        ROUND(SUM(netrev*
        (CASE 
        WHEN qtr IN (@currentqtr)
        THEN 1 ELSE 0 END)),0) 
    AS CurrentRev,
    -- Projected Revenue 
        ROUND((SUM(netrev*
        (CASE 
        WHEN qtr IN (@currentqtr)
        AND USER_NAME NOT IN ('TRACE TEAM')
        THEN 1 ELSE 0 END)) / @multiplier + 
        SUM(netrev*
        (CASE
        WHEN qtr IN (@currentqtr)
        AND USER_NAME IN ('TRACE TEAM')
        THEN 1 ELSE 0 END))),0)
    AS ProjRev,
    -- Target revenue
        qtrquota
    AS TargetRev

FROM main

GROUP BY region, territory_no, territory, rep, slspsn_pernr, qtrquota
)

SELECT DISTINCT
    region, 
    primary_zone, 
    territory, 
    mainRev.territory_no, 
    rep,
    pernr, 
    CurrentVoyantRev,
    ProjVoyantRev,
    BaseVoyantRev,
    CurrentRev,
    ProjRev,
    TargetRev,
    CurrentZoneRev,
    ProjZoneRev,
    TargetZoneRev

FROM mainRev
LEFT OUTER JOIN repZone 
ON mainRev.territory_no = repZone.territory_no
LEFT OUTER JOIN zoneRev 
ON repZone.primary_zone = zoneRev.zone
ORDER BY region, primary_zone



