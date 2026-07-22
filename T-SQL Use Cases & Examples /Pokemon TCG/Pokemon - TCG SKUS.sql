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
	and title not like 'LIC%'
	and title not like 'DNU%'
go


select
	*
from
	#PKMTCG
order by
	releaseDate desc



/*
use GAME_ARC
go


if object_id ('tempdb..#PKMTCG') is not NULL
	drop table #PKMTCG
select
	*
into
	#PKMTCG
from 
	dim_product (nolock)
where
	department_code = 'M'
	and class_code = 'TC'
	and subclass_code = 'OTC'
	and merchandise_flg = 'YES'
	and (product_description like '%Pokemon%'
		or product_description like '%Pokémon%'
		or product_description LIKE '%PKM%')	
	and product_description not like 'LIC%'
	and product_description not like '%plush%'
	and product_description not like '%plsh%'
	and product_description not like '%fig set%'
	and product_description not like '%bt fig%'
	and product_description not like '%eb fig%'
	and product_description not like '%ft fg%'
	and product_description not like '%fig ast%'
	and product_description not like 'LIC%'
	and product_description not like 'DNU%'
go
*/

