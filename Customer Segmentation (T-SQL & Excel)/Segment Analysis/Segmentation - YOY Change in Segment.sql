use insight
go


if object_id ('tempdb..#ACT18') is not NULL
	drop table #ACT18
select
	distinct emc.mergedcustomerid,
	count (distinct tc.id) 'tCount',
	sum (totalamount) 'vSum'
into
	#ACT18
from
	expanededmergedcustomerids emc (nolock)
	inner join transactions tc (nolock) on emc.insightcustomerid = tc.insightcustomerid
where
	transactiondate >= cast(dateadd(month,-18,getdate()) as date)
	and totalamount != 0
	and storenumber <> 9999
	and emc.mergedcustomerid not in (select mergedcustomerid from insighttemp..GK_CUSTOMER_BLACKLIST)
group by
	emc.mergedcustomerid
go



if object_id ('tempdb..#ACTMINTRAN') is not NULL
	drop table #ACTMINTRAN
select
	distinct a.mergedcustomerid,
	a.tCount,
	a.vSum,
	min (transactiondate) 'mDate'
into
	#ACTMINTRAN
from
	#ACT18 a
	inner join expanededmergedcustomerids emc (nolock) on a.mergedcustomerid = emc.mergedcustomerid
	inner join transactions tc (nolock) on emc.insightcustomerid = tc.insightcustomerid
group by
	a.mergedcustomerid,
	a.tCount,
	a.vSum
go



if object_id ('tempdb..#SANDBOX') is not NULL
	drop table #SANDBOX
select
	a.mergedcustomerid,
	case 
		when tCount = 1 then '1'
		when tCount = 2 then '2'
		when tCount = 3 then '3'
		when tCount = 4 then '4'
		when tCount = 5 then '5'
		when tCount = 6 then '6'
		when tCount = 7 then '7'
		when tCount = 8 then '8'
		when tCount = 9 then '9'
		when tCount = 10 then '10'
		when tCount = 11 then '11'
		when tCount = 12 then '12'
		when tCount = 13 then '13'
		when tCount = 14 then '14'
		when tCount = 15 then '15'
		when tCount = 16 then '16'
		when tCount = 17 then '17'
		when tCount >= 18 then '18+'
	end [Freq],
	case 
		when vSum > 0 and vSum < 10 then '0-9'
		when vSum >= 10 and vSum < 20 then '10-19'
		when vSum >= 20 and vSum < 30 then '20-29'
		when vSum >= 30 and vSum < 40 then '30-39'
		when vSum >= 40 and vSum < 50 then '40-49'
		when vSum >= 50 and vSum < 100 then '50-99'
		when vSum >= 100 and vSum < 150 then '100-149'
		when vSum >= 150 and vSum < 200 then '150-199'
		when vSum >= 200 and vSum < 250 then '200-249'
		when vSum >= 250 and vSum < 300 then '250-299'
		when vSum >= 300 and vSum < 400 then '300-399'
		when vSum >= 400 and vSum < 500 then '400-499'
		when vSum >= 500 and vSum < 600 then '500-599'
		when vSum >= 600 and vSum < 700 then '600-699'
		when vSum >= 700 and vSum < 800 then '700-799'
		when vSum >= 800 and vSum < 900 then '800-899'
		when vSum >= 900 and vSum < 1000 then '900-999'
		when vSum >= 1000 then '1000+'
	end [Val]
into
	#SANDBOX
from
	#ACTMINTRAN a
where
	mDate < cast(dateadd(month,-6,getdate()) as date)
	and vSum > 0 
	and vSum is not NULL
go




--| Casual Acquaintance - Freq = 1 / Val = 0-39
--| Pocket Regulars - Freq = 3-18+ / Val = 0-99 or Freq = 7-18+ and Val = 100-199
--| Occassional Trippers - Freq = 1 / Val = 40-149 or Freq = 2 / Val = 0-149
--| Single Splurgers - Freq = 1-2 / Val = 150-1000+
--| Average Shoppers - Freq = 3-6 / Val = 100-299
--| Middleweight Spenders - Freq = 3-6 / Val = 300-499 or Freq = 7-10 / Val = 200-499
--| Big Time Spenders - Freq = 3-10 / Val = 500-1000+ or Freq = 11-17 / Val = 200-1000+ or Freq = 18+ / Val = 200-999
--| Top Elite - Freq = 18+ / Val = 1000+




