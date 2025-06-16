create database manchester_loans;

\c manchester_loans;

set client_encoding = 'UTF8';

-- branchItemBorrowed,title,author,collection,itemID,loanDate,loanTime,branchID,lsoa
create table loans_temp (
    branchItemBorrowed text not null,
    title text not null,
    author text,
    collection text not null,
    itemID text not null,
    loanDate text not null,
    loanTime text not null,
    branchID text not null,
    lsoa text not null
);


\copy loans_temp from 'manchester_loans.csv' with csv header;

-- LSOA21CD,LSOA21NM,LSOA21NMW,WD24CD,WD24NM,WD24NMW,LAD24CD,LAD24NM,LAD24NMW,ObjectId
create table lsoa_lookup (
    lsoa21cd character varying(9) not null,
    lsoa21nm text not null,
    lsoa21nmw text,
    wd24cd character varying(9) not null,
    wd24nm text not null,
    wd24nmw text,
    lad24cd character varying(9) not null,
    lad24nm text not null,
    lad24nmw text,
    objectid text
);

\copy lsoa_lookup from 'lsoa21_to_ward24.csv' with csv header;

create table loans (
    branchItemBorrowed text not null,
    title text not null,
    author text,
    collection text not null,
    itemID text not null,
    loanDateTime timestamp not null,
    branchID text not null,
    lsoa character varying(9),
    ward character varying(9)
);

insert into loans (branchItemBorrowed, title, author, collection, itemID, loanDateTime, branchID, lsoa, ward)
select 
    branchItemBorrowed, 
    title, 
    author, 
    collection, 
    itemID,
    -- loanDate AND loanTime are in 'DD/MM/YYYY HH:MM:SS' format
    to_timestamp(substring(loanDate from 1 for 10) || ' ' || substring(loanTime from 12 for 8), 'DD-MM-YYYY HH24:MI:SS') as loanDateTime,
    branchID,
    nullif(lsoa, 'Invalid Postcode') as lsoa,
    -- Join with lsoa_lookup to get the ward
    (select wd24cd from lsoa_lookup where lsoa_lookup.lsoa21cd = lsoa) as ward
from loans_temp;

-- Get the most popular single title for each ward
create table most_popular_titles (
    ward character varying(9) not null,
    title text not null,
    author text,
    loan_count integer not null
);
-- remember that aggregate function calls cannot be nested
insert into most_popular_titles (ward, title, author, loan_count)
select 
    distinct on (ward)
    ward,
    title,
    author, 
    count(*) as loan_count
from loans
group by ward, title, author
order by ward, loan_count desc;