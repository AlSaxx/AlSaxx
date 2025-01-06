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
	and vSum < 10000 
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
	a.mergedcustomerid,
	a.vSum,
	v.VFSegmentID,
	v.VFSegmentName 
into
	#UPPER_THRESHOLD_SUPPRESSION
from 
	#ACT18 a 
	inner join #VFSEGMENT_TEST v on a.mergedcustomerid = v.mergedcustomerid
where
	a.vSum > 10000
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


/*

create table insighttemp..CustomerSegment_GK
(
mergedCustomerID int,
VFSegmentID int,
VFSegmentName varchar(50),
insightCustomerID int,
updatedDate date
)
go

INSERT insighttemp..CustomerSegment_GK (mergedCustomerID,VFSegmentID,VFSegmentName,insightCustomerID,updatedDate)
select
	*,
	convert(date,getdate()) [updatedDate]
from
	#VFSEGMENT_TEST2
go

*/

---------
--| TEMPS
---------

if object_id ('tempdb..#AGEBREAKDOWN') is not NULL
	drop table #AGEBREAKDOWN
select
	distinct v.mergedcustomerid,
	VFSegmentID,
	VFSegmentName,
	ic.age
into
	#AGEBREAKDOWN
from
	#VFSEGMENT_TEST2 v
	inner join compositecustomer cc (nolock) on v.mergedcustomerid = cc.id
	inner join insightcustomer ic (nolock) on v.insightcustomerid = ic.id and cc.dateOfBirth = ic.dateOfBirth
where
	ic.age <> '-1'
go


if object_id ('tempdb..#SHOPPINGBEHAVIOUR') is not NULL
	drop table #SHOPPINGBEHAVIOUR
select
	distinct v.mergedcustomerid,
	v.vfsegmentid,
	v.VFSegmentName,
	v.insightcustomerid,
	tc.id,
	tc.transactiondate,
	tc.storenumber,
	tc.cashpaymentAmount,
	tc.cardPaymentAmount,
	tc.giftcardPaymentAmount,
	ti.transactiontypeid,
	ti.quantity,
	ti.totalPrice,
	s.sku,
	s.title,
	s.releasedate,
	s.departmentid,
	s.subdepartmentid,
	s.productclassid,
	s.productsubclassid,
	s.platformid,
	s.pegiratingid,
	s.genreid
into
	#SHOPPINGBEHAVIOUR
from
	#VFSEGMENT_TEST2 v
	inner join transactions tc (nolock) on v.insightcustomerid = tc.insightcustomerid
	inner join transactionitem ti (nolock) on tc.id = ti.transactionid
	inner join sku s (nolock) on ti.sku = s.sku
where
	tc.transactiondate > cast(dateadd(month,-18,getdate()) as date)
	and tc.storenumber not in (0,999,9999)
go


if object_id ('tempdb..#DIGISEG') is not NULL
	drop table #DIGISEG
select 
	distinct mergedcustomerid,
	vfsegmentid
into
	#DIGISEG
from
	#SHOPPINGBEHAVIOUR
where
	transactiontypeid = 1
	and (productclassid = 5 
			or productsubclassid in (8,9) 
				or title like '%steam wallet%'
					or departmentid in (456,470))
	and sku not in (select sku from sku where departmentid = 470 and subdepartmentid = 50)
go


if object_id ('tempdb..#PHYSSEG') is not NULL
	drop table #PHYSSEG
select 
	distinct mergedcustomerid,
	vfsegmentid
into
	#PHYSSEG
from
	#SHOPPINGBEHAVIOUR
where
	transactiontypeid = 1
	and sku not in (select sku from sku where productclassid = 5 or productsubclassid in (8,9) or title like '%steam wallet%' or departmentid in (456,470))
	and sku not in (select sku from sku where departmentid = 470 and subdepartmentid = 50)
go



----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--| CRIB SHEET ANALYSIS |--


