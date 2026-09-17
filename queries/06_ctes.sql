/*
  CTEs
*/

-- Above genre-average movies, rewritten with a CTE
WITH genre_avg AS (
	SELECT mg.genre_id, ROUND(AVG(r.average_rating), 2) AS per_genre_avg
	FROM movie_genres mg
	JOIN ratings r
		ON mg.tconst = r.tconst
	GROUP BY mg.genre_id
)
SELECT m.primary_title AS movie_title, g.genre_name AS genre, r.average_rating AS rating
FROM movies m
JOIN ratings r
	ON m.tconst = r.tconst
JOIN movie_genres mg
	ON mg.tconst = m.tconst
JOIN genres g
	ON g.genre_id = mg.genre_id
JOIN genre_avg ga
	ON ga.genre_id = g.genre_id
WHERE r.average_rating > ga.per_genre_avg
ORDER BY rating DESC;

-- Multi-step CTE: prolific AND highly-rated actors
WITH actors_movie AS (
	-- how many movies has each actor appeared in (10+ only)
	SELECT a1.nconst, a1.primary_name, COUNT(a1.nconst) AS am_count
	FROM actors a1
	JOIN movie_actors ma1
		ON ma1.nconst = a1.nconst
	GROUP BY a1.nconst, a1.primary_name
	HAVING COUNT(a1.nconst) > 10
),
actors_rating AS (
	-- average rating across each actor's movies
	SELECT ma2.nconst, ROUND(AVG(r1.average_rating), 2) AS avg_actor_rating
	FROM ratings r1
	JOIN movie_actors ma2
		ON ma2.tconst = r1.tconst
	GROUP BY ma2.nconst
)
SELECT am.primary_name AS actors_name, am.am_count AS movie_count, ar.avg_actor_rating
FROM actors_rating ar
JOIN actors_movie am
	ON ar.nconst = am.nconst
WHERE ar.avg_actor_rating > (
	SELECT AVG(r3.average_rating)
	FROM ratings r3
)
ORDER BY ar.avg_actor_rating DESC, movie_count DESC;
