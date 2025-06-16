# Manchester loans

Scripts to analyse Manchester loans data alongside geospatial information.

The underlying data from Manchester libraries is not held in this repository as it is not an open data release and should be controlled by Manchester City Council.

## Creating the database

To create the database, run the following command:

```bash
"psql.exe" --set=sslmode=require -f load_db.sql -h host -p 5432 -U username postgres
```

Replace `host`, `username` and `password` with the appropriate values for your PostgreSQL instance.
