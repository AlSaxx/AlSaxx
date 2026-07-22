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

SELECT FCT.*
	INTO #PKMTCG_BSKT
	FROM (
			SELECT * FROM FCT_SALES_LINES (NOLOCK)
			UNION ALL
			SELECT * FROM FCT_SALES_LINES_2020_Q2 (NOLOCK)
			UNION ALL
			SELECT * FROM FCT_SALES_LINES_2020_Q1 (NOLOCK)
			UNION ALL
			SELECT * FROM FCT_SALES_LINES_2019_Q3 (NOLOCK)
			UNION ALL
			SELECT * FROM FCT_SALES_LINES_2019_Q2 (NOLOCK)
			UNION ALL
			SELECT * FROM FCT_SALES_LINES_2019_Q1 (NOLOCK)
			UNION ALL
			SELECT * FROM FCT_SALES_LINES_2018_Q4 (NOLOCK)
			UNION ALL
			SELECT * FROM FCT_SALES_LINES_2018_Q3 (NOLOCK)
			UNION ALL
			SELECT * FROM FCT_SALES_LINES_2018_Q2 (NOLOCK)
			UNION ALL
			SELECT * FROM FCT_SALES_LINES_2018_Q1 (NOLOCK)
			UNION ALL
			SELECT * FROM FCT_SALES_LINES_2017_Q4 (NOLOCK)
			UNION ALL
			SELECT * FROM FCT_SALES_LINES_2017_Q3 (NOLOCK)
			UNION ALL
			SELECT * FROM FCT_SALES_LINES_2017_Q2 (NOLOCK)
		) FCT
		INNER JOIN #PKMTCG P ON P.PRODUCT_KEY = FCT.PRODUCT_KEY
		INNER JOIN DIM_DATE D (NOLOCK) ON D.DATE_KEY = FCT.DATE_KEY
	WHERE
		D.DATE_FLD >= '2018-01-01' AND D.DATE_FLD < '2024-01-01'
		AND SALE_INVC_TYPE IN ('REG-INV','DISC-SALE')
GO

-----------------------------------TOPLINE DATE PULLS--------------------------------------------
-------------------------------------------------------------------------------------------------

SELECT	DISTINCT DATEPART(YEAR, D.DATE_FLD) 'Total_cYr',
		SUM(F.SALE_TOT_QTY) 'Total_Units',
		COUNT(DISTINCT F.INVOICE_NO) 'Total_Baskets',
		SUM(F.SALE_NET_VAL+F.SALE_TOT_TAX_VAL) 'Total_GrossVal'
	FROM #PKMTCG_BSKT F
		INNER JOIN DIM_DATE D (NOLOCK) ON D.DATE_KEY = F.DATE_KEY
	GROUP BY
		DATEPART(YEAR, D.DATE_FLD)
	ORDER BY
		DATEPART(YEAR, D.DATE_FLD)
GO

SELECT	DISTINCT DATEPART(YEAR, D.DATE_FLD) 'Store_cYr',
		SUM(F.SALE_TOT_QTY) 'Store_Units',
		COUNT(DISTINCT F.INVOICE_NO) 'Store_Baskets',
		SUM(F.SALE_NET_VAL+F.SALE_TOT_TAX_VAL) 'Store_GrossVal'
	FROM #PKMTCG_BSKT F
		INNER JOIN DIM_DATE D (NOLOCK) ON D.DATE_KEY = F.DATE_KEY
	WHERE
		F.STORE_CODE NOT IN ('UK - 887','UK - 889')
	GROUP BY
		DATEPART(YEAR, D.DATE_FLD)
	ORDER BY
		DATEPART(YEAR, D.DATE_FLD)
GO

SELECT	DISTINCT DATEPART(YEAR, D.DATE_FLD) 'Online_cYr',
		SUM(F.SALE_TOT_QTY) 'Online_Units',
		COUNT(DISTINCT F.INVOICE_NO) 'Online_Baskets',
		SUM(F.SALE_NET_VAL+F.SALE_TOT_TAX_VAL) 'Online_GrossVal'
	FROM #PKMTCG_BSKT F
		INNER JOIN DIM_DATE D (NOLOCK) ON D.DATE_KEY = F.DATE_KEY
	WHERE
		F.STORE_CODE IN ('UK - 887','UK - 889')
	GROUP BY
		DATEPART(YEAR, D.DATE_FLD)
	ORDER BY
		DATEPART(YEAR, D.DATE_FLD)
