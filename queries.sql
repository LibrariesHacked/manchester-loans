select
	'Manchester' as "Local authority",
	'2025-07-17' as "Count date",
	lsoa as "Area code",
	count(*) as "Members"
from loans
where lsoa in (
select lsoa21cd from lsoa_lookup where lad24nm = 'Manchester'
)
group by lsoa;


select 
    distinct on (l.ward)
    l.ward,
    l.author, 
    count(*) as loan_count
from loans l
join lsoa_lookup ls 
on ls.wd24cd = l.ward
where l.ward is not null
and ls.lad24nm = 'Manchester'
and l.author is not null
group by l.ward, l.author
order by l.ward, loan_count desc;