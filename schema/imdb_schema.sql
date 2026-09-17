-- ============================================================
-- IMDB MOVIE LIBRARY PROJECT — SCHEMA + IMPORT SCRIPT
-- ============================================================
-- Strategy: load raw TSVs into staging tables (exact column
-- match, fast \copy), then transform/clean into normalized
-- final tables using SQL.
-- ============================================================


-- ============================================================
-- STEP 1: STAGING TABLES (mirror the raw TSV structure)
-- ============================================================

DROP TABLE IF EXISTS staging_title_basics;
CREATE TABLE staging_title_basics (
    tconst          TEXT,
    titleType       TEXT,
    primaryTitle    TEXT,
    originalTitle   TEXT,
    isAdult         TEXT,
    startYear       TEXT,
    endYear         TEXT,
    runtimeMinutes  TEXT,
    genres          TEXT
);

DROP TABLE IF EXISTS staging_name_basics;
CREATE TABLE staging_name_basics (
    nconst              TEXT,
    primaryName         TEXT,
    birthYear            TEXT,
    deathYear            TEXT,
    primaryProfession    TEXT,
    knownForTitles       TEXT
);

DROP TABLE IF EXISTS staging_title_principals;
CREATE TABLE staging_title_principals (
    tconst      TEXT,
    ordering    TEXT,
    nconst      TEXT,
    category    TEXT,
    job         TEXT,
    characters  TEXT
);

DROP TABLE IF EXISTS staging_title_ratings;
CREATE TABLE staging_title_ratings (
    tconst          TEXT,
    averageRating   TEXT,
    numVotes        TEXT
);


-- ============================================================
-- STEP 2: IMPORT — run these from psql (adjust paths to your own folder)
-- Note: use forward slashes even on Windows, and keep the files
-- somewhere Postgres' service account can read.
-- ============================================================

-- SET client_encoding TO 'UTF8';
-- \copy staging_title_basics FROM 'D:/Project/title.basics.tsv' WITH (FORMAT csv, DELIMITER E'\t', NULL '\N', HEADER true, QUOTE E'\b', ENCODING 'UTF8');
-- \copy staging_name_basics FROM 'D:/Project/name.basics.tsv' WITH (FORMAT csv, DELIMITER E'\t', NULL '\N', HEADER true, QUOTE E'\b', ENCODING 'UTF8');
-- \copy staging_title_principals FROM 'D:/Project/title.principals.tsv' WITH (FORMAT csv, DELIMITER E'\t', NULL '\N', HEADER true, QUOTE E'\b', ENCODING 'UTF8');
-- \copy staging_title_ratings FROM 'D:/Project/title.ratings.tsv' WITH (FORMAT csv, DELIMITER E'\t', NULL '\N', HEADER true, QUOTE E'\b', ENCODING 'UTF8');

-- NOTE: QUOTE E'\b' disables quote-character handling, since IMDb's
-- characters column contains literal quote marks like ["Self"] which
-- would otherwise confuse the CSV parser.
-- NOTE: ENCODING 'UTF8' avoids a WIN1252 encoding mismatch error that
-- can occur on Windows, since IMDb's files are UTF-8 but psql's
-- client encoding may default to WIN1252.


-- ============================================================
-- STEP 3: FINAL NORMALIZED SCHEMA
-- ============================================================

DROP TABLE IF EXISTS movie_actors;
DROP TABLE IF EXISTS movie_genres;
DROP TABLE IF EXISTS ratings;
DROP TABLE IF EXISTS genres;
DROP TABLE IF EXISTS actors;
DROP TABLE IF EXISTS movies;

CREATE TABLE movies (
    tconst          TEXT PRIMARY KEY,
    primary_title   TEXT NOT NULL,
    original_title  TEXT,
    start_year      INTEGER,
    runtime_minutes INTEGER,
    is_adult        BOOLEAN
);

CREATE TABLE genres (
    genre_id    SERIAL PRIMARY KEY,
    genre_name  TEXT UNIQUE NOT NULL
);

CREATE TABLE movie_genres (
    tconst    TEXT REFERENCES movies(tconst),
    genre_id  INTEGER REFERENCES genres(genre_id),
    PRIMARY KEY (tconst, genre_id)
);

