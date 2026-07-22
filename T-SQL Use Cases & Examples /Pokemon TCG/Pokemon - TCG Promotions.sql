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
	(
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
	and product_description not like 'DNU%'
	and source_product_code not in ('814106','814137','814139','814155','814157','814149')
	)
	or source_product_code = '816293'
go


if object_id ('tempdb..#Koraidon') is not NULL
	drop table #Koraidon
select
	*
into
	#Koraidon
from
	dim_product (nolock)
where
	source_product_code = '827952' -- Koraidon Oversized Card 31Mar2023
go

-------------------------------------------------------------------------------------------
-- OS Koraidon

select
	cast(d.DATE_FLD as date) Date,
	sum(l.sale_tot_qty) 'Koraidon_Units'
from
	fct_sales_lines l (nolock)
	inner join #Koraidon p on l.product_key = p.product_key
	inner join dim_date d (nolock) on l.date_key = d.date_key
where
	d.date_fld >= '2023-03-31'
	and d.date_fld < dateadd(dd,30,'2023-03-31')
	and l.sale_invc_type in ('DISC-SALE','REG-INV')
group by cast(d.DATE_FLD as date)
go

select
	sum(l.sale_tot_qty) 'Koraidon_Units'
from
	fct_sales_lines l (nolock)
	inner join #Koraidon p on l.product_key = p.product_key
	inner join dim_date d (nolock) on l.date_key = d.date_key
where
	d.date_fld >= '2023-03-31'
	and l.sale_invc_type in ('DISC-SALE','REG-INV')
go

select
	count(distinct x.invoice_no) 'Koraidon_BSKTs',
	sum(l.sale_tot_qty) 'units',
	sum(l.sale_net_val + l.sale_tot_tax_val) 'grossval'
from
	(
		select
			distinct l.invoice_no
		from
			fct_sales_lines l (nolock)
			inner join #Koraidon p on l.product_key = p.product_key
			inner join dim_date d (nolock) on l.date_key = d.date_key
		where
			d.date_fld >= '2023-03-31' and d.date_fld < dateadd(dd,30,'2023-03-31')
			and l.sale_invc_type in ('DISC-SALE','REG-INV')
	)X
	inner join fct_sales_lines l (nolock) on x.invoice_no = l.invoice_no
	inner join dim_product p (nolock) on l.product_code = p.product_code
where
	p.subclass_code not in ('XSS','OOT','LOY','XNI','OPP')
	and p.merchandise_flg = 'YES'
	and l.sale_invc_type in ('DISC-SALE','REG-INV')
	and p.product_key not in (select product_key from #Koraidon)
go


select
	top 10 p.product_code,
	p.product_description,
	sum(l.sale_tot_qty) 'units'
from
	(
		select
			distinct l.invoice_no
		from
			fct_sales_lines l (nolock)
			inner join #Koraidon p on l.product_key = p.product_key
			inner join dim_date d (nolock) on l.date_key = d.date_key
		where
			d.date_fld >= '2023-03-31'and d.date_fld < dateadd(dd,30,'2023-03-31')
			and l.sale_invc_type in ('DISC-SALE','REG-INV')
	)X
	inner join fct_sales_lines l (nolock) on x.invoice_no = l.invoice_no
	inner join dim_product p (nolock) on l.product_code = p.product_code
where
	p.subclass_code not in ('XSS','OOT','LOY','XNI','OPP')
	and p.merchandise_flg = 'YES'
	and l.sale_invc_type in ('DISC-SALE','REG-INV')
	and p.product_key not in (select product_key from #Koraidon)
group by
	p.product_code,
	p.product_description 
order by
	sum(l.sale_tot_qty) desc
go