if object_id ('tempdb..#VFSEGMENT_TEST') is not NULL
	drop table #VFSEGMENT_TEST
select
	mergedcustomerid,
	case
		when VFSegmentName = 'Casual Acquaintance' then 2
		when VFSegmentName = 'Pocket Regulars' then 3
		when VFSegmentName = 'Occasional Trippers' then 4
		when VFSegmentName = 'Single Splurgers' then 5
		when VFSegmentName = 'Average Shoppers' then 6
		when VFSegmentName = 'Middleweight Spenders' then 7
		when VFSegmentName = 'Big Time Spenders' then 8
		when VFSegmentName = 'Top Elite' then 9
	end [VFSegmentID],
	VFSegmentName
into
	#VFSEGMENT_TEST
from
	(
		select
			distinct mergedcustomerid,
			case
				when 
					Freq = '1' 
					and Val in ('0-9','10-19','20-29','30-39') 
				then 'Casual Acquaintance'
				when 
					(
					Freq not in ('1','2') 
					and Val in ('0-9','10-19','20-29','30-39','40-49','50-99')
					)
					or 
					(
					Freq in ('6','7','8','9','10','11','12','13','14','15','16','17','18+') 
					and Val in ('100-149','150-199')
					) 
				then 'Pocket Regulars'
				when 
					(
					Freq = '1' 
					and Val in ('40-49','50-99','100-149')
					) 
					or 
					(
					Freq = '2' 
					and Val in ('0-9','10-19','20-29','30-39','40-49','50-99','100-149')
					) 
				then 'Occasional Trippers'
				when 
					Freq in ('1','2') 
					and Val not in ('0-9','10-19','20-29','30-39','40-49','50-99','100-149') 
				then 'Single Splurgers'
				when 
					Freq in ('3','4','5') 
					and Val in ('100-149','150-199','200-249','250-299','300-399') 
				then 'Average Shoppers'
				when 
					(
					Freq in ('3','4','5') 
					and Val = '400-499'
					)
					or 
					(
					Freq in ('6','7','8','9','10') 
					and Val in ('200-249','250-299','300-399','400-499')
					) 
				then 'Middleweight Spenders'
				when 
					(
					Freq in ('3','4','5','6','7','8','9','10') 
					and Val in ('500-599','600-699','700-799','800-899','900-999','1000+')
					)
					or 
					(
					Freq in ('11','12','13','14','15','16','17') 
					and Val in ('200-249','250-299','300-399','400-499','500-599','600-699','700-799','800-899','900-999','1000+')
					)
					or 
					(
					Freq = '18+' 
					and Val in ('200-249','250-299','300-399','400-499','500-599','600-699','700-799','800-899','900-999')
					) 
				then 'Big Time Spenders'
				when 
					Freq = '18+' 
					and Val = '1000+' 
				then 'Top Elite'
			end [VFSegmentName]
		from
			#SANDBOX
	)SEGNAME
go



if object_id ('tempdb..#UPPER_THRESHOLD_SUPPRESSION') is not NULL
	drop table #UPPER_THRESHOLD_SUPPRESSION
select
	distinct v.mergedcustomerid,
	v.VFSegmentID,
	v.VFSegmentName,
	sum (totalamount) 'Spend'
into
	#UPPER_THRESHOLD_SUPPRESSION
from
	#VFSEGMENT_TEST v
	inner join expanededmergedcustomerids emc (nolock) on v.mergedcustomerid = emc.mergedcustomerid
	inner join transactions tc (nolock) on emc.insightcustomerid = tc.insightcustomerid
where
	transactiondate > dateadd(month,-18,getdate())
	and totalamount != 0
	and storenumber <> 9999
