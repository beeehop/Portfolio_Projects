-- HSD 2022 Q1 

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

WITH main AS(

SELECT 
    cust.zone, 
    netrev,
    qtr,
    GroupForecast, 
    USER_NAME
    
FROM AM_SALE AS sale
JOIN AM_CUST AS cust 
ON sale.custnum = cust.custnum
JOIN AM_ITEM AS item 
ON sale.itemnum = item.itemnum

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

SELECT 
    cust.zone, 
    netrev,
    qtr,
    item.GroupForecast,
    USER_NAME
    
FROM Back_Trace AS bt
JOIN AM_CUST AS cust 
ON bt.custnum = cust.custnum
JOIN AM_ITEM AS item 
ON bt.itemnum = item.itemnum

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

mainTarget AS (

SELECT 
    zone,
    CLIP_APPLIER_TARGET,
    qtrquota AS ZoneTargetRev
    
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

mainRev AS (

SELECT 
    mainTarget.zone, 
        ROUND(SUM(netrev*(
        CASE 
        WHEN qtr IN (@currentqtr)
        THEN 1 ELSE 0 END)),0) 
    AS CurrentRev,
        ROUND((SUM(netrev*(
        CASE 
        WHEN qtr IN (@currentqtr)
        AND USER_NAME NOT IN ('TRACE TEAM')
        THEN 1 ELSE 0 END)) / @multiplier +
        SUM(netrev*(
        CASE 
        WHEN qtr IN (@currentqtr)
        AND USER_NAME IN ('TRACE TEAM')
        THEN 1 ELSE 0 END
        ))),0) 
    AS ProjRev,
        ROUND(SUM(netrev*(
        CASE
        WHEN qtr IN ('2020-Q4', @baseqtr)
        THEN 1 ELSE 0 END)),0) 
    AS BaseRev,
        ROUND(SUM(netrev*(
        CASE 
        WHEN qtr IN (@currentqtr)
        AND (GroupForecast LIKE '%CLIP%' 
        OR GroupForecast IN ('KIT LAP CHOLE'))
        THEN 1 ELSE 0 END)),0) 
    AS CurrentClipRev,
        ROUND((SUM(netrev*
        (CASE 
        WHEN qtr IN (@currentqtr)
        AND USER_NAME NOT IN ('TRACE TEAM')
        AND (GroupForecast LIKE '%CLIP%' 
        OR GroupForecast IN ('KIT LAP CHOLE'))
        THEN 1 ELSE 0 END)) / @multiplier + 
        SUM(netrev*
        (CASE
        WHEN qtr IN (@currentqtr)
        AND (GroupForecast LIKE '%CLIP%' 
        OR GroupForecast IN ('KIT LAP CHOLE'))
        AND USER_NAME IN ('TRACE TEAM')
        THEN 1 ELSE 0 END))),0)
    AS ProjClipRev,
        CAST(CAST(CLIP_APPLIER_TARGET AS NUMERIC) AS INT)
    AS ClipTargetRev,
    ZoneTargetRev


FROM main
JOIN mainTarget
ON main.zone = mainTarget.zone
GROUP BY mainTarget.zone, CLIP_APPLIER_TARGET, ZoneTargetRev
)

SELECT *
FROM mainRev
