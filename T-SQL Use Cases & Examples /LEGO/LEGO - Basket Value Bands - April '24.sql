USE GAME_ARC
GO

--------------------------------------------PRODUCT TABLE----------------------------------------
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

---------------------------------------------FACT TABLE------------------------------------------
-------------------------------------------------------------------------------------------------

IF OBJECT_ID ('tempdb..#BSKT') IS NOT NULL
	DROP TABLE #BSKT

SELECT FCT.*
	INTO #BSKT
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
		INNER JOIN #LEGO P ON P.PRODUCT_KEY = FCT.PRODUCT_KEY
		INNER JOIN DIM_DATE D (NOLOCK) ON D.DATE_KEY = FCT.DATE_KEY
	WHERE
		D.DATE_FLD >= '2018-01-01' AND D.DATE_FLD < '2024-04-01'
		AND SALE_INVC_TYPE IN ('REG-INV','DISC-SALE')
GO

-------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------

SELECT	[Year],
		COALESCE([< £10],0) '< £10',
		COALESCE([£10 =< £20],0) '£10 =< £20',
		COALESCE([£20 =< £30],0) '£20 =< £30',
		COALESCE([£30 =< £40],0) '£30 =< £40',
		COALESCE([£40 =< £50],0) '£40 =< £50',
		COALESCE([> £50],0) '> £50'
FROM
(
	SELECT	[Year],
			CASE
				WHEN Gross_Value < 10 THEN '< £10'
				WHEN Gross_Value >= 10 AND Gross_Value < 20 THEN '£10 =< £20'
				WHEN Gross_Value >= 20 AND Gross_Value < 30 THEN '£20 =< £30'
				WHEN Gross_Value >= 30 AND Gross_Value < 40 THEN '£30 =< £40'
				WHEN Gross_Value >= 40 AND Gross_Value < 50 THEN '£40 =< £50'
				WHEN Gross_Value > 50 THEN '> £50'
			END 'BSKT_Val',
			COUNT(DISTINCT INVOICE_NO) 'Baskets'
		FROM
			(
				SELECT	DATEPART(YEAR,D.DATE_FLD) 'Year',
						F.INVOICE_NO,
						SUM(F.SALE_NET_VAL+F.SALE_TOT_TAX_VAL) 'Gross_Value'
					FROM #BSKT F (NOLOCK)
						INNER JOIN #LEGO P ON P.PRODUCT_KEY = F.PRODUCT_KEY
						INNER JOIN DIM_DATE D (NOLOCK) ON D.DATE_KEY = F.DATE_KEY
					GROUP BY
						DATEPART(YEAR, D.DATE_FLD),
						F.INVOICE_NO
			) a
			GROUP BY
				[Year],
				CASE
					WHEN Gross_Value < 10 THEN '< £10'
					WHEN Gross_Value >= 10 AND Gross_Value < 20 THEN '£10 =< £20'
					WHEN Gross_Value >= 20 AND Gross_Value < 30 THEN '£20 =< £30'
					WHEN Gross_Value >= 30 AND Gross_Value < 40 THEN '£30 =< £40'
					WHEN Gross_Value >= 40 AND Gross_Value < 50 THEN '£40 =< £50'
					WHEN Gross_Value > 50 THEN '> £50'
				END
	) b
PIVOT
	( SUM(Baskets) FOR [BSKT_Val] IN	(
										[< £10],
										[£10 =< £20],
										[£20 =< £30],
										[£30 =< £40],
										[£40 =< £50],
										[> £50]
										)

	) PVT
	ORDER BY
		[YEAR]
GO