USE insight
GO

------------------------------------------PRODUCT TABLE------------------------------------------
-------------------------------------------------------------------------------------------------

IF OBJECT_ID ('tempdb..#PKMTCG') IS NOT NULL
	DROP TABLE #PKMTCG

SELECT *
	INTO #PKMTCG
	FROM sku S (NOLOCK)
	WHERE
		s.departmentId = 425
		AND s.subDepartmentId = 210
		AND s.marketplaceVendorId = 0001
		AND (s.title LIKE '%PKM%'
			OR s.title LIKE '%pokemon%'
			OR s.title LIKE '%pokémon%')
		AND s.title NOT LIKE '%plush%'
		AND s.title NOT LIKE '%plsh%'
		AND s.title NOT LIKE '%fig set%'
		AND s.title NOT LIKE '%bt fig%'
		AND s.title NOT LIKE '%eb fig%'
		AND s.title NOT LIKE '%ft fg%'
		AND s.title NOT LIKE '%fig ast%'
		AND s.title NOT LIKE 'DNU%'
		AND s.sku NOT IN ('814106','814137','814139','814155','814157','816402','814149')
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
		INNER JOIN #PKMTCG S (NOLOCK) ON S.sku = TI.sku
	WHERE
		TI.transactionTypeId = 1
		AND TC.storeNumber <> 9999
		AND emc.mergedCustomerId NOT IN (SELECT DISTINCT mergedCustomerId FROM insighttemp..GK_CUSTOMER_BLACKLIST)
		AND emc.mergedCustomerId NOT IN (SELECT DISTINCT mergedcustomerid FROM insighttemp..GK_B2B_suppression)
	GROUP BY
		emc.mergedcustomerid
GO

------------------------------------YEARLY CUST/NEW CUST-----------------------------------------
-------------------------------------------------------------------------------------------------

SELECT	A.cYr,
		A.[Total Pokemon Cust],
		B.[New Pokemon TCG Cust]
FROM
	(
	SELECT
		DATEPART(YEAR,TC.transactionDate) 'cYr',
		COUNT(DISTINCT emc.mergedcustomerid) 'Total Pokemon Cust'
	FROM
		expanededmergedcustomerids EMC (NOLOCK)
			INNER JOIN Transactions TC (NOLOCK) ON EMC.insightCustomerId = TC.InsightCustomerId
			INNER JOIN TransactionItem TI (NOLOCK) ON TC.Id = TI.transactionId
			INNER JOIN #PKMTCG S (NOLOCK) ON S.sku = TI.sku
	WHERE
		TI.transactionTypeId = 1
			AND TC.storeNumber <> 9999
			AND TC.transactionDate >= '2018-01-01' AND TC.transactionDate < '2024-01-01'
			AND EMC.mergedCustomerId NOT IN (SELECT DISTINCT mergedCustomerId FROM insighttemp..GK_CUSTOMER_BLACKLIST)
			AND EMC.mergedCustomerId NOT IN (SELECT DISTINCT mergedcustomerid FROM insighttemp..GK_B2B_suppression)
	GROUP BY
		DATEPART(YEAR,TC.transactionDate)
	) A
LEFT OUTER JOIN
	(
	SELECT
		DISTINCT DATEPART(YEAR,minTRGTrans) 'cYr',
		COUNT(DISTINCT mergedcustomerid) 'New Pokemon TCG Cust'
	FROM #NEWCUST
	WHERE
		DATEPART(YEAR,minTRGTrans) >= 2018 AND DATEPART(YEAR,minTRGTrans) < 2024
	GROUP BY
		DATEPART(YEAR,minTRGTrans)
	) B ON A.cYr = B.cYr
ORDER BY
	A.cYr
GO

SELECT	A.cYr,
		A.[Total Pokemon Cust] 'Store Total Pokemon Cust',
		B.[New Pokemon TCG Cust] 'Store New Pokemon TCG Cust'
