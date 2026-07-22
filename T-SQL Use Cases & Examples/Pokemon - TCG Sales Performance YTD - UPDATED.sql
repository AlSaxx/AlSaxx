USE GAME_ARC
GO

------------------------------------------PRODUCT TABLE------------------------------------------
-------------------------------------------------------------------------------------------------

IF OBJECT_ID ('tempdb..#PKMTCG') IS NOT NULL
	DROP TABLE #PKMTCG

SELECT *
	INTO #PKMTCG
	FROM DIM_PRODUCT P (NOLOCK)
	WHERE
		P.DEPARTMENT_CODE = 'M'
		AND P.CLASS_CODE = 'TC'
		AND P.SUBCLASS_CODE = 'OTC'
		AND P.ATTRIB1_CODE = '210'
		AND P.MERCHANDISE_FLG = 'YES'
		AND P.MANUFACTURE_CODE = 400099
		AND (P.PRODUCT_DESCRIPTION LIKE '%Pokemon%'
			OR P.PRODUCT_DESCRIPTION LIKE '%Pokémon%'
			OR P.PRODUCT_DESCRIPTION LIKE '%PKM%')	
		AND P.PRODUCT_DESCRIPTION NOT LIKE '%plush%'
		AND P.PRODUCT_DESCRIPTION NOT LIKE '%plsh%'
		AND P.PRODUCT_DESCRIPTION NOT LIKE '%fig set%'
		AND P.PRODUCT_DESCRIPTION NOT LIKE '%bt fig%'
		AND P.PRODUCT_DESCRIPTION NOT LIKE '%eb fig%'
		AND P.PRODUCT_DESCRIPTION NOT LIKE '%ft fg%'
		AND P.PRODUCT_DESCRIPTION NOT LIKE '%fig ast%'
		AND P.PRODUCT_DESCRIPTION NOT LIKE 'DNU%'
		AND P.SOURCE_PRODUCT_CODE NOT IN ('814106','814137','814139','814155','814157','816402','814149')
GO

--SELECT * FROM #PKMTCG

-------------------------------------------BASKET TABLE------------------------------------------
-------------------------------------------------------------------------------------------------

IF OBJECT_ID ('tempdb..#PKMTCG_BSKT') IS NOT NULL
	DROP TABLE #PKMTCG_BSKT

SELECT F.*
	INTO #PKMTCG_BSKT
	FROM FCT_SALES_LINES F (NOLOCK)
		INNER JOIN #PKMTCG P ON P.PRODUCT_KEY = F.PRODUCT_KEY
		INNER JOIN DIM_DATE D (NOLOCK) ON D.DATE_KEY = F.DATE_KEY
	WHERE D.DATE_FLD >= '2021-01-01' AND D.DATE_FLD < '2024-01-01'
		AND F.SALE_INVC_TYPE IN ('REG-INV','DISC-SALE')	
GO

-------------------------------------TOPLINE YTD PULLS-------------------------------------------
-------------------------------------------------------------------------------------------------

SELECT
	DISTINCT DATEPART(YEAR,D.DATE_FLD) 'cYr',
	SUM(F.SALE_TOT_QTY) 'Units',
	COUNT(DISTINCT F.INVOICE_NO) 'Baskets',
	SUM(F.SALE_NET_VAL+F.SALE_TOT_TAX_VAL) 'GrossVal'
FROM
	#PKMTCG_BSKT F
		INNER JOIN DIM_DATE D (NOLOCK) ON D.DATE_KEY = F.DATE_KEY
WHERE
	D.DATE_FLD >= '2021-01-01' AND D.DATE_FLD < '2021-12-31'							--- CHANGE TO 2021 YTD LAST DAY DEPENDING ON HALF.
	OR (D.DATE_FLD >= '2022-01-01' AND D.DATE_FLD < '2022-12-31')						--- CHANGE TO 2022 YTD LAST DAY DEPENDING ON HALF.
	OR (D.DATE_FLD >= '2023-01-01' AND D.DATE_FLD < '2023-12-31')						--- CHANGE TO 2023 YTD LAST DAY DEPENDING ON HALF.
GROUP BY
	DATEPART(YEAR,D.DATE_FLD)
ORDER BY
	DATEPART(YEAR,D.DATE_FLD)
GO

