-- SR Director Horizon II FIT 2022 Q1

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

WITH mainGel AS (

SELECT 
        (CASE 
        WHEN rep.region IN ('APS-SOUTHEAST REGIO', 'APS-NORTHEAST REGIO')
        THEN 'EAST' ELSE 'WEST' END) 
    AS OverallRegion,
    rep.zone,
    rep.region,
    rep.territory,
    rep.territory_no, 
    netrev, 
    qtr,
    cust.slspsn_no_2,
    USER_NAME

FROM AM_CUST AS cust 
JOIN AM_SALE AS sale 
ON cust.custnum = sale.custnum
JOIN AM_ITEM AS item
ON sale.itemnum = item.itemnum
JOIN AM_SLSPSN AS rep 
ON cust.slspsn_no_2 = rep.slspsn_no 

WHERE qtr IN (@currentqtr)
AND commissionable IN ('Y')
AND (GroupForecast LIKE '%GEL%'
OR GroupForecast IN ('KITS MIGS')
OR item.GroupForecast IN ('CES ALEXIS TROCAR'))

UNION ALL 

SELECT 
    (CASE 
        WHEN rep.region IN ('APS-SOUTHEAST REGIO', 'APS-NORTHEAST REGIO')
        THEN 'EAST' ELSE 'WEST' END) 
    AS OverallRegion,
    rep.zone,
    rep.region,
    rep.territory,
    rep.territory_no,  
    netrev, 
    qtr,
    cust.slspsn_no_2,
    USER_NAME

FROM Back_Trace AS bt
JOIN AM_CUST AS cust
ON bt.custnum = cust.custnum  
JOIN AM_ITEM AS item 
ON bt.itemnum = item.itemnum  
JOIN AM_SLSPSN AS rep 
ON cust.slspsn_no_2 = rep.slspsn_no 

WHERE qtr IN (@currentqtr)
AND commissionable IN ('Y')
AND (item.GroupForecast LIKE '%GEL%'
OR item.GroupForecast IN ('KITS MIGS')
OR item.GroupForecast IN ('CES ALEXIS TROCAR'))

),

mainOrtho AS (

SELECT 
    (CASE 
        WHEN rep.region IN ('ALEXIS ORTHO EAST')
        THEN 'EAST' ELSE 'WEST' END) 
    AS OverallRegion,
    rep.zone,
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
ON cust.slspsn_no_5 = rep.slspsn_no 

WHERE qtr IN (@currentqtr)
AND commissionable IN ('Y')
AND GroupForecast IN ('ALEXIS ORTHOPAEDIC')

UNION ALL 

SELECT 
    (CASE 
        WHEN rep.region IN ('ALEXIS ORTHO EAST')
        THEN 'EAST' ELSE 'WEST' END) 
    AS OverallRegion,
    rep.zone,
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
ON cust.slspsn_no_5 = rep.slspsn_no 

WHERE qtr IN (@currentqtr)
AND commissionable IN ('Y')
AND item.GroupForecast IN ('ALEXIS ORTHOPAEDIC')

),

GelTarget AS (

SELECT 
    region,
    qtrquota AS GelRevTarget
FROM AM_SLSPSN AS rep 
WHERE reptype_no IN ('14', '91')
AND qtrquota NOT IN ('0')

),

OrthoTarget AS (

SELECT 
    region,
     qtrquota AS OrthoRevTarget
FROM AM_SLSPSN AS rep 
WHERE reptype_no IN ('39')
AND qtrquota NOT IN ('0')

),

GelRev AS (

SELECT  
    OverallRegion,
    m.zone, 
    m.region, 

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
    GelRevTarget AS Target

FROM mainGel AS m
JOIN GelTarget AS gt 
ON m.region = gt.region

GROUP BY 
    OverallRegion,
    m.zone, 
    m.region,
    GelRevTarget

),


OrthoRev AS (

SELECT  
    OverallRegion,
    m.zone, 
    m.region, 

        ROUND(SUM(netrev*
        (CASE 
        WHEN qtr IN (@currentqtr)
        THEN 1 ELSE 0 END)),0) 
    AS CurrentRev, 
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
    OrthoRevTarget AS Target

FROM mainOrtho AS m
JOIN OrthoTarget AS ot
ON m.region = ot.region


GROUP BY 
    OverallRegion,
    m.zone, 
    m.region, 
    OrthoRevTarget
)

SELECT
    OverallRegion,
    zone, 
    region,
    CurrentRev,
    ProjRev,
    Target

FROM GelRev AS g 


UNION 

SELECT 
    OverallRegion,
    zone, 
    region,
    CurrentRev,
    ProjRev,
    Target

FROM OrthoRev AS o
ORDER BY zone