FROM
	(
	SELECT
		DATEPART(YEAR,TC.transactionDate) 'cYr',
		COUNT(DISTINCT emc.mergedcustomerid) 'Total Pokemon Cust'
	FROM
		expanededmergedcustomerids EMC (NOLOCK)
			INNER JOIN Transactions TC (NOLOCK) ON EMC.insightCustomerId = TC.InsightCustomerId
			INNER JOIN TransactionItem TI (NOLOCK) ON TC.Id = TI.transactionId
			INNER JOIN #PKMTCG S (NOLOCK) ON S.sku = TI.sku
	WHERE
		TI.transactionTypeId = 1
			AND TC.storeNumber <> 9999
			AND TC.storeNumber NOT IN (887,889)
			AND TC.transactionDate >= '2018-01-01' AND TC.transactionDate < '2024-01-01'
			AND EMC.mergedCustomerId NOT IN (SELECT DISTINCT mergedCustomerId FROM insighttemp..GK_CUSTOMER_BLACKLIST)
			AND EMC.mergedCustomerId NOT IN (SELECT DISTINCT mergedcustomerid FROM insighttemp..GK_B2B_suppression)
	GROUP BY
		DATEPART(YEAR,TC.transactionDate)
	) A
LEFT OUTER JOIN
	(
	SELECT
		DISTINCT DATEPART(YEAR,minTRGTrans) 'cYr',
		COUNT(DISTINCT mergedcustomerid) 'New Pokemon TCG Cust'
	FROM #NEWCUST
	WHERE
		DATEPART(YEAR,minTRGTrans) >= 2018 AND DATEPART(YEAR,minTRGTrans) < 2024
	GROUP BY
		DATEPART(YEAR,minTRGTrans)
	) B ON A.cYr = B.cYr
ORDER BY
	A.cYr
GO

SELECT	A.cYr,
		A.[Total Pokemon Cust] 'Online Total Pokemon Cust',
		B.[New Pokemon TCG Cust] 'Online New Pokemon TCG Cust'
FROM
	(
	SELECT
		DATEPART(YEAR,TC.transactionDate) 'cYr',
		COUNT(DISTINCT emc.mergedcustomerid) 'Total Pokemon Cust'
	FROM expanededmergedcustomerids EMC (NOLOCK)
		INNER JOIN Transactions TC (NOLOCK) ON EMC.insightCustomerId = TC.InsightCustomerId
		INNER JOIN TransactionItem TI (NOLOCK) ON TC.Id = TI.transactionId
		INNER JOIN #PKMTCG S (NOLOCK) ON S.sku = TI.sku
	WHERE TI.transactionTypeId = 1
		AND TC.storeNumber <> 9999
		AND TC.storeNumber IN (887,889)
		AND TC.transactionDate >= '2018-01-01' AND TC.transactionDate < '2024-01-01'
		AND EMC.mergedCustomerId NOT IN (SELECT DISTINCT mergedCustomerId FROM insighttemp..GK_CUSTOMER_BLACKLIST)
		AND EMC.mergedCustomerId NOT IN (SELECT DISTINCT mergedcustomerid FROM insighttemp..GK_B2B_suppression)
	GROUP BY
		DATEPART(YEAR,TC.transactionDate)
	) A
LEFT OUTER JOIN
	(
	SELECT
		DISTINCT DATEPART(YEAR,minTRGTrans) 'cYr',
		COUNT(DISTINCT mergedcustomerid) 'New Pokemon TCG Cust'
	FROM #NEWCUST
	WHERE
		DATEPART(YEAR,minTRGTrans) >= 2018 AND DATEPART(YEAR,minTRGTrans) < 2024
	GROUP BY
		DATEPART(YEAR,minTRGTrans)
	) B ON A.cYr = B.cYr
ORDER BY
	A.cYr
GO

-----------------------------MONTHLY TRENDED NEW CUST (L2Y)--------------------------------------
-------------------------------------------------------------------------------------------------

SELECT
	A.cYr,
	A.cMthName,
	A.[Total Pokemon Cust],
	B.[New Pokemon TCG Cust]
