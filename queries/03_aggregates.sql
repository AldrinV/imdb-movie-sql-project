/*
  AGGREGATES & GROUP BY
*/

-- Average rating per genre (genres with 1000+ movies only)
SELECT g.genre_name AS genre, ROUND(AVG(r.average_rating), 2) AS genre_avg_rating
FROM genres g
JOIN movie_genres mg
	ON g.genre_id = mg.genre_id
JOIN ratings r
	ON r.tconst = mg.tconst
GROUP BY g.genre_name
HAVING COUNT(*) >= 1000
ORDER BY genre_avg_rating DESC;

-- Movie count per decade
SELECT CONCAT((start_year / 10 * 10), 's') AS decade, COUNT(start_year) AS movie_count
FROM movies
GROUP BY decade
ORDER BY decade;

-- Top 10 most prolific actors
SELECT a.primary_name AS actors_name, COUNT(m.primary_title) AS no_of_movies
FROM movies m
JOIN movie_actors ma
	ON m.tconst = ma.tconst
JOIN actors a
	ON a.nconst = ma.nconst
GROUP BY a.primary_name, a.nconst
ORDER BY no_of_movies DESC
LIMIT 10;

-- Genre popularity by total votes
SELECT genre_name AS genre, SUM(num_votes) AS total_num_votes
FROM genres g
JOIN movie_genres mg
	ON g.genre_id = mg.genre_id
JOIN ratings r
	ON r.tconst = mg.tconst
WHERE r.num_votes IS NOT NULL
GROUP BY g.genre_name
ORDER BY total_num_votes DESC;

-- Average runtime per genre
SELECT g.genre_name AS genre, ROUND(AVG(m.runtime_minutes), 2) AS average_runtime_minutes
FROM movies m
JOIN movie_genres mg
	ON m.tconst = mg.tconst
JOIN genres g
	ON g.genre_id = mg.genre_id
GROUP BY g.genre_name
ORDER BY average_runtime_minutes DESC;
