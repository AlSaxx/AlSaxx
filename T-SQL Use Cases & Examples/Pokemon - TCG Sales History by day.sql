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
	and attrib1_code = 210
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



if object_id ('tempdb..#PKMTCG_BSKT') is not NULL
	drop table #PKMTCG_BSKT
select 
	l.*
into
	#PKMTCG_BSKT
from	
	(
		select * from fct_sales_lines l (nolock)
		union all
		select * from fct_sales_lines_2018_Q2 (nolock)
		union all
		select * from fct_sales_lines_2018_Q1 (nolock)
		union all
		select * from fct_sales_lines_2017_Q4 (nolock)
		union all
		select * from fct_sales_lines_2017_Q3 (nolock)
		union all
		select * from fct_sales_lines_2017_Q2 (nolock)
		union all
		select * from fct_sales_lines_2017_Q1 (nolock)
		union all
		select * from fct_sales_lines_2016_Q4 (nolock)
		union all
		select * from fct_sales_lines_2016_Q3 (nolock)
		union all
		select * from fct_sales_lines_2016_Q2 (nolock)
		union all
		select * from fct_sales_lines_2016_Q1 (nolock)
		union all
		select * from fct_sales_lines_2015_Q4 (nolock)
		union all
		select * from fct_sales_lines_2015_Q3 (nolock)
		union all
		select * from fct_sales_lines_2015_Q2 (nolock)
	)l
	inner join #PKMTCG p on l.product_key = p.product_key
where
	l.sale_invc_type in ('DISC-SALE','REG-INV')
go



select
	distinct cast(week_commencing as date) 'week_commencing',
	sum(units) 'basketUnits',
	sum(grossVal) 'basketVal',
	count(distinct invoice_no) 'baskets',
	count(distinct case when grossVal >= 15 then invoice_no end) 'basketsOver£15'
from
	(
		select
			distinct l.invoice_no,
			d2.date_fld 'week_commencing',
			sum(l.sale_tot_qty) 'units',
			sum(l.sale_net_val + l.sale_tot_tax_val) 'grossVal'
		from
			#PKMTCG_BSKT l
			inner join dim_date d (nolock) on l.date_key = d.date_key
			inner join dim_store st (nolock) on l.store_key = st.store_key
			inner join #PKMTCG p on l.product_key = p.product_key
			inner join dim_date d2 (nolock) on d.week_st_date_key = d2.date_key
		where
			l.sale_invc_type in ('DISC-SALE','REG-INV')
			--and st.store_type in ('w','un','hs')
			and d.date_fld >= '2021-01-01'
		group by
			l.invoice_no,
			d2.date_fld
	)X
group by
	week_commencing
order by
	week_commencing