FROM
	(
		SELECT
			DISTINCT DATEPART(MONTH,TC.transactionDate) 'cMth',
			DATEPART(YEAR,TC.transactionDate) 'cYr',
			DATENAME(MONTH,TC.transactionDate) 'cMthName',
			COUNT(DISTINCT EMC.mergedCustomerId) 'Total Pokemon Cust'
		FROM ExpanededMergedCustomerIds EMC (nolock)
			INNER JOIN Transactions TC (NOLOCK) ON EMC.insightCustomerId = TC.InsightCustomerId
			INNER JOIN TransactionItem TI (NOLOCK) ON TC.Id = TI.transactionId
			INNER JOIN #PKMTCG S (NOLOCK) ON S.sku = TI.sku
		WHERE
			ti.transactiontypeid = 1
				AND TC.storeNumber <> 9999
				AND TC.transactionDate >= '2022-01-01' AND TC.transactionDate < '2024-01-01'
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
			COUNT(DISTINCT mergedCustomerId) 'New Pokemon TCG Cust'
		FROM #NEWCUST
		WHERE
			DATEPART(YEAR,minTRGTrans) >= 2022 AND DATEPART(YEAR,minTRGTrans) < 2024
		GROUP BY
			DATEPART(YEAR,minTRGTrans),
			DATEPART(MONTH,minTRGTrans)
	)B ON A.cYr = B.cYr AND A.cMth = B.cMth
ORDER BY
	A.cYr,
	A.cMth
GO

SELECT
	A.cYr,
	A.cMthName,
	A.[Total Pokemon Cust] 'Store Total Pokemon Cust',
	B.[New Pokemon TCG Cust] 'Store New Pokemon TCG Cust'
FROM
	(
		SELECT
			DISTINCT DATEPART(MONTH,TC.transactionDate) 'cMth',
			DATEPART(YEAR,TC.transactionDate) 'cYr',
			DATENAME(MONTH,TC.transactionDate) 'cMthName',
			COUNT(DISTINCT EMC.mergedCustomerId) 'Total Pokemon Cust'
		FROM ExpanededMergedCustomerIds EMC (nolock)
			INNER JOIN Transactions TC (NOLOCK) ON EMC.insightCustomerId = TC.InsightCustomerId
			INNER JOIN TransactionItem TI (NOLOCK) ON TC.Id = TI.transactionId
			INNER JOIN #PKMTCG S (NOLOCK) ON S.sku = TI.sku
		WHERE
			ti.transactiontypeid = 1
				AND TC.storeNumber <> 9999
				AND TC.storenumber NOT IN (887,889)
				AND TC.transactionDate >= '2022-01-01' AND TC.transactionDate < '2024-01-01'
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
			COUNT(DISTINCT mergedCustomerId) 'New Pokemon TCG Cust'
		FROM #NEWCUST
		WHERE
			DATEPART(YEAR,minTRGTrans) >= 2022 AND DATEPART(YEAR,minTRGTrans) < 2024
		GROUP BY
			DATEPART(YEAR,minTRGTrans),
			DATEPART(MONTH,minTRGTrans)
	)B ON A.cYr = B.cYr AND A.cMth = B.cMth
ORDER BY
	A.cYr,
	A.cMth
GO

SELECT
	A.cYr,
	A.cMthName,
	A.[Total Pokemon Cust] 'Online Total Pokemon Cust',
	B.[New Pokemon TCG Cust] 'Online New Pokemon TCG Cust'
FROM
	(
		SELECT
			DISTINCT DATEPART(MONTH,TC.transactionDate) 'cMth',
			DATEPART(YEAR,TC.transactionDate) 'cYr',
			DATENAME(MONTH,TC.transactionDate) 'cMthName',
			COUNT(DISTINCT EMC.mergedCustomerId) 'Total Pokemon Cust'
		FROM ExpanededMergedCustomerIds EMC (nolock)
			INNER JOIN Transactions TC (NOLOCK) ON EMC.insightCustomerId = TC.InsightCustomerId
			INNER JOIN TransactionItem TI (NOLOCK) ON TC.Id = TI.transactionId
			INNER JOIN #PKMTCG S (NOLOCK) ON S.sku = TI.sku
		WHERE
			ti.transactiontypeid = 1
				AND TC.storeNumber <> 9999
				AND TC.storeNumber IN (887,889)
				AND TC.transactionDate >= '2022-01-01' AND TC.transactionDate < '2024-01-01'
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
			COUNT(DISTINCT mergedCustomerId) 'New Pokemon TCG Cust'
		FROM #NEWCUST
		WHERE
			DATEPART(YEAR,minTRGTrans) >= 2022 AND DATEPART(YEAR,minTRGTrans) < 2024
		GROUP BY
			DATEPART(YEAR,minTRGTrans),
			DATEPART(MONTH,minTRGTrans)
	)B ON A.cYr = B.cYr AND A.cMth = B.cMth
