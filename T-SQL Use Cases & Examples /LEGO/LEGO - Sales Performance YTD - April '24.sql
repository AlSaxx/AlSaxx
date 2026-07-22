USE GAME_ARC
GO

------------------------------------------PRODUCT TABLE------------------------------------------
-------------------------------------------------------------------------------------------------

IF OBJECT_ID ('tempdb..#LEGO') IS NOT NULL
	DROP TABLE #LEGO

SELECT *
	INTO #LEGO
	FROM DIM_PRODUCT P (NOLOCK)
	WHERE P.MANUFACTURE_CODE = 500687
		AND P.PROD_TYPE_CODE = '425'
		AND P.SUBCLASS_CODE = 'TBB'
		--AND P.LATEST = 1
		AND P.MERCHANDISE_FLG = 'YES'
GO

--SELECT * FROM #LEGO

----------------------------------------FACT TABLE: YTD------------------------------------------
-------------------------------------------------------------------------------------------------

IF OBJECT_ID ('tempdb..#BSKT') IS NOT NULL
		DROP TABLE #BSKT

SELECT F.*
	INTO #BSKT
	FROM FCT_SALES_LINES F (NOLOCK)
		INNER JOIN #LEGO P ON P.PRODUCT_KEY = F.PRODUCT_KEY
		INNER JOIN DIM_DATE D (NOLOCK) ON D.DATE_KEY = F.DATE_KEY
	WHERE
		--D.DATE_FLD >= '2022-01-01' AND D.DATE_FLD < '2022-04-01'
		--D.DATE_FLD >= '2023-01-01' AND D.DATE_FLD < '2023-04-01'
		D.DATE_FLD >= '2024-01-01' AND D.DATE_FLD < '2024-04-01'
		AND F.SALE_INVC_TYPE IN ('REG-INV','DISC-SALE')
GO

-------------------------------------------Baskets-----------------------------------------------
-------------------------------------------------------------------------------------------------

SELECT	[Year] 'Year',
		COALESCE(Store,0)+COALESCE([Online],0) 'LEGO_YTD',
		COALESCE(Store,0) 'Store_YTD',
		COALESCE([Online],0) 'Online_YTD'
FROM
(
SELECT	DATEPART(YEAR, D.DATE_FLD) 'Year',
		CASE
			WHEN F.STORE_CODE IN ('UK - 887','UK - 889') THEN 'Online'
			WHEN F.STORE_CODE NOT IN ('UK - 887','UK - 889') THEN 'Store'
		END 'Channel',
		COUNT(DISTINCT F.INVOICE_NO) 'Baskets'
	FROM #BSKT F
		INNER JOIN DIM_DATE D (NOLOCK) ON D.DATE_KEY = F.DATE_KEY
	GROUP BY
		DATEPART(YEAR, D.DATE_FLD),
		CASE
			WHEN F.STORE_CODE IN ('UK - 887','UK - 889') THEN 'Online'
			WHEN F.STORE_CODE NOT IN ('UK - 887','UK - 889') THEN 'Store'
		END
) x
PIVOT
	( SUM(Baskets) FOR Channel IN	(
									[Store],
									[Online]
									)
) PVT
	ORDER BY
		[Year]
GO

-----------------------------------Unit Sales----------------------------------------------------
-------------------------------------------------------------------------------------------------

SELECT	[Year] 'Year',
		COALESCE(Store,0)+COALESCE([Online],0) 'LEGO_YTD',
		COALESCE(Store,0) 'Store_YTD',
		COALESCE([Online],0) 'Online_YTD'
FROM
(
SELECT	DATEPART(YEAR, D.DATE_FLD) 'Year',
		CASE
			WHEN F.STORE_CODE IN ('UK - 887','UK - 889') THEN 'Online'
			WHEN F.STORE_CODE NOT IN ('UK - 887','UK - 889') THEN 'Store'
		END 'Channel',
		SUM(F.SALE_TOT_QTY) 'Unit_Sales'
	FROM #BSKT F
		INNER JOIN DIM_DATE D (NOLOCK) ON D.DATE_KEY = F.DATE_KEY
	GROUP BY
		DATEPART(YEAR, D.DATE_FLD),
		CASE
			WHEN F.STORE_CODE IN ('UK - 887','UK - 889') THEN 'Online'
			WHEN F.STORE_CODE NOT IN ('UK - 887','UK - 889') THEN 'Store'
		END
) x
PIVOT
	( SUM(Unit_Sales) FOR Channel IN	(
										[Store],
										[Online]
										)
) PVT
	ORDER BY
		[Year]