SELECT
	DISTINCT DATEPART(YEAR,D.DATE_FLD) 'Store_cYr',
	SUM(F.SALE_TOT_QTY) 'Store_Units',
	COUNT(DISTINCT F.INVOICE_NO) 'Store_Baskets',
	SUM(F.SALE_NET_VAL+F.SALE_TOT_TAX_VAL) 'Store_GrossVal'
FROM
	#PKMTCG_BSKT F
		INNER JOIN DIM_DATE D (NOLOCK) ON D.DATE_KEY = F.DATE_KEY
WHERE
	(F.STORE_CODE NOT IN ('UK - 887','UK - 889')
		AND D.DATE_FLD >= '2021-01-01' AND D.DATE_FLD < '2021-12-31')						--- CHANGE TO 2021 YTD LAST DAY DEPENDING ON HALF.
	OR (F.STORE_CODE NOT IN ('UK - 887','UK - 889')
		AND D.DATE_FLD >= '2022-01-01' AND D.DATE_FLD < '2022-12-31')						--- CHANGE TO 2022 YTD LAST DAY DEPENDING ON HALF.
	OR (F.STORE_CODE NOT IN ('UK - 887','UK - 889')
		AND D.DATE_FLD >= '2023-01-01' AND D.DATE_FLD < '2023-12-31')						--- CHANGE TO 2023 YTD LAST DAY DEPENDING ON HALF.
GROUP BY
	DATEPART(YEAR,D.DATE_FLD)
ORDER BY
	DATEPART(YEAR,D.DATE_FLD)
GO

SELECT
	DISTINCT DATEPART(YEAR,D.DATE_FLD) 'Online_cYr',
	SUM(F.SALE_TOT_QTY) 'Online_Units',
	COUNT(DISTINCT F.INVOICE_NO) 'Online_Baskets',
	SUM(F.SALE_NET_VAL+F.SALE_TOT_TAX_VAL) 'Online_GrossVal'
FROM
	#PKMTCG_BSKT F
		INNER JOIN DIM_DATE D (NOLOCK) ON D.DATE_KEY = F.DATE_KEY
WHERE
	(F.STORE_CODE IN ('UK - 887','UK - 889')
		AND D.DATE_FLD >= '2021-01-01' AND D.DATE_FLD < '2021-12-31')						--- CHANGE TO 2021 YTD LAST DAY DEPENDING ON HALF.
	OR (F.STORE_CODE IN ('UK - 887','UK - 889')
		AND D.DATE_FLD >= '2022-01-01' AND D.DATE_FLD < '2022-12-31')						--- CHANGE TO 2022 YTD LAST DAY DEPENDING ON HALF.
	OR (F.STORE_CODE IN ('UK - 887','UK - 889')
		AND D.DATE_FLD >= '2023-01-01' AND D.DATE_FLD < '2023-12-31')						--- CHANGE TO 2023 YTD LAST DAY DEPENDING ON HALF.
GROUP BY
	DATEPART(YEAR,D.DATE_FLD)
ORDER BY
	DATEPART(YEAR,D.DATE_FLD)
GO

-----------------------------------BASKET VALUE BANDS--------------------------------------------
-------------------------------------------------------------------------------------------------

SELECT	cYr,
		[< £10],
		COALESCE([£10 =< £20],0) '£10 =< £20',
		COALESCE([£20 =< £30],0) '£20 =< £30',
		COALESCE([£30 =< £40],0) '£30 =< £40',
		COALESCE([£40 =< £50],0) '£40 =< £50',
		COALESCE([>= £50],0) '>= £50'
