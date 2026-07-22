USE insight
GO

------------------------------------------PRODUCT TABLE------------------------------------------
-------------------------------------------------------------------------------------------------

IF OBJECT_ID ('tempdb..#LEGO') IS NOT NULL
	DROP TABLE #LEGO

SELECT *
	INTO #LEGO
	FROM sku S (NOLOCK)
		inner join UK_SQL_ARC_01.GAME_ARC.dbo.DIM_PRODUCT P ON P.SOURCE_PRODUCT_CODE = s.sku
	WHERE
		P.MANUFACTURE_CODE = 500687
		AND P.PROD_TYPE_CODE = '425'
		AND P.SUBCLASS_CODE = 'TBB'
		AND P.MERCHANDISE_FLG = 'YES'
GO

-----------------------------------------CUSTOMER TABLE------------------------------------------
-------------------------------------------------------------------------------------------------

IF OBJECT_ID ('tempdb..#NEWCUST') IS NOT NULL
	DROP TABLE #NEWCUST

SELECT	DISTINCT EMC.mergedcustomerid,
		MIN(tc.transactionDate) 'minTRGTrans'
	INTO #NEWCUST
	FROM expanededmergedcustomerids EMC (NOLOCK)
		INNER JOIN Transactions TC (NOLOCK) ON EMC.insightCustomerId = TC.InsightCustomerId
		INNER JOIN TransactionItem TI (NOLOCK) ON TC.Id = TI.transactionId
		INNER JOIN #LEGO S (NOLOCK) ON S.sku = TI.sku
	WHERE
		TI.transactionTypeId = 1
		AND TC.storeNumber <> 9999
		AND emc.mergedCustomerId NOT IN (SELECT DISTINCT mergedCustomerId FROM insighttemp..GK_CUSTOMER_BLACKLIST)
		AND emc.mergedCustomerId NOT IN (SELECT DISTINCT mergedcustomerid FROM insighttemp..GK_B2B_suppression)
	GROUP BY
		emc.mergedcustomerid
GO

-----------------------------MONTHLY TRENDED NEW CUST (> 2023)--------------------------------------
-------------------------------------------------------------------------------------------------

SELECT
	A.cYr,
	A.cMthName,
	A.[Total_LEGO_Cust],
	B.[New_LEGO_Cust]
FROM
	(
		SELECT
			DISTINCT DATEPART(MONTH,TC.transactionDate) 'cMth',
			DATEPART(YEAR,TC.transactionDate) 'cYr',
			DATENAME(MONTH,TC.transactionDate) 'cMthName',
			COUNT(DISTINCT EMC.mergedCustomerId) 'Total_LEGO_Cust'
		FROM ExpanededMergedCustomerIds EMC (nolock)
			INNER JOIN Transactions TC (NOLOCK) ON EMC.insightCustomerId = TC.InsightCustomerId
			INNER JOIN TransactionItem TI (NOLOCK) ON TC.Id = TI.transactionId
			INNER JOIN #LEGO S (NOLOCK) ON S.sku = TI.sku
		WHERE
			ti.transactiontypeid = 1
				AND TC.storeNumber <> 9999
				AND TC.transactionDate >= '2023-01-01' AND TC.transactionDate < '2024-04-01'
				AND EMC.mergedCustomerId NOT IN (SELECT DISTINCT mergedCustomerId FROM insighttemp..GK_CUSTOMER_BLACKLIST)
				AND EMC.mergedCustomerId NOT IN (SELECT DISTINCT mergedcustomerid FROM insighttemp..GK_B2B_suppression)
		GROUP BY
			DATEPART(YEAR,TC.transactionDate),
			DATEPART(MONTH,TC.transactionDate),
			DATENAME(MONTH,TC.transactionDate)
	) A
LEFT OUTER JOIN
	(
		SELECT
			DISTINCT DATEPART(MONTH,minTRGTrans) 'cMth',
			DATEPART(YEAR,minTRGTrans) 'cYr',
			COUNT(DISTINCT mergedCustomerId) 'New_LEGO_Cust'
		FROM #NEWCUST
		WHERE
			DATEPART(YEAR,minTRGTrans) >= 2023 --AND DATEPART(YEAR,minTRGTrans) < 2024
		GROUP BY
			DATEPART(YEAR,minTRGTrans),
			DATEPART(MONTH,minTRGTrans)
	)B ON A.cYr = B.cYr AND A.cMth = B.cMth
ORDER BY
	A.cYr,
	A.cMth
GO

