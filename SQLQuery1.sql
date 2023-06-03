-----------------------------------------------------------------------------------------------------------------------------------------------------------
/*	DATA SOURCE - https://github.com/AllThingsDataWithAngelina/DataSource/blob/main/sales_data_sample.csv
	DATA TIMELINE - 6TH JANUARY 2003 TO 31ST MAY 2005
	DATE OF DATA DOWNLOAD - 16TH NOVEMBER 2022 10:53AM
*/
-----------------------------------------------------------------------------------------------------------------------------------------------------------

-----------------------------------------------------------------------------------------------------------------------------------------------------------
/* QUESTIONS ANSWERED AT THE END OF THE ANALYSIS
	1. THE SALES THAT WAS ACCUMULATED PER YEAR.
	2. THE GROWTH IN REVENUE OVER TIME.
	3. THE REVENUE GOTTEN FROM VARIOUS DEAL SIZES.
	4. THE REVENUE GOTTEN, BROKEN UP BY MONTH TO SEE BEST PERFORMING MONTHS OR SEASONAL PRODUCTS.
	5. THE RFM ANALYSIS TO SHOW THE RECENCY, FREQUENCY AND MONETRY VALUE OF SALES.
	6. THE MOST SOLD PRODUCTS.
*/
-----------------------------------------------------------------------------------------------------------------------------------------------------------


-- Inspecting Data ----------------------------------------------------------------------------------------------------------------------------------------
SELECT *
FROM sales

SELECT DISTINCT STATUS 
FROM sales

SELECT DISTINCT YEAR_ID
FROM sales

SELECT *
FROM SALES
ORDER BY ORDERDATE 

SELECT DISTINCT PRODUCTLINE
FROM sales

SELECT DISTINCT COUNTRY
FROM sales

SELECT DISTINCT DEALSIZE
FROM sales

SELECT DISTINCT TERRITORY
FROM sales
-----------------------------------------------------------------------------------------------------------------------------------------------------------


-- Sales by product line
SELECT PRODUCTLINE, SUM(Sales) AS REVENUE
FROM sales
GROUP BY PRODUCTLINE
ORDER BY REVENUE DESC
-----------------------------------------------------------------------------------------------------------------------------------------------------------


-- Sales by year-------------------------------------------------------------------------------------------------------------------------------------------
SELECT YEAR_ID, SUM(Sales) AS REVENUE
FROM sales
GROUP BY YEAR_ID
ORDER BY REVENUE DESC

/* The sales for 2005 were low, so i dived to see what went wrong. I found out that the data covered only 5 months of 2005, as seen in the query below.*/
SELECT DISTINCT MONTH_ID
FROM sales
WHERE YEAR_ID = 2005

 /*TAKING THE SUM OF REVENUE FOR THE FIRST 5 MONTHS IN 2003 TO COMPARE WITH 2005*/
WITH TOT_03 AS(
SELECT MONTH_ID, SUM(SALES) AS REVENUE
FROM sales
WHERE YEAR_ID = 2003 AND MONTH_ID <= 5
GROUP BY MONTH_ID)
--ORDER BY MONTH_ID)
SELECT SUM(REVENUE) AS FIVE_MONTH_REVENUE_2003
FROM TOT_03;

 /*TAKING THE SUM OF REVENUE FOR THE FIRST 5 MONTHS IN 2004 TO COMPARE WITH 2005*/
WITH TOT_04 AS(
SELECT MONTH_ID, SUM(SALES) AS REVENUE
FROM sales
WHERE YEAR_ID = 2004 AND MONTH_ID <= 5
GROUP BY MONTH_ID)
--ORDER BY MONTH_ID)
SELECT SUM(REVENUE) AS FIVE_MONTH_REVENUE_2004
FROM TOT_04;

 /*TAKING THE SUM OF REVENUE FOR THE FIRST 5 MONTHS IN 2005*/
SELECT SUM(SALES) AS REVENUE
FROM sales
WHERE YEAR_ID = 2005;

/*We can see that the company is doing better overall, as there has been a steady increase in sales of the first five months, from 2003 to 2005
2004 had a 56.46 percentage increase from 2003
2005 had a 36.40 percentage increase from 2004*/
-----------------------------------------------------------------------------------------------------------------------------------------------------------


-- DEALSIZE------------------------------------------------------------------------------------------------------------------------------------------------
SELECT DEALSIZE, SUM(Sales) AS REVENUE
FROM sales
GROUP BY DEALSIZE
ORDER BY REVENUE DESC
-----------------------------------------------------------------------------------------------------------------------------------------------------------


-- REVENUE BY MONTH ---------------------------------------------------------------------------------------------------------------------------------------
SELECT MONTH_ID, SUM(Sales) AS REVENUE, COUNT(ORDERNUMBER) AS ORDERS
FROM sales
GROUP BY MONTH_ID
ORDER BY REVENUE DESC;

-- 2003
SELECT MONTH_ID, SUM(Sales) AS REVENUE, COUNT(ORDERNUMBER) AS ORDERS
FROM sales
WHERE YEAR_ID = 2003
GROUP BY MONTH_ID 
ORDER BY REVENUE DESC;

-- 2004
SELECT MONTH_ID, SUM(Sales) AS REVENUE, COUNT(ORDERNUMBER) AS ORDERS
FROM sales
WHERE YEAR_ID = 2004
GROUP BY MONTH_ID
ORDER BY REVENUE DESC;