FROM
	(
		SELECT
			DISTINCT cYr,
			CASE 
				WHEN GrossVal < 10 then '< £10'
				WHEN GrossVal >= 10 AND GrossVal < 20 THEN '£10 =< £20'
				WHEN GrossVal >= 20 AND GrossVal < 30 THEN '£20 =< £30'
				WHEN GrossVal >= 30 AND GrossVal < 40 THEN '£30 =< £40'
				WHEN GrossVal >= 40 AND GrossVal < 50 THEN '£40 =< £50'
				WHEN GrossVal >= 50 THEN '>= £50'
			END [bVal],
			COUNT(DISTINCT INVOICE_NO) 'Baskets'
		FROM
			(
				SELECT
					DISTINCT DATEPART(YEAR,D.DATE_FLD) 'cYr',
					F.INVOICE_NO,
					SUM(F.SALE_NET_VAL+F.SALE_TOT_TAX_VAL) 'GrossVal'
				FROM
					#PKMTCG_BSKT F
						INNER JOIN DIM_DATE D (NOLOCK) ON D.DATE_KEY = F.DATE_KEY
				WHERE
					(D.DATE_FLD >= '2021-01-01' AND D.DATE_FLD < '2021-12-31')				--- CHANGE TO 2020 YTD LAST DAY DEPENDING ON HALF.
					OR (D.DATE_FLD >= '2022-01-01' AND D.DATE_FLD < '2022-12-31')			--- CHANGE TO 2021 YTD LAST DAY DEPENDING ON HALF.
					OR (D.DATE_FLD >= '2023-01-01' AND D.DATE_FLD < '2023-12-31')			--- CHANGE TO 2022 YTD LAST DAY DEPENDING ON HALF.
				GROUP BY
					DATEPART(YEAR,D.DATE_FLD),
					F.INVOICE_NO
			) X
		GROUP BY
			cYr,
			CASE 
				WHEN GrossVal < 10 THEN '< £10'
				WHEN GrossVal >= 10 AND GrossVal < 20 THEN '£10 =< £20'
				WHEN GrossVal >= 20 AND GrossVal < 30 THEN '£20 =< £30'
				WHEN GrossVal >= 30 AND GrossVal < 40 THEN '£30 =< £40'
				WHEN GrossVal >= 40 AND GrossVal < 50 THEN '£40 =< £50'
				WHEN GrossVal >= 50 THEN '>= £50'
			END
	) Y
PIVOT(
		SUM(Baskets) FOR [bVal] IN (
									[< £10],
									[£10 =< £20],
									[£20 =< £30],
									[£30 =< £40],
									[£40 =< £50],
									[>= £50]
									)
	) PVT
	ORDER BY
		cYr
GO

SELECT	cYr 'Stores_cYr',
		[< £10],
		COALESCE([£10 =< £20],0) '£10 =< £20',
		COALESCE([£20 =< £30],0) '£20 =< £30',
		COALESCE([£30 =< £40],0) '£30 =< £40',
		COALESCE([£40 =< £50],0) '£40 =< £50',
		COALESCE([>= £50],0) '>= £50'
FROM
	(
		SELECT
			DISTINCT cYr,
			CASE 
				WHEN GrossVal < 10 then '< £10'
				WHEN GrossVal >= 10 AND GrossVal < 20 THEN '£10 =< £20'
				WHEN GrossVal >= 20 AND GrossVal < 30 THEN '£20 =< £30'
				WHEN GrossVal >= 30 AND GrossVal < 40 THEN '£30 =< £40'
				WHEN GrossVal >= 40 AND GrossVal < 50 THEN '£40 =< £50'
				WHEN GrossVal >= 50 THEN '>= £50'
			END [bVal],
			COUNT(DISTINCT INVOICE_NO) 'Baskets'
		FROM
			(
				SELECT
					DISTINCT DATEPART(YEAR,D.DATE_FLD) 'cYr',
					F.INVOICE_NO,
					SUM(F.SALE_NET_VAL+F.SALE_TOT_TAX_VAL) 'GrossVal'
				FROM
					#PKMTCG_BSKT F
						INNER JOIN DIM_DATE D (NOLOCK) ON D.DATE_KEY = F.DATE_KEY
				WHERE
					(F.STORE_CODE NOT IN ('UK - 887','UK - 889')
						AND D.DATE_FLD >= '2021-01-01' AND D.DATE_FLD < '2021-12-31')			--- CHANGE TO 2021 YTD LAST DAY DEPENDING ON HALF.
					OR (F.STORE_CODE NOT IN ('UK - 887','UK - 889')
						AND D.DATE_FLD >= '2022-01-01' AND D.DATE_FLD < '2022-12-31')			--- CHANGE TO 2022 YTD LAST DAY DEPENDING ON HALF.
					OR (F.STORE_CODE NOT IN ('UK - 887','UK - 889')
						AND D.DATE_FLD >= '2023-01-01' AND D.DATE_FLD < '2023-12-31')			--- CHANGE TO 2023 YTD LAST DAY DEPENDING ON HALF.
				GROUP BY
					DATEPART(YEAR,D.DATE_FLD),
					F.INVOICE_NO
			) X
		GROUP BY
			cYr,
			CASE 
				WHEN GrossVal < 10 THEN '< £10'
				WHEN GrossVal >= 10 AND GrossVal < 20 THEN '£10 =< £20'
				WHEN GrossVal >= 20 AND GrossVal < 30 THEN '£20 =< £30'
				WHEN GrossVal >= 30 AND GrossVal < 40 THEN '£30 =< £40'
				WHEN GrossVal >= 40 AND GrossVal < 50 THEN '£40 =< £50'
				WHEN GrossVal >= 50 THEN '>= £50'
			END
	) Y
