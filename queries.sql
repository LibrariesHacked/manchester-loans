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