group by
	v.mergedcustomerid,
	v.VFSegmentID,
	v.VFSegmentName
having 
	sum (totalamount) > 10000
go





if object_id ('tempdb..#VFSEGMENT_TEST2') is not NULL
	drop table #VFSEGMENT_TEST2
select
	A.*,
	emc.insightcustomerid
into
	#VFSEGMENT_TEST2
from
	(
		select
			*
		from
			#VFSEGMENT_TEST
		where
			mergedcustomerid not in (select mergedcustomerid from #UPPER_THRESHOLD_SUPPRESSION)
		union all
		select
			distinct mergedcustomerid,
			'1' [VFSegmentID],
			'GAME Rookies' VFSegmentName
		from
			#ACTMINTRAN
		where
			mDate >= cast(dateadd(month,-6,getdate()) as date)
	)A
	inner join expanededmergedcustomerids emc (nolock) on A.mergedcustomerid = emc.mergedcustomerid
go




-----------------------------------------------------------------------------------------------------------------------------------------------------





if object_id ('tempdb..#ACT18_LY') is not NULL
	drop table #ACT18_LY
select
	distinct emc.mergedcustomerid,
	count (distinct tc.id) 'tCount',
	sum (totalamount) 'vSum'
into
	#ACT18_LY
from
	expanededmergedcustomerids emc (nolock)
	inner join transactions tc (nolock) on emc.insightcustomerid = tc.insightcustomerid
	inner join segmentBits sb (nolock) on tc.insightcustomerid = sb.insightcustomerid
where
	transactiondate >= cast(dateadd(month,-18,dateadd(month,-12,getdate())) as date)
	and transactiondate < cast(dateadd(month,-12,getdate()) as date)
	and totalamount != 0
	and storenumber <> 9999
	and sb.isB2B = 0
	and emc.mergedcustomerid not in (select mergedcustomerid from insighttemp..GK_CUSTOMER_BLACKLIST)
group by
	emc.mergedcustomerid
go



if object_id ('tempdb..#ACTMINTRAN_LY') is not NULL
	drop table #ACTMINTRAN_LY
select
	distinct a.mergedcustomerid,
	a.tCount,
	a.vSum,
	min (transactiondate) 'mDate'
into
	#ACTMINTRAN_LY
from
	#ACT18_LY a
	inner join expanededmergedcustomerids emc (nolock) on a.mergedcustomerid = emc.mergedcustomerid
	inner join transactions tc (nolock) on emc.insightcustomerid = tc.insightcustomerid
group by
	a.mergedcustomerid,
	a.tCount,
	a.vSum
go



if object_id ('tempdb..#SANDBOX_LY') is not NULL
	drop table #SANDBOX_LY
select
	a.mergedcustomerid,
	case 
		when tCount = 1 then '1'
		when tCount = 2 then '2'
		when tCount = 3 then '3'
		when tCount = 4 then '4'
		when tCount = 5 then '5'
		when tCount = 6 then '6'
		when tCount = 7 then '7'
		when tCount = 8 then '8'
		when tCount = 9 then '9'
		when tCount = 10 then '10'
		when tCount = 11 then '11'
		when tCount = 12 then '12'
		when tCount = 13 then '13'
		when tCount = 14 then '14'
		when tCount = 15 then '15'
		when tCount = 16 then '16'
		when tCount = 17 then '17'
		when tCount >= 18 then '18+'
	end [Freq],
	case 
		when vSum > 0 and vSum < 10 then '0-9'
		when vSum >= 10 and vSum < 20 then '10-19'
		when vSum >= 20 and vSum < 30 then '20-29'
		when vSum >= 30 and vSum < 40 then '30-39'
		when vSum >= 40 and vSum < 50 then '40-49'
		when vSum >= 50 and vSum < 100 then '50-99'
		when vSum >= 100 and vSum < 150 then '100-149'
		when vSum >= 150 and vSum < 200 then '150-199'
		when vSum >= 200 and vSum < 250 then '200-249'
		when vSum >= 250 and vSum < 300 then '250-299'
		when vSum >= 300 and vSum < 400 then '300-399'
		when vSum >= 400 and vSum < 500 then '400-499'
		when vSum >= 500 and vSum < 600 then '500-599'
		when vSum >= 600 and vSum < 700 then '600-699'
		when vSum >= 700 and vSum < 800 then '700-799'
		when vSum >= 800 and vSum < 900 then '800-899'
		when vSum >= 900 and vSum < 1000 then '900-999'
		when vSum >= 1000 then '1000+'
	end [Val]
into
	#SANDBOX_LY
from
	#ACTMINTRAN_LY a
where
	mDate < dateadd(month,-6,cast(dateadd(month,-12,getdate()) as date))
	and vSum > 0 
	and vSum is not NULL
go




--| Casual Acquaintance - Freq = 1 / Val = 0-39
--| Pocket Regulars - Freq = 3-18+ / Val = 0-99 or Freq = 7-18+ and Val = 100-199
--| Occassional Trippers - Freq = 1 / Val = 40-149 or Freq = 2 / Val = 0-149
--| Single Splurgers - Freq = 1-2 / Val = 150-1000+
--| Average Shoppers - Freq = 3-6 / Val = 100-299
--| Middleweight Spenders - Freq = 3-6 / Val = 300-499 or Freq = 7-10 / Val = 200-499
--| Big Time Spenders - Freq = 3-10 / Val = 500-1000+ or Freq = 11-17 / Val = 200-1000+ or Freq = 18+ / Val = 200-999
--| Top Elite - Freq = 18+ / Val = 1000+




if object_id ('tempdb..#VFSEGMENT_TEST_LY') is not NULL
	drop table #VFSEGMENT_TEST_LY
select
	mergedcustomerid,
	case
		when VFSegmentName = 'Casual Acquaintance' then 2
		when VFSegmentName = 'Pocket Regulars' then 3
		when VFSegmentName = 'Occasional Trippers' then 4
		when VFSegmentName = 'Single Splurgers' then 5
		when VFSegmentName = 'Average Shoppers' then 6
		when VFSegmentName = 'Middleweight Spenders' then 7
		when VFSegmentName = 'Big Time Spenders' then 8
		when VFSegmentName = 'Top Elite' then 9
	end [VFSegmentID],
	VFSegmentName
into
	#VFSEGMENT_TEST_LY
from
	(
		select
			distinct mergedcustomerid,
			case
				when 
					Freq = '1' 
					and Val in ('0-9','10-19','20-29','30-39') 
				then 'Casual Acquaintance'
				when 
					(
					Freq not in ('1','2') 
					and Val in ('0-9','10-19','20-29','30-39','40-49','50-99')
					)
					or 
					(
					Freq in ('6','7','8','9','10','11','12','13','14','15','16','17','18+') 
					and Val in ('100-149','150-199')
					) 
				then 'Pocket Regulars'
				when 
					(
					Freq = '1' 
					and Val in ('40-49','50-99','100-149')
					) 
					or 
					(
					Freq = '2' 
					and Val in ('0-9','10-19','20-29','30-39','40-49','50-99','100-149')
					) 
				then 'Occasional Trippers'
				when 
					Freq in ('1','2') 
					and Val not in ('0-9','10-19','20-29','30-39','40-49','50-99','100-149') 
				then 'Single Splurgers'
				when 
					Freq in ('3','4','5') 
					and Val in ('100-149','150-199','200-249','250-299','300-399') 
				then 'Average Shoppers'
				when 
					(
					Freq in ('3','4','5') 
					and Val = '400-499'
					)
					or 
					(
					Freq in ('6','7','8','9','10') 
					and Val in ('200-249','250-299','300-399','400-499')
					) 
				then 'Middleweight Spenders'
				when 
					(
					Freq in ('3','4','5','6','7','8','9','10') 
					and Val in ('500-599','600-699','700-799','800-899','900-999','1000+')
					)
					or 
					(
					Freq in ('11','12','13','14','15','16','17') 
					and Val in ('200-249','250-299','300-399','400-499','500-599','600-699','700-799','800-899','900-999','1000+')
					)
					or 
					(
					Freq = '18+' 
					and Val in ('200-249','250-299','300-399','400-499','500-599','600-699','700-799','800-899','900-999')
					) 
				then 'Big Time Spenders'
				when 
					Freq = '18+' 
					and Val = '1000+' 
				then 'Top Elite'
			end [VFSegmentName]
		from
			#SANDBOX_LY
	)SEGNAME
go



if object_id ('tempdb..#UPPER_THRESHOLD_SUPPRESSION_LY') is not NULL
	drop table #UPPER_THRESHOLD_SUPPRESSION_LY
select
	distinct v.mergedcustomerid,
	v.VFSegmentID,
	v.VFSegmentName,
	sum (totalamount) 'Spend'
into
	#UPPER_THRESHOLD_SUPPRESSION_LY
from
	#VFSEGMENT_TEST_LY v
	inner join expanededmergedcustomerids emc (nolock) on v.mergedcustomerid = emc.mergedcustomerid
	inner join transactions tc (nolock) on emc.insightcustomerid = tc.insightcustomerid
where
	transactiondate > cast(dateadd(month,-18,dateadd(month,-12,getdate())) as date)
	and transactiondate < cast(dateadd(month,-12,getdate()) as date)
	and totalamount != 0
	and storenumber <> 9999
group by
	v.mergedcustomerid,
	v.VFSegmentID,
	v.VFSegmentName
having 
	sum (totalamount) > 10000
go





if object_id ('tempdb..#VFSEGMENT_TEST2_LY') is not NULL
	drop table #VFSEGMENT_TEST2_LY
select
	A.*,
	emc.insightcustomerid
into
	#VFSEGMENT_TEST2_LY
from
	(
		select
			*
		from
			#VFSEGMENT_TEST_LY
		where
			mergedcustomerid not in (select mergedcustomerid from #UPPER_THRESHOLD_SUPPRESSION_LY)
		union all
		select
			distinct mergedcustomerid,
			'1' [VFSegmentID],
			'GAME Rookies' VFSegmentName
		from
			#ACTMINTRAN_LY
		where
			mDate >= cast(dateadd(month,-6,dateadd(month,-12,getdate())) as date)
			and mDate < cast(dateadd(month,-12,getdate()) as date)
	)A
	inner join expanededmergedcustomerids emc (nolock) on A.mergedcustomerid = emc.mergedcustomerid
go





if object_id ('tempdb..#YOY_TRANSITION') is not NULL
	drop table #YOY_TRANSITION
select
	distinct mergedcustomerid,
	VFSegmentID,
	VFSegmentName,
	'Lapsed' 'VFSegmentNow'
into
	#YOY_TRANSITION
from
	#VFSEGMENT_TEST2_LY
where
	mergedcustomerid not in (select mergedcustomerid from #VFSEGMENT_TEST2)
union all
select
	distinct ly.mergedcustomerid,
	ly.VFSegmentID,
	ly.VFSegmentName,
	ty.VFSegmentName 'VFSegmentNow'
from
	#VFSEGMENT_TEST2_LY ly
	inner join #VFSEGMENT_TEST2 ty on ly.mergedcustomerid = ty.mergedcustomerid
union all
select
	distinct mergedcustomerid,
	'0' 'VFSegmentID',
	'Not Yet A Customer' 'VFSegmentName',
	VFSegmentName 'VFSegmentNow'
from
	#VFSEGMENT_TEST2
where
	mergedcustomerid not in (select mergedcustomerid from #VFSEGMENT_TEST2_LY)
go





select
	*
from
	#YOY_TRANSITION
PIVOT (count(mergedcustomerid) for [VFSegmentNow] in ([GAME Rookies],[Casual Acquaintance],[Pocket Regulars],[Occasional Trippers],[Single Splurgers],[Average Shoppers],[Middleweight Spenders],[Big Time Spenders],[Top Elite],[Lapsed])) as PVTTable
order by
	VFSegmentId,
	VFSegmentName