select
	distinct A.VFSegmentID,
	A.VFSegmentName,
	A.Cust,
	A.Spend,
	A.Trans,
	A.Units,
	B.Email,
	C.[Trade-in],
	D.Digital,
	E.App,
	F.Store,
	G.[Online],
	H.[Store & Online],
	I.NewGen,
	J.Physical,
	K.Digital,
	L.[Physical & Digital],
	M.Mint,
	N.Preowned,
	O.[Mint & Preowned],
	P.[Bought HW],
	Q.[Bought SW],
	R.[Bought ACC],
	S.[Bought Exclusives],
	T.[Bought Tech],
	U.[Bought Board Games],
	U2.[Bought Clothing],
	U3.[Bought TCG],
	U4.[Bought Toys & Collectables],
	V.[Bought PEGI 16 or Under],
	W.[Opened CRM Emails],
	W.[Total Emails Opened],
	X.[Bought in L12M],
	X.[Trans in L12M],
	Y.[Bought in L9M],
	Z.[Bought in L6M],
	AA.[Bought in L3M],
	AB.[Bought in L1M],
	AC.[Bought in December],
	AC.[Trans in December],
	AD.[Bought in Week 1],
	AE.[Paid with Cash],
	AF.[Paid with Card],
	AG.[Paid with Gift Card],
	AJ.[Under 13],
	AJ.[13-17],
	AJ.[18-25],
	AJ.[26-30],
	AJ.[31-35],
	AJ.[36-40],
	AJ.[41-45],
	AJ.[46-55],
	AJ.[56-65],
	AJ.[Over 65],
	AK.SW_Spend,
	AL.HW_Spend,
	AM.ACC_Spend,
	AN.Digital_Spend,
	AP.[PEGI16 or Under_Spend],
	AQ.Tech_Spend,
	AR.[Board Games_Spend],
	AU.Clothing_Spend,
	AV.TCG_Spend,
	AW.[Toys & Collectables_Spend]
