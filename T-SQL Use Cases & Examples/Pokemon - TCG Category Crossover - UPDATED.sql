use insight
go


if object_id ('tempdb..#PKMTCG') is not NULL
	drop table #PKMTCG
select
	*
into
	#PKMTCG
from
	sku (nolock)
where
	departmentid = 425
	and subdepartmentid = 210
	and marketplacevendorid = 0001
	and (title like '%PKM%'
		or title like '%pokemon%'
		or title like '%pokémon%')
	and title not like '%plush%'
	and title not like '%plsh%'
	and title not like '%fig set%'
	and title not like '%bt fig%'
	and title not like '%eb fig%'
	and title not like '%ft fg%'
	and title not like '%fig ast%'
	and title not like 'DNU%'
	and sku not in ('814106','814137','814139','814155','814157','814149')
go


if object_id ('tempdb..#ALLTCG') is not NULL
	drop table #ALLTCG
select
	*
into
	#ALLTCG
from
	sku s (nolock)
where
	departmentid = 425
	and subdepartmentid in (150,210,270)
	and marketplacevendorid = 0001
	and sku not in 
	('773233','773291','773298','773314','773519','773525','773549','773550'
	,'773594','773621','773665','774232','810245','810246','810247','810248'
	,'810249','810250','810251','810252','810253','810254','810255','810256'
	,'810257','810258','810259','810260','810261','810262','810263','810264'
	,'810265','810266','810267','810268','810269','810270','810271','810272'
	,'810273','810274','810275','810276','810277','810278','810279','810280'
	,'810281','810282','810283','810285','810286','810287','810288','810289'
	,'810290','810291','810292','810293','810294','545081','505417','402944'
	,'457189','566195','482346','693132','505416','537408','702720','674214'
	,'481895')
	and sku not in (select sku from #PKMTCG)
go


if object_id ('tempdb..#TARGETCUST') is not NULL
drop table #TARGETCUST
select
	distinct emc.mergedcustomerid,
	min(transactiondate) 'minTRGTrans'
into 
	#TARGETCUST
from 
	expanededmergedcustomerids emc (nolock)
	inner join transactions tc (nolock) on emc.insightcustomerid = tc.insightcustomerid
	inner join transactionitem ti (nolock) on tc.id = ti.transactionid
	inner join #PKMTCG s (nolock) on ti.sku = s.sku
where
	tc.transactiondate >= cast(dateadd(month,-18,getdate()) as date)
	and ti.transactiontypeid = 1
	and tc.storenumber != 9999
	and emc.mergedcustomerid not in (select distinct mergedcustomerid from insighttemp..GK_CUSTOMER_BLACKLIST)
	and emc.mergedcustomerid not in (select distinct mergedcustomerid from insighttemp..GK_B2B_suppression)
group by
	emc.mergedcustomerid
go


if object_id ('tempdb..#BASE') is not NULL
	drop table #BASE
select
	distinct emc.mergedcustomerid,
	min(transactiondate) 'minTRGTrans'
into
	#BASE
from
	expanededmergedcustomerids emc (nolock)
	inner join transactions tc (nolock) on emc.insightcustomerid = tc.insightcustomerid
	inner join transactionitem ti (nolock) on tc.id = ti.transactionid
	inner join #ALLTCG s (nolock) on ti.sku = s.sku
where
	tc.transactiondate >= cast(dateadd(month,-18,getdate()) as date)
	and ti.transactiontypeid = 1
	and tc.storenumber != 9999
	and emc.mergedcustomerid not in (select distinct mergedcustomerid from insighttemp..GK_CUSTOMER_BLACKLIST)
	and emc.mergedcustomerid not in (select distinct mergedcustomerid from insighttemp..GK_B2B_suppression)
group by
	emc.mergedcustomerid
go



select
	count(distinct mergedcustomerid) 'Pokemon Only'
from
	#TARGETCUST
where
	mergedcustomerid not in (select mergedcustomerid from #BASE)


select
	count(distinct t.mergedcustomerid) 'Pokemon & Other TCG'
from
	#TARGETCUST t
	inner join #BASE b on t.mergedcustomerid = b.mergedcustomerid


select
	count(distinct mergedcustomerid) 'Other TCG Not Pokemon'
from
	#BASE
where
	mergedcustomerid not in (select mergedcustomerid from #TARGETCUST)