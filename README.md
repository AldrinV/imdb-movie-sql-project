# IMDb Movie Library — SQL Practice Project

A PostgreSQL project built from IMDb's public dataset, covering database design,
ETL/import from raw TSV files, and progressively advanced SQL — from basic filtering
through JOINs, aggregates, subqueries, window functions, and CTEs.

## What this project covers

- Designing a normalized relational schema from messy, denormalized source data
- Importing large TSV files into PostgreSQL staging tables, then transforming into a clean schema
- Debugging real-world data issues: encoding mismatches, ambiguous columns, foreign key violations, slow queries
- Writing SQL across increasing levels of complexity: filtering → JOINs → aggregates → subqueries → window functions → CTEs

## Dataset

Source: [IMDb public datasets](https://datasets.imdb.com/) — `title.basics`, `name.basics`,
`title.principals`, `title.ratings`. Filtered to movies released 2000 onward for a manageable scope.

## Schema

Six tables, normalized from IMDb's raw comma-separated genre lists and unfiltered principal credits:

- `movies` — core movie info (title, year, runtime)
- `genres` — distinct genre list
- `movie_genres` — join table (movies can have multiple genres)
- `actors` — actor/actress names and info
- `movie_actors` — join table (cast per movie, filtered to actor/actress roles only)
- `ratings` — average rating and vote count per movie
See [`schema/imdb_schema.sql`](schema/imdb_schema.sql) for the full staging → transform pipeline.

## Queries

Organized by difficulty, matching the order they were built in:

| File | Covers |
|---|---|
| [`queries/01_basic.sql`](queries/01_basic.sql) | Filtering, sorting, LIMIT, DISTINCT |
| [`queries/02_joins.sql`](queries/02_joins.sql) | INNER JOIN, LEFT JOIN, self-joins |
| [`queries/03_aggregates.sql`](queries/03_aggregates.sql) | GROUP BY, HAVING, aggregate functions |
| [`queries/04_subqueries.sql`](queries/04_subqueries.sql) | Scalar, correlated, and EXISTS/NOT EXISTS subqueries |
| [`queries/05_window_functions.sql`](queries/05_window_functions.sql) | RANK, ROW_NUMBER, NTILE, running totals |
| [`queries/06_ctes.sql`](queries/06_ctes.sql) | WITH clauses, multi-step CTEs |

## Challenges & lessons learned

Real issues hit while building this, and how they were resolved:

- **Encoding mismatch on import** — `title.principals.tsv` contains UTF-8 characters that
  conflicted with psql's default WIN1252 client encoding on Windows. Fixed with
  `SET client_encoding TO 'UTF8';` before import.
- **Ambiguous column reference** — splitting comma-separated genres with `unnest()` created
  a column alias that collided with an actual table column name, causing PostgreSQL to reject
  the join. Fixed by giving the unnested value a distinct alias.
- **Foreign key violations on import** — some actor IDs referenced in `title.principals`
  had no matching record in `name.basics`, so joining strictly (`INNER JOIN` instead of
  filtering with `NOT IN`) was both more correct and dramatically faster.
- **Slow correlated subquery** — a per-row correlated subquery recalculating genre averages
  took minutes to run. Rewritten as a CTE that precomputes the average once per genre,
  then joins — turning an O(n²)-ish operation into a single-pass calculation.
- **`INNER JOIN` + `IS NULL` is always a no-op** — learned the hard way that finding
  "rows with no match" requires a `LEFT JOIN`, not a plain `JOIN`.

## Tools used

- PostgreSQL
- pgAdmin / psql

## Setup

1. Download the IMDb datasets from [datasets.imdb.com](https://datasets.imdb.com/)
2. Run [`schema/imdb_schema.sql`](schema/imdb_schema.sql) to create staging tables,
   import the TSVs via `\copy`, then run the transform queries to populate the final schema
3. Explore the queries in the `queries/` folder, organized by topic