ORDER BY
	A.cYr,
	A.cMth
GO

----------------------------CUSTOMER VISTS (REDUNDANT ANALYSIS - CODE ARCHIVED)-------------------
-------------------------------------------------------------------------------------------------

--if object_id ('tempdb..#NEWCUST_TRANS') is not NULL
--	drop table #NEWCUST_TRANS
--select
--	distinct n.mergedcustomerid,
--	convert(date,n.minTRGTrans) 'minTRGTrans',
--	convert(date,tc.transactiondate) 'transactiondate'
--into
--	#NEWCUST_TRANS
--from
--	#NEWCUST n
--	inner join expanededmergedcustomerids emc (nolock) on n.mergedcustomerid = emc.mergedcustomerid
--	inner join transactions tc (nolock) on emc.insightcustomerid = tc.insightcustomerid
--	inner join transactionitem ti (nolock) on tc.id = ti.transactionid
--	inner join #PKMTCG s (nolock) on ti.sku = s.sku
--where
--	ti.transactiontypeid = 1
--	and tc.storenumber != 9999
--	and datepart(year,n.minTRGTrans) >= 2016
--go

--if object_id ('tempdb..#NEWPKMCUST') is not NULL
--	drop table #NEWPKMCUST
--select
--	distinct n.mergedcustomerid,
--	n.minTRGTrans,
--	x.mxTDate,
--	n.transactiondate
--into
--	#NEWPKMCUST
--from
--	#NEWCUST_TRANS n
--	left outer join 
--	(
--		select
--			distinct mergedcustomerid,
--			max(transactiondate) 'mxTDate'
--		from
--			#NEWCUST_TRANS
--		group by
--			mergedcustomerid
--	)X on n.mergedcustomerid = x.mergedcustomerid
--go

--select
--	*
--from
--	(
--		select
--			distinct newCY,
--			case when daysVisited > 2 then 3 else daysVisited end 'daysVisited',
--			count(distinct mergedcustomerid) 'cust'
--		from
--			(
--				select
--					distinct mergedcustomerid,
--					datepart(year,minTRGTrans) 'newCY',
--					count(distinct transactiondate) 'daysVisited'
--				from
--					#NEWPKMCUST
--				group by
--					mergedcustomerid,
--					datepart(year,minTRGTrans)
--			)x
--		group by
--			newCY,
--			case when daysVisited > 2 then 3 else daysVisited end
--	)D
--	PIVOT(sum(cust) for [daysVisited] in ([1],[2],[3])) PVT
--order by
--	newCY

--if object_id ('tempdb..#NEW_TENURE') is not NULL
--	drop table #NEW_TENURE
--select
--	distinct newCY,
--	weeksTenure,
--	count(distinct mergedcustomerid) 'cust'
--into
--	#NEW_TENURE
--from
--	(
--		select
--			distinct mergedcustomerid,
--			datepart(year,minTRGTrans) 'newCY',
--			datediff(day,minTRGTrans,mxTDate) / 7 'weeksTenure'
--		from
--			#NEWPKMCUST
--		group by
--			mergedcustomerid,
--			datepart(year,minTRGTrans),
--			datediff(day,minTRGTrans,mxTDate) / 7
--	)x
--group by
--	newCY,
--	weeksTenure
--go

--select
--	distinct newCY,
--	cust
--from
--	#NEW_TENURE
--where
--	weeksTenure = 0
--order by
--	newCY

--select
--	distinct newCY,
--	sum(cust) 'cust'
--from
--	#NEW_TENURE
--where
--	weeksTenure > 0
--	and weeksTenure <= 26
--group by
--	newCY
--order by
--	newCY

--select
--	distinct newCY,
--	sum(cust) 'cust'
--from
--	#NEW_TENURE
--where
--	weeksTenure > 26
--	and weeksTenure <= 52
--group by
--	newCY
--order by
--	newCY

--select
--	distinct newCY,
--	sum(cust) 'cust'
--from
--	#NEW_TENURE
--where
--	weeksTenure > 52
--group by
--	newCY
--order by
--	newCY