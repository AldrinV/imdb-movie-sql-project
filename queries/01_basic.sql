/*
  BASIC SELECT QUERIES
*/

-- Top 10 Movies by rating
SELECT m.primary_title, r.average_rating, r.num_votes
FROM movies m
JOIN ratings r
	ON m.tconst = r.tconst
WHERE r.num_votes >= 10000
ORDER BY r.average_rating DESC, r.num_votes DESC
LIMIT 10;

-- Movies recently released (so far between 2025-2026)
SELECT *
FROM movies
WHERE start_year BETWEEN (EXTRACT(YEAR FROM CURRENT_DATE)::INTEGER - 1)
                      AND EXTRACT(YEAR FROM CURRENT_DATE)::INTEGER
ORDER BY start_year DESC;

-- Long movies (runtime over 150 minutes)
SELECT *
FROM movies
WHERE runtime_minutes > 150
ORDER BY runtime_minutes DESC;

-- Genre count
SELECT COUNT(*)
FROM genres;

-- Movies with missing ratings
SELECT m.primary_title AS movie_title
FROM movies m
LEFT JOIN ratings r
	ON m.tconst = r.tconst
WHERE r.tconst IS NULL;