GO

-----------------------------------------------Value Sales---------------------------------------
-------------------------------------------------------------------------------------------------

SELECT	[Year] 'Year',
		COALESCE(Store,0)+COALESCE([Online],0) 'LEGO_YTD',
		COALESCE(Store,0) 'Store_YTD',
		COALESCE([Online],0) 'Online_YTD'
FROM
(
SELECT	DATEPART(YEAR, D.DATE_FLD) 'Year',
		CASE
			WHEN F.STORE_CODE IN ('UK - 887','UK - 889') THEN 'Online'
			WHEN F.STORE_CODE NOT IN ('UK - 887','UK - 889') THEN 'Store'
		END 'Channel',
		SUM(F.SALE_NET_VAL+F.SALE_TOT_TAX_VAL) 'Value_Sales'
	FROM #BSKT F
		INNER JOIN DIM_DATE D (NOLOCK) ON D.DATE_KEY = F.DATE_KEY
	GROUP BY
		DATEPART(YEAR, D.DATE_FLD),
		CASE
			WHEN F.STORE_CODE IN ('UK - 887','UK - 889') THEN 'Online'
			WHEN F.STORE_CODE NOT IN ('UK - 887','UK - 889') THEN 'Store'
		END
) x
PIVOT
	( SUM(Value_Sales) FOR Channel IN	(
										[Store],
										[Online]
										)
) PVT
	ORDER BY
		[Year]
GO

---------------------------------------------TOP PRODUCTS----------------------------------------
-------------------------------------------------------------------------------------------------

SELECT	DISTINCT [Year] 'Q1',
		SOURCE_PRODUCT_CODE,
		PRODUCT_DESCRIPTION,
		COALESCE(Unit_Sales,0) 'Volume',
		pIDx 'Vol_pIDx'
FROM
	(
	SELECT	DISTINCT P.SOURCE_PRODUCT_CODE,
			P.PRODUCT_DESCRIPTION,
			DATEPART(YEAR, D.DATE_FLD) 'Year',
			SUM(F.SALE_TOT_QTY) 'Unit_Sales',
			ROW_NUMBER() OVER(PARTITION BY DATEPART(YEAR, D.DATE_FLD) ORDER BY SUM(F.SALE_TOT_QTY) DESC) 'pIdx'
		FROM #BSKT F
			INNER JOIN DIM_DATE D (NOLOCK) ON D.DATE_KEY = F.DATE_KEY
			INNER JOIN #LEGO P ON P.PRODUCT_KEY = F.PRODUCT_KEY
		GROUP BY
			P.SOURCE_PRODUCT_CODE,
			P.PRODUCT_DESCRIPTION,
			DATEPART(YEAR,D.DATE_FLD)
	) x
WHERE
	pIDX <= 5
ORDER BY
	[Year],
	pIDX
GO

SELECT	DISTINCT [Year] 'Q1',
		SOURCE_PRODUCT_CODE,
		PRODUCT_DESCRIPTION,
		COALESCE(Val_Sales,0) 'Value_Sales',
		pIDx 'Val_pIDx'
FROM
	(
	SELECT	DISTINCT P.SOURCE_PRODUCT_CODE,
			P.PRODUCT_DESCRIPTION,
			DATEPART(YEAR, D.DATE_FLD) 'Year',
			SUM(F.SALE_NET_VAL+F.SALE_TOT_TAX_VAL) 'Val_Sales',
			ROW_NUMBER() OVER(PARTITION BY DATEPART(YEAR, D.DATE_FLD) ORDER BY SUM(F.SALE_NET_VAL+F.SALE_TOT_TAX_VAL) DESC) 'pIdx'
		FROM #BSKT F
			INNER JOIN DIM_DATE D (NOLOCK) ON D.DATE_KEY = F.DATE_KEY
			INNER JOIN #LEGO P ON P.PRODUCT_KEY = F.PRODUCT_KEY
		GROUP BY
			P.SOURCE_PRODUCT_CODE,
			P.PRODUCT_DESCRIPTION,
			DATEPART(YEAR,D.DATE_FLD)
	) x
WHERE
	pIDX <= 5
ORDER BY
	[Year],
	pIDX
GO

-------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------