/*
  WINDOW FUNCTIONS
*/

-- Top 3 movies per genre, by rating
WITH genre_rank AS (
	SELECT mg.tconst, mg.genre_id,
		DENSE_RANK() OVER (PARTITION BY mg.genre_id ORDER BY r.average_rating DESC) AS ranking
	FROM ratings r
	JOIN movie_genres mg
		ON mg.tconst = r.tconst
)
SELECT m.primary_title AS movie_title, g.genre_name AS genre, gr.ranking AS ranking
FROM genre_rank gr
JOIN genres g
	ON g.genre_id = gr.genre_id
JOIN movies m
	ON m.tconst = gr.tconst
WHERE gr.ranking <= 3
ORDER BY g.genre_id, gr.ranking;

-- Running total of movies released per year
WITH movies_per_year AS (
	SELECT DISTINCT start_year, COUNT(start_year) OVER (PARTITION BY start_year) AS total_movies
	FROM movies
)
SELECT mpy.start_year, total_movies AS total_movies_year,
	SUM(total_movies) OVER (ORDER BY start_year) AS rolling_total
FROM movies_per_year mpy;

-- Actor movie count with rank
WITH total_movie_actor AS (
	SELECT a.nconst, a.primary_name, COUNT(ma.nconst) AS movie_count
	FROM actors a
	JOIN movie_actors ma
		ON ma.nconst = a.nconst
	GROUP BY a.nconst, a.primary_name
)
SELECT ta.primary_name, ta.movie_count,
	ROW_NUMBER() OVER (ORDER BY ta.movie_count DESC) AS ranking
FROM total_movie_actor ta;

-- Percentile ranking: movies in the top quartile by rating
WITH quartile AS (
	SELECT m.primary_title AS movie_title, r.average_rating AS movie_rating,
		NTILE(4) OVER (ORDER BY r.average_rating DESC) AS quartile_rank
	FROM movies m
	JOIN ratings r
		ON r.tconst = m.tconst
)
SELECT *
FROM quartile q
WHERE q.quartile_rank = 1;