GO

-----------------------------------BASKET VALUE BANDS--------------------------------------------
-------------------------------------------------------------------------------------------------

SELECT	cYr,
		COALESCE([< £10],0) '< £10',
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
				WHEN grossVal < 10 THEN '< £10'
				WHEN grossVal >= 10 and grossVal < 20 THEN '£10 =< £20'
				WHEN grossVal >= 20 and grossVal < 30 THEN '£20 =< £30'
				WHEN grossVal >= 30 and grossVal < 40 THEN '£30 =< £40'
				WHEN grossVal >= 40 and grossVal < 50 THEN '£40 =< £50'
				WHEN grossVal >= 50 THEN '>= £50'
			END [bVal],
			COUNT(DISTINCT INVOICE_NO) 'Baskets'
		FROM
			(
				SELECT
					DISTINCT DATEPART(YEAR,D.DATE_FLD) 'cYr',
					F.INVOICE_NO,
					SUM(F.SALE_NET_VAL+F.SALE_TOT_TAX_VAL) 'grossVal'
				FROM
					#PKMTCG_BSKT F
					INNER JOIN DIM_DATE D (NOLOCK) ON D.DATE_KEY = F.DATE_KEY
				GROUP BY
					DATEPART(YEAR,D.DATE_FLD),
					F.INVOICE_NO
			) X
		GROUP BY
			cYr,
			CASE 
				WHEN grossVal < 10 THEN '< £10'
				WHEN grossVal >= 10 and grossVal < 20 THEN '£10 =< £20'
				WHEN grossVal >= 20 and grossVal < 30 THEN '£20 =< £30'
				WHEN grossVal >= 30 and grossVal < 40 THEN '£30 =< £40'
				WHEN grossVal >= 40 and grossVal < 50 THEN '£40 =< £50'
				WHEN grossVal >= 50 THEN '>= £50'
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

SELECT	cYr,
		COALESCE([< £10],0) '< £10',
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
				WHEN grossVal < 10 THEN '< £10'
				WHEN grossVal >= 10 and grossVal < 20 THEN '£10 =< £20'
				WHEN grossVal >= 20 and grossVal < 30 THEN '£20 =< £30'
				WHEN grossVal >= 30 and grossVal < 40 THEN '£30 =< £40'
				WHEN grossVal >= 40 and grossVal < 50 THEN '£40 =< £50'
				WHEN grossVal >= 50 THEN '>= £50'
			END [bVal],
			COUNT(DISTINCT INVOICE_NO) 'Baskets'
		FROM
			(
				SELECT
					DISTINCT DATEPART(YEAR,D.DATE_FLD) 'cYr',
					F.INVOICE_NO,
					SUM(F.SALE_NET_VAL+F.SALE_TOT_TAX_VAL) 'grossVal'
				FROM
					#PKMTCG_BSKT F
					INNER JOIN DIM_DATE D (NOLOCK) ON D.DATE_KEY = F.DATE_KEY
				WHERE
					F.STORE_CODE NOT IN ('UK - 887','UK - 889')
				GROUP BY
					DATEPART(YEAR,D.DATE_FLD),
					F.INVOICE_NO
			) X
		GROUP BY
			cYr,
			CASE 
				WHEN grossVal < 10 THEN '< £10'
				WHEN grossVal >= 10 and grossVal < 20 THEN '£10 =< £20'
				WHEN grossVal >= 20 and grossVal < 30 THEN '£20 =< £30'
				WHEN grossVal >= 30 and grossVal < 40 THEN '£30 =< £40'
				WHEN grossVal >= 40 and grossVal < 50 THEN '£40 =< £50'
				WHEN grossVal >= 50 THEN '>= £50'
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