PIVOT(
		SUM(Baskets) FOR [bVal] IN (
									[< £10],
									[£10 =< £20],
									[£20 =< £30],
									[£30 =< £40],
									[£40 =< £50],
									[>= £50]
									)
	) PVT
	ORDER BY
		cYr
GO

SELECT	cYr 'Online_cYr',
		[< £10],
		COALESCE([£10 =< £20],0) '£10 =< £20',
		COALESCE([£20 =< £30],0) '£20 =< £30',
		COALESCE([£30 =< £40],0) '£30 =< £40',
		COALESCE([£40 =< £50],0) '£40 =< £50',
		COALESCE([>= £50],0) '>= £50'
FROM
	(
		SELECT
			DISTINCT cYr,
			CASE 
				WHEN GrossVal < 10 then '< £10'
				WHEN GrossVal >= 10 AND GrossVal < 20 THEN '£10 =< £20'
				WHEN GrossVal >= 20 AND GrossVal < 30 THEN '£20 =< £30'
				WHEN GrossVal >= 30 AND GrossVal < 40 THEN '£30 =< £40'
				WHEN GrossVal >= 40 AND GrossVal < 50 THEN '£40 =< £50'
				WHEN GrossVal >= 50 THEN '>= £50'
			END [bVal],
			COUNT(DISTINCT INVOICE_NO) 'Baskets'
		FROM
			(
				SELECT
					DISTINCT DATEPART(YEAR,D.DATE_FLD) 'cYr',
					F.INVOICE_NO,
					SUM(F.SALE_NET_VAL+F.SALE_TOT_TAX_VAL) 'GrossVal'
				FROM
					#PKMTCG_BSKT F
						INNER JOIN DIM_DATE D (NOLOCK) ON D.DATE_KEY = F.DATE_KEY
				WHERE
					(F.STORE_CODE IN ('UK - 887','UK - 889')
						AND D.DATE_FLD >= '2021-01-01' AND D.DATE_FLD < '2021-12-31')			--- CHANGE TO 2021 YTD LAST DAY DEPENDING ON HALF.
					OR (F.STORE_CODE IN ('UK - 887','UK - 889')
						AND D.DATE_FLD >= '2022-01-01' AND D.DATE_FLD < '2022-12-31')			--- CHANGE TO 2022 YTD LAST DAY DEPENDING ON HALF.
					OR (F.STORE_CODE IN ('UK - 887','UK - 889')
						AND D.DATE_FLD >= '2023-01-01' AND D.DATE_FLD < '2023-12-31')			--- CHANGE TO 2023 YTD LAST DAY DEPENDING ON HALF.
				GROUP BY
					DATEPART(YEAR,D.DATE_FLD),
					F.INVOICE_NO
			) X
		GROUP BY
			cYr,
			CASE 
				WHEN GrossVal < 10 THEN '< £10'
				WHEN GrossVal >= 10 AND GrossVal < 20 THEN '£10 =< £20'
				WHEN GrossVal >= 20 AND GrossVal < 30 THEN '£20 =< £30'
				WHEN GrossVal >= 30 AND GrossVal < 40 THEN '£30 =< £40'
				WHEN GrossVal >= 40 AND GrossVal < 50 THEN '£40 =< £50'
				WHEN GrossVal >= 50 THEN '>= £50'
			END
	) Y
PIVOT(
		SUM(Baskets) FOR [bVal] IN (
									[< £10],
									[£10 =< £20],
									[£20 =< £30],
									[£30 =< £40],
									[£40 =< £50],
									[>= £50]
									)
	) PVT
	ORDER BY
		cYr
GO