from
	(	
		select
			distinct VFSegmentID,
			VFSegmentName,
			count (distinct mergedcustomerid) 'Cust',
			sum (totalPrice) 'Spend',
			count (distinct id) 'Trans',
			sum (quantity) 'Units'
		from
			#SHOPPINGBEHAVIOUR
		where
			transactiontypeid != 6
			and totalPrice != 0
		group by
			VFSegmentID,
			VFSegmentName
	)A
	left outer join 
	(
		select
			distinct VFSegmentID,
			count (distinct v.mergedcustomerid) 'Email'
		from
			#VFSEGMENT_TEST2 v
			inner join insightcustomer ic (nolock) on v.insightcustomerid = ic.id
			inner join contactpreference cp (nolock) on ic.contactpreferencesid = cp.contactpreferenceid
		where
			email is not Null
			and email <> ''
			and contactablebyemail = 1
		group by
			VFSegmentID
	)B 
	on A.VFSegmentID = B.VFSegmentID
	left outer join 
	(
		select
			distinct VFSegmentID,
			count (distinct mergedcustomerid) 'Trade-in'
		from
			#SHOPPINGBEHAVIOUR
		where
			transactiontypeid = 6
		group by
			VFSegmentID
	)C	
	on A.VFSegmentID = C.VFSegmentID
	left outer join 	
	(
		select
			distinct VFSegmentID,
			count (distinct mergedcustomerid) 'Digital'
		from
			#SHOPPINGBEHAVIOUR
		where
			transactiontypeid = 1
			and (productclassid = 5 
					or productsubclassid in (8,9) 
						or title like '%steam wallet%'
							or departmentid in (456,470))
			and sku not in (select sku from sku where departmentid = 470 and subdepartmentid = 50)
		group by
			VFSegmentID
	)D	
	on A.VFSegmentID = D.VFSegmentID
	left outer join 	
	(
		select
			distinct VFSegmentID,
			count (distinct v.mergedcustomerid) 'App'
		from
			#VFSEGMENT_TEST2 v
			inner join 
			(
				select
					distinct ic.id 'APPCust'
				from
					mobiledeviceaccess mda (nolock)
					inner join insightcustomer ic (nolock) on mda.rewardnumber = ic.rewardnumber
				where
					dateaccessrevoked is NULL
			) APP
				on v.insightcustomerid = APP.APPCust
		group by
			VFSegmentID
	)E	
	on A.VFSegmentID = E.VFSegmentID
	left outer join 
	(
		select
			distinct VFSegmentID,
			count (distinct mergedcustomerid) 'Store'
		from
			#SHOPPINGBEHAVIOUR
		where
			storenumber != 889
			and mergedcustomerid not in (select	distinct mergedcustomerid from #SHOPPINGBEHAVIOUR where	storenumber = 889)
		group by
			VFSegmentID
	)F	
	on A.VFSegmentID = F.VFSegmentID
	left outer join 
	(
		select
			distinct VFSegmentID,
			count (distinct mergedcustomerid) 'Online'
		from
			#SHOPPINGBEHAVIOUR
		where
			storenumber = 889
			and mergedcustomerid not in (select	distinct mergedcustomerid from #SHOPPINGBEHAVIOUR where	storenumber != 889)
		group by
			VFSegmentID
	)G
	on A.VFSegmentID = G.VFSegmentID
	left outer join 	
	(		
		select
			distinct VFSegmentID,
			count (distinct mergedcustomerid) 'Store & Online'
		from
			#SHOPPINGBEHAVIOUR
		where
			storenumber != 889
			and mergedcustomerid in (select	distinct mergedcustomerid from #SHOPPINGBEHAVIOUR where	storenumber = 889)
		group by
			VFSegmentID
	)H
	on A.VFSegmentID = H.VFSegmentID
	left outer join 	
	(
		select
			distinct VFSegmentID,
			count (distinct mergedcustomerid) 'NewGen'
		from
			#SHOPPINGBEHAVIOUR
		where
			transactiontypeid = 1
			and platformid in (287,288,289,291)
		group by
			VFSegmentID
	)I	
	on A.VFSegmentID = I.VFSegmentID
	left outer join 	
	(
		select
			distinct VFSegmentID,
			count (distinct mergedcustomerid) 'Physical'
		from
			#PHYSSEG
		where
			mergedcustomerid not in (select distinct mergedcustomerid from #DIGISEG)
		group by
			VFSegmentID
	)J			
	on A.VFSegmentID = J.VFSegmentID
	left outer join 	
	(
		select
			distinct VFSegmentID,
			count (distinct mergedcustomerid) 'Digital'
		from
			#DIGISEG
		where
			mergedcustomerid not in (select distinct mergedcustomerid from #PHYSSEG)
		group by
			VFSegmentID
	)K		
	on A.VFSegmentID = K.VFSegmentID
	left outer join 
	(	
		select
			distinct d.VFSegmentID,
			count (distinct d.mergedcustomerid) 'Physical & Digital'
		from
			#DIGISEG d (nolock)
			inner join #PHYSSEG nd (nolock) on d.mergedcustomerid = nd.mergedcustomerid
		group by
			d.VFSegmentID
	)L
	on A.VFSegmentID = L.VFSegmentID
	left outer join 	
	(
		select
			distinct VFSegmentID,
			count (distinct mergedcustomerid) 'Mint'
		from
			#SHOPPINGBEHAVIOUR
		where
			transactiontypeid = 1
			and productclassid in (1,5)			
			and mergedcustomerid not in (select distinct mergedcustomerid from #SHOPPINGBEHAVIOUR where transactiontypeid = 1 and productclassid = 2)
		group by
			VFSegmentID
	)M	
	on A.VFSegmentID = M.VFSegmentID
	left outer join 		
	(	
		select
			distinct VFSegmentID,
			count (distinct mergedcustomerid) 'Preowned'
		from
			#SHOPPINGBEHAVIOUR
		where
			transactiontypeid = 1
			and productclassid = 2		
			and mergedcustomerid not in (select distinct mergedcustomerid from #SHOPPINGBEHAVIOUR where transactiontypeid = 1 and productclassid in (1,5))
		group by
			VFSegmentID
	)N
	on A.VFSegmentID = N.VFSegmentID
	left outer join
	(	
		select
			distinct m.VFSegmentID,
			count (distinct m.mergedcustomerid) 'Mint & Preowned'
		from
			#SHOPPINGBEHAVIOUR M
			inner join (select distinct mergedcustomerid from #SHOPPINGBEHAVIOUR where transactiontypeid = 1 and productclassid = 2) P on m.mergedcustomerid = p.mergedcustomerid
		where
			transactiontypeid = 1
			and productclassid in (1,5)	
		group by
			m.VFSegmentID
	)O
	on A.VFSegmentID = O.VFSegmentID
	left outer join	
	(
		select
			distinct VFSegmentID,
			count (distinct mergedcustomerid) 'Bought HW'
		from
			#SHOPPINGBEHAVIOUR
		where
			transactiontypeid = 1
			and productsubclassid = 2
		group by
			VFSegmentID
	)P
	on A.VFSegmentID = P.VFSegmentID
	left outer join		
	(
		select
			distinct VFSegmentID,
			count (distinct mergedcustomerid) 'Bought SW'
		from
			#SHOPPINGBEHAVIOUR
		where
			transactiontypeid = 1
			and productsubclassid = 1
		group by
			VFSegmentID
	)Q	
	on A.VFSegmentID = Q.VFSegmentID
	left outer join		
	(
		select
			distinct VFSegmentID,
			count (distinct mergedcustomerid) 'Bought ACC'
		from
			#SHOPPINGBEHAVIOUR
		where
			transactiontypeid = 1
			and productsubclassid = 3
		group by
			VFSegmentID
	)R
	on A.VFSegmentID = R.VFSegmentID
	left outer join	
	(
		select
			distinct VFSegmentID,
			count (distinct mergedcustomerid) 'Bought Exclusives'
		from
			#SHOPPINGBEHAVIOUR
		where
			transactiontypeid = 1
			and (title like '%Excl%' or title like '%Only at GAME%')
			and releasedate > cast(dateadd(month,-18,getdate()) as date)
			and title not like 'NRR%'
			and title not like 'DEP%'
		group by
			VFSegmentID
	)S
	on A.VFSegmentID = S.VFSegmentID
	left outer join	
	(
		select
			distinct VFSegmentID,
			count (distinct mergedcustomerid) 'Bought Tech'
		from
			#SHOPPINGBEHAVIOUR
		where
			transactiontypeid = 1
			and platformId in (307,303,296,295,294,293,286,285,284,283,267,231,221,216,215,210,203,196,194,193,190,150) 
			and productSubClassId in (3,103,2)
		group by
			VFSegmentID
	)T	
	on A.VFSegmentID = T.VFSegmentID
	left outer join	----------------------------HERE
	(
		select
			distinct VFSegmentID,
			count (distinct mergedcustomerid) 'Bought Board Games'
		from
			#SHOPPINGBEHAVIOUR
		where
			transactiontypeid = 1
			and genreid in (72,128,127,3) 
			and platformId in (274,282,292)
		group by
			VFSegmentID
	)U
	on A.VFSegmentID = U.VFSegmentID
	left outer join	----------------------------HERE
	(
		select
			distinct VFSegmentID,
			count (distinct mergedcustomerid) 'Bought Clothing'
		from
			#SHOPPINGBEHAVIOUR
		where
			transactiontypeid = 1
			and productSubClassId = 102
		group by
			VFSegmentID
	)U2
	on A.VFSegmentID = U2.VFSegmentID
	left outer join	----------------------------HERE
	(
		select
			distinct VFSegmentID,
			count (distinct mergedcustomerid) 'Bought TCG'
		from
			#SHOPPINGBEHAVIOUR
		where
			transactiontypeid = 1
			and departmentId = 425 
			and subDepartmentId in (150,210,270)
		group by
			VFSegmentID
	)U3
	on A.VFSegmentID = U3.VFSegmentID
	left outer join	----------------------------HERE
	(
		select
			distinct VFSegmentID,
			count (distinct mergedcustomerid) 'Bought Toys & Collectables'
		from
			#SHOPPINGBEHAVIOUR
		where
			transactiontypeid = 1
			and productSubClassId = 105
		group by
			VFSegmentID
	)U4
	on A.VFSegmentID = U4.VFSegmentID
	left outer join	
	(
		select
			distinct VFSegmentID,
			count (distinct mergedcustomerid) 'Bought PEGI 16 or Under'
		from
			#SHOPPINGBEHAVIOUR
		where
			transactiontypeid = 1
			and productsubclassid = 1 
			and pegiRatingId in (1,3,4,5,6,8,9,10,12,13,14,16,18,19,20,21,23,24,26,28,29,30,31,33,35,37,38,39,40,41,42,43,46)
		group by
			VFSegmentID
	)V
	on A.VFSegmentID = V.VFSegmentID
	left outer join		
	(
		select
			distinct VFSegmentID,
			count (distinct v.mergedcustomerid) 'Opened CRM Emails',
			count (CampaignId) 'Total Emails Opened' 
		from
			#VFSEGMENT_TEST2 v
			inner join responsysOpened ro (nolock) on v.mergedcustomerid = ro.CustomerId
		where
			eventCapturedDate > cast(dateadd(month,-18,getdate()) as date)
			and customerid not like 'X%'
			and customerid not like '%?%'
			and customerid not like 'cc%'
			and customerid not like '%PROOF%'
			and customerid <> ''
			and customerid <> '111111111111'
		group by
			VFSegmentID
	)W
	on A.VFSegmentID = W.VFSegmentID
	left outer join		
	(
		select
			distinct VFSegmentID,
			count (distinct mergedcustomerid) 'Bought in L12M',
			count (distinct id) 'Trans in L12M'
		from
			#SHOPPINGBEHAVIOUR
		where
			transactiondate > cast(dateadd(month,-12,getdate()) as date)
			and transactiontypeid = 1
		group by
			VFSegmentID
	)X
	on A.VFSegmentID = X.VFSegmentID
	left outer join		
	(
		select
			distinct VFSegmentID,
			count (distinct mergedcustomerid) 'Bought in L9M'
		from
			#SHOPPINGBEHAVIOUR
		where
			transactiondate > cast(dateadd(month,-9,getdate()) as date)
			and transactiontypeid = 1
		group by
			VFSegmentID
	)Y
	on A.VFSegmentID = Y.VFSegmentID
	left outer join		
	(
		select
			distinct VFSegmentID,
			count (distinct mergedcustomerid) 'Bought in L6M'
		from
			#SHOPPINGBEHAVIOUR
		where
			transactiondate > cast(dateadd(month,-6,getdate()) as date)
			and transactiontypeid = 1
		group by
			VFSegmentID
	)Z
	on A.VFSegmentID = Z.VFSegmentID
	left outer join		
	(
		select
			distinct VFSegmentID,
			count (distinct mergedcustomerid) 'Bought in L3M'
		from
			#SHOPPINGBEHAVIOUR
		where
			transactiondate > cast(dateadd(month,-3,getdate()) as date)
			and transactiontypeid = 1
		group by
			VFSegmentID
	)AA
	on A.VFSegmentID = AA.VFSegmentID
	left outer join		
	(
		select
			distinct VFSegmentID,
			count (distinct mergedcustomerid) 'Bought in L1M'
		from
			#SHOPPINGBEHAVIOUR
		where
			transactiondate > cast(dateadd(month,-1,getdate()) as date)
			and transactiontypeid = 1
		group by
			VFSegmentID
	)AB
	on A.VFSegmentID = AB.VFSegmentID
	left outer join	
	(
		select
			distinct VFSegmentID,
			count (distinct mergedcustomerid) 'Bought in December',
			count (distinct id) 'Trans in December'
		from
			#SHOPPINGBEHAVIOUR
		where
			transactiondate > cast(dateadd(month,-12,getdate()) as date)
			and datepart(month,transactiondate) = 12
			and transactiontypeid = 1
		group by
			VFSegmentID
	)AC
	on A.VFSegmentID = AC.VFSegmentID
	left outer join	
	(
		select
			distinct VFSegmentID,
			count (distinct mergedcustomerid) 'Bought in Week 1'
		from
			#SHOPPINGBEHAVIOUR
		where
			transactiondate < dateadd(day,7,releasedate)
			and productclassid = 1
			and productsubclassid in (1,2)
			and transactiontypeid = 1
		group by
			VFSegmentID
	)AD
	on A.VFSegmentID = AD.VFSegmentID
	left outer join	
	(
		select
			distinct VFSegmentID,
			count (distinct mergedcustomerid) 'Paid with Cash'
		from
			#SHOPPINGBEHAVIOUR
		where
			storenumber not in (887,889)
			and cashPaymentAmount > 0
		group by
			VFSegmentID
	)AE
	on A.VFSegmentID = AE.VFSegmentID
	left outer join	
	(
		select
			distinct VFSegmentID,
			count (distinct mergedcustomerid) 'Paid with Card'
		from
			#SHOPPINGBEHAVIOUR
		where
			cardPaymentAmount > 0 
			or (storenumber = 889 and cashPaymentAmount > 0)
		group by
			VFSegmentID
	)AF
	on A.VFSegmentID = AF.VFSegmentID
	left outer join	
	(
		select
			distinct VFSegmentID,
			count (distinct mergedcustomerid) 'Paid with Gift Card'
		from
			#SHOPPINGBEHAVIOUR
		where
			giftcardPaymentAmount > 0
		group by
			VFSegmentID
	)AG
	on A.VFSegmentID = AG.VFSegmentID
	left outer join	
	(
		select
			*
		from
			(
				select
					case when label in ('13','14','15','16','17') then '13-17' else label end [AgeGrp],
					VFSegmentID,
					count (distinct x.mergedcustomerid) 'Cust'
				from
					#AGEBREAKDOWN x
					inner join agerange ar (nolock) on x.age = ar.age
				group by 
					case when label in ('13','14','15','16','17') then '13-17' else label end,
					VFSegmentID
			)SUMMARY
		PIVOT (sum(Cust) for [AgeGrp] in ([Under 13],[13-17],[18-25],[26-30],[31-35],[36-40],[41-45],[46-55],[56-65],[Over 65])) as PVTTable
	)AJ
	on A.VFSegmentID = AJ.VFSegmentID
	left outer join
	(
		select
			distinct VFSegmentID,
			sum (totalprice) 'SW_Spend'
		from
			#SHOPPINGBEHAVIOUR
		where
			transactiontypeid in (1,2,3,4)
			and productsubclassid = 1
		group by
			VFSegmentID
	)AK
	on A.VFSegmentID = AK.VFSegmentID
	left outer join
	(
		select
			distinct VFSegmentID,
			sum (totalprice) 'HW_Spend'
		from
			#SHOPPINGBEHAVIOUR
		where
			transactiontypeid in (1,2,3,4)
			and productsubclassid = 2
		group by
			VFSegmentID
	)AL
	on A.VFSegmentID = AL.VFSegmentID
	left outer join
	(
		select
			distinct VFSegmentID,
			sum (totalprice) 'ACC_Spend'
		from
			#SHOPPINGBEHAVIOUR
		where
			transactiontypeid in (1,2,3,4)
			and productsubclassid = 3
		group by
			VFSegmentID
	)AM
	on A.VFSegmentID = AM.VFSegmentID
	left outer join
	(
		select
			distinct VFSegmentID,
			sum (totalprice) 'Digital_Spend'
		from
			#SHOPPINGBEHAVIOUR
		where
			transactiontypeid in (1,2,3,4)
			and (productclassid = 5 
					or productsubclassid in (8,9) 
						or title like '%steam wallet%'
							or departmentid in (456,470))
			and sku not in (select sku from sku where departmentid = 470 and subdepartmentid = 50)
		group by
			VFSegmentID
	)AN
	on A.VFSegmentID = AN.VFSegmentID
	left outer join
	(
		select
			distinct VFSegmentID,
			sum (totalprice) 'PEGI16 or Under_Spend'
		from
			#SHOPPINGBEHAVIOUR
		where
			transactiontypeid in (1,2,3,4)
			and productsubclassid = 1 
			and pegiRatingId in (1,3,4,5,6,8,9,10,12,13,14,16,18,19,20,21,23,24,26,28,29,30,31,33,35,37,38,39,40,41,42,43,46)
		group by
			VFSegmentID
	)AP
	on A.VFSegmentID = AP.VFSegmentID
	left outer join
	(
		select
			distinct VFSegmentID,
			sum (totalprice) 'Tech_Spend'
		from
			#SHOPPINGBEHAVIOUR
		where
			transactiontypeid in (1,2,3,4)
			and platformId in (307,303,296,295,294,293,286,285,284,283,267,231,221,216,215,210,203,196,194,193,190,150) 
			and productSubClassId in (3,103,2)
		group by
			VFSegmentID
	)AQ
	on A.VFSegmentID = AQ.VFSegmentID
	left outer join	----------------------------HERE
	(
		select
			distinct VFSegmentID,
			sum (totalprice) 'Board Games_Spend'
		from
			#SHOPPINGBEHAVIOUR
		where
			transactiontypeid in (1,2,3,4)
			and genreid in (72,128,127,3) 
			and platformId in (274,282,292)
		group by
			VFSegmentID
	)AR
	on A.VFSegmentID = AR.VFSegmentID
	left outer join	----------------------------HERE
	(
		select
			distinct VFSegmentID,
			sum (totalprice) 'Clothing_Spend'
		from
			#SHOPPINGBEHAVIOUR
		where
			transactiontypeid in (1,2,3,4)
			and productSubClassId = 102
		group by
			VFSegmentID
	)AU
	on A.VFSegmentID = AU.VFSegmentID
	left outer join	----------------------------HERE
	(
		select
			distinct VFSegmentID,
			sum (totalprice) 'TCG_Spend'
		from
			#SHOPPINGBEHAVIOUR
		where
			transactiontypeid in (1,2,3,4)
			and departmentId = 425 
			and subDepartmentId in (150,210,270)
		group by
			VFSegmentID
	)AV
	on A.VFSegmentID = AV.VFSegmentID
	left outer join	----------------------------HERE
	(
		select
			distinct VFSegmentID,
			sum (totalprice) 'Toys & Collectables_Spend'
		from
			#SHOPPINGBEHAVIOUR
		where
			transactiontypeid in (1,2,3,4)
			and productSubClassId = 105
		group by
			VFSegmentID
	)AW
	on A.VFSegmentID = AW.VFSegmentID
order by
	A.VFSegmentID