SELECT	cYr,
		COALESCE([< £10],0) '< £10',
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
				WHEN grossVal < 10 THEN '< £10'
				WHEN grossVal >= 10 and grossVal < 20 THEN '£10 =< £20'
				WHEN grossVal >= 20 and grossVal < 30 THEN '£20 =< £30'
				WHEN grossVal >= 30 and grossVal < 40 THEN '£30 =< £40'
				WHEN grossVal >= 40 and grossVal < 50 THEN '£40 =< £50'
				WHEN grossVal >= 50 THEN '>= £50'
			END [bVal],
			COUNT(DISTINCT INVOICE_NO) 'Baskets'
		FROM
			(
				SELECT
					DISTINCT DATEPART(YEAR,D.DATE_FLD) 'cYr',
					F.INVOICE_NO,
					SUM(F.SALE_NET_VAL+F.SALE_TOT_TAX_VAL) 'grossVal'
				FROM
					#PKMTCG_BSKT F
					INNER JOIN DIM_DATE D (NOLOCK) ON D.DATE_KEY = F.DATE_KEY
				WHERE
					F.STORE_CODE IN ('UK - 887','UK - 889')
				GROUP BY
					DATEPART(YEAR,D.DATE_FLD),
					F.INVOICE_NO
			) X
		GROUP BY
			cYr,
			CASE 
				WHEN grossVal < 10 THEN '< £10'
				WHEN grossVal >= 10 and grossVal < 20 THEN '£10 =< £20'
				WHEN grossVal >= 20 and grossVal < 30 THEN '£20 =< £30'
				WHEN grossVal >= 30 and grossVal < 40 THEN '£30 =< £40'
				WHEN grossVal >= 40 and grossVal < 50 THEN '£40 =< £50'
				WHEN grossVal >= 50 THEN '>= £50'
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

-----------------------------------------Units, AUPB, ABV----------------------------------------
-------------------------------------------------------------------------------------------------

SELECT	cMth,
		cMthName,
		COALESCE([2018],0) '2018',
		COALESCE([2019],0) '2019',
		COALESCE([2020],0) '2020',
		COALESCE([2021],0) '2021',
		COALESCE([2022],0) '2022',
		COALESCE([2023],0) '2023'
FROM
	(
		SELECT
			DISTINCT DATEPART(YEAR,D.DATE_FLD) 'cYr',
			DATEPART(MONTH,D.DATE_FLD) 'cMth',
			DATENAME(MONTH,D.DATE_FLD) 'cMthName',
			SUM(F.SALE_TOT_QTY) 'Units'
		FROM
			#PKMTCG_BSKT F
				INNER JOIN DIM_DATE D (NOLOCK) ON D.DATE_KEY = F.DATE_KEY
		GROUP BY
			DATEPART(YEAR,D.DATE_FLD),
			DATEPART(MONTH,D.DATE_FLD),
			DATENAME(MONTH,D.DATE_FLD)
	) X
PIVOT(
		SUM(Units) FOR [cYr] IN (
								[2018],
								[2019],
								[2020],
								[2021],
								[2022],
								[2023]
								)
	) PVT
	ORDER BY
		cMth
GO

SELECT	cMth,
		cMthName,
		COALESCE([2018],0) '2018',
		COALESCE([2019],0) '2019',
		COALESCE([2020],0) '2020',
		COALESCE([2021],0) '2021',
		COALESCE([2022],0) '2022',
		COALESCE([2023],0) '2023'
FROM
	(
		SELECT
			DISTINCT DATEPART(YEAR,D.DATE_FLD) 'cYr',
			DATEPART(MONTH,D.DATE_FLD) 'cMth',
			DATENAME(MONTH,D.DATE_FLD) 'cMthName',
			CONVERT(decimal,SUM(F.SALE_TOT_QTY)) / COUNT(DISTINCT F.INVOICE_NO) 'AUPB'
		FROM
			#PKMTCG_BSKT F
				INNER JOIN DIM_DATE D (NOLOCK) ON D.DATE_KEY = F.DATE_KEY
		GROUP BY
			DATEPART(YEAR,D.DATE_FLD),
			DATEPART(MONTH,D.DATE_FLD),
			DATENAME(MONTH,D.DATE_FLD)
	) X
