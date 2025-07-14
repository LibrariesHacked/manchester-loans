create database manchester_loans;

\c manchester_loans;

set client_encoding = 'UTF8';

-- Import the loans data from Manchester Libraries
create table loans_temp (
    branchItemBorrowed text not null,
    title text not null,
    author text,
    collection text not null,
    itemID text not null,
    loanDate text not null,
    loanTime text not null,
    branchID text not null,
    lsoa text not null,
    anonymisedPostCodes text not null
);
\copy loans_temp from 'manchester_loans.csv' with csv header;

-- We need an LSOA lookup table to provide latest Wards and LADs
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
-- Add indexes
create index idx_lsoa_lookup_lsoa21cd on lsoa_lookup (lsoa21cd);
create index idx_lsoa_lookup_wd24cd on lsoa_lookup (wd24cd);

-- We need a mapping from LSOA11 to LSOA21 which is the best fit (not all lsoa21 codes will be there)
-- ObjectId,LSOA11CD,LSOA11NM,LSOA21CD,LSOA21NM,LAD22CD,LAD22NM,LAD22NMW
create table lsoa11_to_lsoa21_bestfit (
    objectid text not null,
    lsoa11cd character varying(9) not null,
    lsoa11nm text not null,
    lsoa21cd character varying(9) not null,
    lsoa21nm text not null,
    lad22cd character varying(9) not null,
    lad22nm text not null,
    lad22nmw text
);
\copy lsoa11_to_lsoa21_bestfit from 'lsoa11_to_lsoa21_bestfit.csv' with csv header;
-- Add indexes
create index idx_lsoa11_to_lsoa21_bestfit_lsoa11cd on lsoa11_to_lsoa21_bestfit (lsoa11cd);
create index idx_lsoa11_to_lsoa21_bestfit_lsoa21cd on lsoa11_to_lsoa21_bestfit (lsoa21cd);

-- We need a mapping from LSOA11 to LSOA21 which is exact (it will include some duplicate matches)
-- LSOA11CD,LSOA11NM,LSOA21CD,LSOA21NM,CHGIND,LAD22CD,LAD22NM,LAD22NMW,ObjectId
create table lsoa11_to_lsoa21_exact (
    lsoa11cd character varying(9) not null,
    lsoa11nm text not null,
    lsoa21cd character varying(9) not null,
    lsoa21nm text not null,
    chgind character varying(1) not null,
    lad22cd character varying(9) not null,
    lad22nm text not null,
    lad22nmw text,
    objectid text
);
\copy lsoa11_to_lsoa21_exact from 'lsoa11_to_lsoa21_exact.csv' with csv header;
-- Add indexes
create index idx_lsoa11_to_lsoa21_exact_lsoa11cd on lsoa11_to_lsoa21_exact (lsoa11cd);
create index idx_lsoa11_to_lsoa21_exact_lsoa21cd on lsoa11_to_lsoa21_exact (lsoa21cd);

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
    -- Choose a matching lsoa21 code - randomly select one if multiple to ensure a good distribution
    (select l.lsoa21cd from lsoa11_to_lsoa21_exact l where l.lsoa11cd = lsoa order by random() limit 1) as lsoa,
    -- Join with lsoa_lookup to get the ward
    (select wd24cd from lsoa_lookup where lsoa_lookup.lsoa21cd = lsoa) as ward
from loans_temp;

-- Add indexes
create index idx_loans_lsoa on loans (lsoa);
create index idx_loans_ward on loans (ward);

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
where ward is not null
group by ward, title, author
order by ward, loan_count desc;