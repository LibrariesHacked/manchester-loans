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


-- select count of loans by postcode district
select
    distinct on (l.postcode_district),
    count(*) as loan_count
from loans l
group by l.postcode_district
order by l.postcode_district, loan_count desc;

-- select most popular author by postcode district
-- only include manchester postcode districts (starting with M and then a number)
select 
    distinct on (postcode_district)
    postcode_district,
    author, 
    count(*) as loan_count
from loans
where postcode_district is not null
and postcode_district ~ '^M[0-9]'
and author is not null
group by postcode_district, author  
having count(*) > 20
order by postcode_district, loan_count desc;

-- select most popular titles by postcode district
select 
    distinct on (postcode_district)
    postcode_district,
    title, 
    author, 
    count(*) as loan_count
from loans
where postcode_district is not null
and postcode_district ~ '^M[0-9]'
group by postcode_district, title, author
having count(*) > 100
order by postcode_district, loan_count desc;


-- select count of loans by ward
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