PIVOT(
		SUM(AUPB) FOR [cYr] IN (
								[2018],
								[2019],
								[2020],
								[2021],
								[2022],
								[2023]
								)
	) PVT
	ORDER BY
		cMth
GO

SELECT	cMth,
		cMthName,
		COALESCE([2018],0) '2018',
		COALESCE([2019],0) '2019',
		COALESCE([2020],0) '2020',
		COALESCE([2021],0) '2021',
		COALESCE([2022],0) '2022',
		COALESCE([2023],0) '2023'
FROM
	(
		SELECT
			DISTINCT DATEPART(YEAR,D.DATE_FLD) 'cYr',
			DATEPART(MONTH,D.DATE_FLD) 'cMth',
			DATENAME(MONTH,D.DATE_FLD) 'cMthName',
			SUM(F.SALE_NET_VAL+F.SALE_TOT_TAX_VAL)/COUNT(DISTINCT F.INVOICE_NO) 'ABV'
		FROM
			#PKMTCG_BSKT F
				INNER JOIN DIM_DATE D (NOLOCK) ON D.DATE_KEY = F.DATE_KEY
		GROUP BY
			DATEPART(YEAR,D.DATE_FLD),
			DATEPART(MONTH,D.DATE_FLD),
			DATENAME(MONTH,D.DATE_FLD)
	) X
PIVOT(
		SUM(ABV) FOR [cYr] IN (
								[2018],
								[2019],
								[2020],
								[2021],
								[2022],
								[2023]
								)
	) PVT
	ORDER BY
		cMth
GO

---------------------------------TOP PRODUCTS BY YEAR VAL & VOL----------------------------------
-------------------------------------------------------------------------------------------------

SELECT
	DISTINCT cYr,
	SOURCE_PRODUCT_CODE,
	PRODUCT_DESCRIPTION,
	pIDx 'Val_pIDx'
FROM
	(
		SELECT
			DISTINCT P.SOURCE_PRODUCT_CODE,
			P.PRODUCT_DESCRIPTION,
			DATEPART(YEAR,D.DATE_FLD) 'cYr',
			SUM(F.SALE_NET_VAL+F.SALE_TOT_TAX_VAL) 'GrossVal',
			ROW_NUMBER() OVER(PARTITION BY DATEPART(YEAR, D.DATE_FLD) ORDER BY SUM(F.SALE_NET_VAL+F.SALE_TOT_TAX_VAL) DESC) 'pIdx'
		FROM #PKMTCG_BSKT F
			INNER JOIN DIM_DATE D (NOLOCK) ON D.DATE_KEY = F.DATE_KEY
			INNER JOIN #PKMTCG p ON P.PRODUCT_KEY = F.PRODUCT_KEY
		GROUP BY
			P.SOURCE_PRODUCT_CODE,
			P.PRODUCT_DESCRIPTION,
			DATEPART(YEAR,D.DATE_FLD)
	) X
WHERE
	pIDX <= 3
ORDER BY
	cYr,
	pIDX
GO

SELECT
	DISTINCT cYr,
	SOURCE_PRODUCT_CODE,
	PRODUCT_DESCRIPTION,
	pIDx 'Vol_pIDx'
FROM
	(
		SELECT
			DISTINCT P.SOURCE_PRODUCT_CODE,
			P.PRODUCT_DESCRIPTION,
			DATEPART(YEAR,D.DATE_FLD) 'cYr',
			SUM(F.SALE_TOT_QTY) 'Units',
			ROW_NUMBER() OVER(PARTITION BY DATEPART(YEAR, D.DATE_FLD) ORDER BY SUM(F.SALE_TOT_QTY) DESC) 'pIdx'
		FROM #PKMTCG_BSKT F
			INNER JOIN DIM_DATE D (NOLOCK) ON D.DATE_KEY = F.DATE_KEY
			INNER JOIN #PKMTCG P ON P.PRODUCT_KEY = F.PRODUCT_KEY
		GROUP BY
			P.SOURCE_PRODUCT_CODE,
			P.PRODUCT_DESCRIPTION,
			DATEPART(YEAR,D.DATE_FLD)
	) X
WHERE
	pIDX <= 3
ORDER BY
	cYr,
	pIDX
GO