-- 2005
SELECT MONTH_ID, SUM(Sales) AS REVENUE, COUNT(ORDERNUMBER) AS ORDERS
FROM sales
WHERE YEAR_ID = 2005
GROUP BY MONTH_ID
ORDER BY REVENUE DESC;

SELECT PRODUCTLINE, SUM(sales) AS REVENUE, COUNT(ORDERNUMBER) AS ORDERS
FROM sales
WHERE MONTH_ID = 11
GROUP BY PRODUCTLINE
ORDER BY REVENUE DESC

SELECT PRODUCTLINE, SUM(sales) AS REVENUE, COUNT(ORDERNUMBER) AS ORDERS
FROM sales
WHERE MONTH_ID = 1
GROUP BY PRODUCTLINE
ORDER BY REVENUE DESC
-----------------------------------------------------------------------------------------------------------------------------------------------------------


--RFM ANALYSIS --------------------------------------------------------------------------------------------------------------------------------------------
DROP TABLE IF EXISTS #rfm;
WITH rfm AS (
	SELECT	CUSTOMERNAME, 
			SUM(sales) AS MonetryValue, 
			AVG(sales) AS AverageMonetryValue,
			COUNT(ORDERNUMBER) AS Frequency, 
			MAX(ORDERDATE) AS LastOrderDate,
			(SELECT MAX(ORDERDATE) FROM sales) AS MaxOrderDate,
			DATEDIFF(DD, MAX(ORDERDATE), (SELECT MAX(ORDERDATE) FROM sales)) AS Recency
	FROM sales
	GROUP BY CUSTOMERNAME),
rfm_calc AS (
	SELECT	r.*,
		NTILE(5) OVER (ORDER BY Recency) AS rfm_Recency,
		NTILE(5) OVER (ORDER BY Frequency) AS rfm_Frequency,
		NTILE(5) OVER (ORDER BY AverageMonetryValue) AS rfm_AverageMonetryValue
	FROM rfm r)
SELECT *, rfm_Recency+rfm_Frequency+rfm_AverageMonetryValue AS rfm_cell,
		CAST (rfm_Recency AS varchar) + CAST (rfm_Frequency AS varchar) + CAST (rfm_AverageMonetryValue AS varchar) AS rfm_cell_string
INTO #rfm
FROM rfm_calc

SELECT	CUSTOMERNAME, rfm_Recency, rfm_Frequency, rfm_AverageMonetryValue, rfm_cell,
		CASE 
			WHEN rfm_cell >= 12 THEN 'Most Valued Customer'
			WHEN rfm_cell >= 9 THEN 'High Value Customer'
			WHEN rfm_cell  >= 6 /*OR rfm_cell < 9*/ THEN 'Average Value Customer'
			WHEN rfm_cell < 6 THEN 'Low Value Customer'
			END AS 'comment'
FROM #rfm
-----------------------------------------------------------------------------------------------------------------------------------------------------------

--PRODUCTS SOLD TOGETHER ----------------------------------------------------------------------------------------------------------------------------------
SELECT DISTINCT ORDERNUMBER, STUFF (
	(SELECT ',' + PRODUCTCODE
	FROM sales s1
	WHERE ORDERNUMBER IN (
						SELECT ORDERNUMBER
						FROM	(SELECT ORDERNUMBER, COUNT(*) AS kaunt
								FROM sales
								WHERE STATUS = 'Shipped'
								GROUP BY ORDERNUMBER) t
						WHERE kaunt = 9
					)
					AND s1.ORDERNUMBER = s2.ORDERNUMBER
	FOR XML PATH ('')), 1, 1, '') AS ProductCode
FROM sales s2
ORDER BY ProductCode DESC

/*
SELECT ORDERDATE, STATUS, PRODUCTCODE, PRODUCTLINE, CUSTOMERNAME, TERRITORY
FROM sales
WHERE PRODUCTCODE LIKE '%2325'

SELECT ORDERDATE, STATUS, PRODUCTCODE, PRODUCTLINE, CUSTOMERNAME, TERRITORY
FROM sales
WHERE PRODUCTCODE LIKE '%1937'

SELECT ORDERDATE, STATUS, PRODUCTCODE, PRODUCTLINE, CUSTOMERNAME, TERRITORY
FROM sales
WHERE PRODUCTCODE LIKE '%1342'

SELECT ORDERDATE, STATUS, PRODUCTCODE, PRODUCTLINE, CUSTOMERNAME, TERRITORY
FROM sales
WHERE PRODUCTCODE LIKE '%1367'*/

-----------------------------------------------------------------------------------------------------------------------------------------------------------


-- SALES BY PRODUCT LINE ----------------------------------------------------------------------------------------------------------------------------------
SELECT PRODUCTLINE, COUNT(PRODUCTLINE) AS TOTAL
FROM sales
WHERE STATUS = 'Shipped'
GROUP BY PRODUCTLINE
ORDER BY TOTAL
-----------------------------------------------------------------------------------------------------------------------------------------------------------

-- SALES BY TERRITORY -------------------------------------------------------------------------------------------------------------------------------------
SELECT TERRITORY, COUNT(TERRITORY) AS TOTAL
FROM sales
GROUP BY TERRITORY
ORDER BY TOTAL
-----------------------------------------------------------------------------------------------------------------------------------------------------------