--SELECT
--	A.cYr,
--	A.cMthName,
--	A.[Total_LEGO_Cust] 'Store Total LEGO Cust',
--	B.[New_LEGO_Cust] 'Store New LEGO Cust'
--FROM
--	(
--		SELECT
--			DISTINCT DATEPART(MONTH,TC.transactionDate) 'cMth',
--			DATEPART(YEAR,TC.transactionDate) 'cYr',
--			DATENAME(MONTH,TC.transactionDate) 'cMthName',
--			COUNT(DISTINCT EMC.mergedCustomerId) 'Total_LEGO_Cust'
--		FROM ExpanededMergedCustomerIds EMC (nolock)
--			INNER JOIN Transactions TC (NOLOCK) ON EMC.insightCustomerId = TC.InsightCustomerId
--			INNER JOIN TransactionItem TI (NOLOCK) ON TC.Id = TI.transactionId
--			INNER JOIN #LEGO S (NOLOCK) ON S.sku = TI.sku
--		WHERE
--			ti.transactiontypeid = 1
--				AND TC.storeNumber <> 9999
--				AND TC.storenumber NOT IN (887,889)
--				AND TC.transactionDate >= '2023-01-01' AND TC.transactionDate < '2024-04-01'
--				AND EMC.mergedCustomerId NOT IN (SELECT DISTINCT mergedCustomerId FROM insighttemp..GK_CUSTOMER_BLACKLIST)
--				AND EMC.mergedCustomerId NOT IN (SELECT DISTINCT mergedcustomerid FROM insighttemp..GK_B2B_suppression)
--		GROUP BY
--			DATEPART(YEAR,TC.transactionDate),
--			DATEPART(MONTH,TC.transactionDate),
--			DATENAME(MONTH,TC.transactionDate)
--	) A
--LEFT OUTER JOIN
--	(
--		SELECT
--			DISTINCT DATEPART(MONTH,minTRGTrans) 'cMth',
--			DATEPART(YEAR,minTRGTrans) 'cYr',
--			COUNT(DISTINCT mergedCustomerId) 'New_LEGO_Cust'
--		FROM #NEWCUST
--		WHERE
--			DATEPART(YEAR,minTRGTrans) >= 2023 --AND DATEPART(YEAR,minTRGTrans) < 2024
--		GROUP BY
--			DATEPART(YEAR,minTRGTrans),
--			DATEPART(MONTH,minTRGTrans)
--	)B ON A.cYr = B.cYr AND A.cMth = B.cMth
--ORDER BY
--	A.cYr,
--	A.cMth
--GO

--SELECT
--	A.cYr,
--	A.cMthName,
--	A.[Total_LEGO_Cust] 'Online Total Pokemon Cust',
--	B.[New_LEGO_Cust] 'Online New Pokemon TCG Cust'
--FROM
--	(
--		SELECT
--			DISTINCT DATEPART(MONTH,TC.transactionDate) 'cMth',
--			DATEPART(YEAR,TC.transactionDate) 'cYr',
--			DATENAME(MONTH,TC.transactionDate) 'cMthName',
--			COUNT(DISTINCT EMC.mergedCustomerId) 'Total_LEGO_Cust'
--		FROM ExpanededMergedCustomerIds EMC (nolock)
--			INNER JOIN Transactions TC (NOLOCK) ON EMC.insightCustomerId = TC.InsightCustomerId
--			INNER JOIN TransactionItem TI (NOLOCK) ON TC.Id = TI.transactionId
--			INNER JOIN #LEGO S (NOLOCK) ON S.sku = TI.sku
--		WHERE
--			ti.transactiontypeid = 1
--				AND TC.storeNumber <> 9999
--				AND TC.storeNumber IN (887,889)
--				AND TC.transactionDate >= '2023-01-01' AND TC.transactionDate < '2024-04-01'
--				AND EMC.mergedCustomerId NOT IN (SELECT DISTINCT mergedCustomerId FROM insighttemp..GK_CUSTOMER_BLACKLIST)
--				AND EMC.mergedCustomerId NOT IN (SELECT DISTINCT mergedcustomerid FROM insighttemp..GK_B2B_suppression)
--		GROUP BY
--			DATEPART(YEAR,TC.transactionDate),
--			DATEPART(MONTH,TC.transactionDate),
--			DATENAME(MONTH,TC.transactionDate)
--	) A
--LEFT OUTER JOIN
--	(
--		SELECT
--			DISTINCT DATEPART(MONTH,minTRGTrans) 'cMth',
--			DATEPART(YEAR,minTRGTrans) 'cYr',
--			COUNT(DISTINCT mergedCustomerId) 'New_LEGO_Cust'
--		FROM #NEWCUST
--		WHERE
--			DATEPART(YEAR,minTRGTrans) >= 2023 --AND DATEPART(YEAR,minTRGTrans) < 2024
--		GROUP BY
--			DATEPART(YEAR,minTRGTrans),
--			DATEPART(MONTH,minTRGTrans)
--	)B ON A.cYr = B.cYr AND A.cMth = B.cMth
--ORDER BY
--	A.cYr,
--	A.cMth
--GO