CREATE TABLE actors (
    nconst        TEXT PRIMARY KEY,
    primary_name  TEXT NOT NULL,
    birth_year    INTEGER,
    death_year    INTEGER
);

CREATE TABLE movie_actors (
    tconst      TEXT REFERENCES movies(tconst),
    nconst      TEXT REFERENCES actors(nconst),
    category    TEXT,       -- 'actor' or 'actress'
    characters  TEXT,
    ordering    INTEGER,
    PRIMARY KEY (tconst, nconst, ordering)
);

CREATE TABLE ratings (
    tconst          TEXT PRIMARY KEY REFERENCES movies(tconst),
    average_rating  NUMERIC(3,1),
    num_votes       INTEGER
);


-- ============================================================
-- STEP 4: TRANSFORM STAGING -> FINAL TABLES
-- ============================================================

-- 4a. Movies — filter to actual movies only, cast types
INSERT INTO movies (tconst, primary_title, original_title, start_year, runtime_minutes, is_adult)
SELECT
    tconst,
    primaryTitle,
    originalTitle,
    NULLIF(startYear, '')::INTEGER,
    NULLIF(runtimeMinutes, '')::INTEGER,
    (isAdult = '1')
FROM staging_title_basics
WHERE titleType = 'movie'
  AND startYear ~ '^\d{4}$'          -- keep only rows with a valid year
  AND startYear::INTEGER >= 2000;    -- adjust/remove this filter to change scope

-- 4b. Genres — split comma-separated genres into distinct rows
INSERT INTO genres (genre_name)
SELECT DISTINCT genre
FROM staging_title_basics, unnest(string_to_array(genres, ',')) AS genre
WHERE genres IS NOT NULL
ON CONFLICT (genre_name) DO NOTHING;

-- 4c. Movie <-> Genre join table
INSERT INTO movie_genres (tconst, genre_id)
SELECT b.tconst, g.genre_id
FROM staging_title_basics b,
     unnest(string_to_array(b.genres, ',')) AS ug(genre_val)
JOIN genres g ON g.genre_name = ug.genre_val
WHERE b.tconst IN (SELECT tconst FROM movies);   -- only for movies we kept

-- 4d. Actors — only people who appear as actor/actress in our kept movies
INSERT INTO actors (nconst, primary_name, birth_year, death_year)
SELECT DISTINCT n.nconst, n.primaryName,
    NULLIF(n.birthYear, '')::INTEGER,
    NULLIF(n.deathYear, '')::INTEGER
FROM staging_name_basics n
WHERE n.nconst IN (
    SELECT p.nconst
    FROM staging_title_principals p
    WHERE p.category IN ('actor', 'actress')
      AND p.tconst IN (SELECT tconst FROM movies)
);

-- 4e. Movie <-> Actor join table
-- Starts from the small `movies` table and joins outward through
-- indexed columns — much faster than filtering staging_title_principals
-- directly, and the INNER JOIN to actors naturally excludes any
-- nconst that didn't make it into the actors table (avoiding FK
-- violations from missing name.basics records).
INSERT INTO movie_actors (tconst, nconst, category, characters, ordering)
SELECT p.tconst, p.nconst, p.category, p.characters,
    NULLIF(p.ordering, '')::INTEGER
FROM movies m
JOIN staging_title_principals p ON p.tconst = m.tconst
JOIN actors a ON a.nconst = p.nconst
WHERE p.category IN ('actor', 'actress');

-- 4f. Ratings — only for movies we kept
INSERT INTO ratings (tconst, average_rating, num_votes)
SELECT tconst,
    NULLIF(averageRating, '')::NUMERIC,
    NULLIF(numVotes, '')::INTEGER
FROM staging_title_ratings
WHERE tconst IN (SELECT tconst FROM movies);


-- ============================================================
-- STEP 5: HELPFUL INDEXES (speeds up joins on staging tables)
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_staging_principals_nconst ON staging_title_principals(nconst);
CREATE INDEX IF NOT EXISTS idx_staging_principals_tconst ON staging_title_principals(tconst);



