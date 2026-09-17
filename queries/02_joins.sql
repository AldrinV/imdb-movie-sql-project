/*
  JOIN STATEMENTS
*/

-- Movie + genre list (10 movies, all their genres)
SELECT m.primary_title, g.genre_name
FROM movies m
JOIN movie_genres mg
	ON mg.tconst = m.tconst
JOIN genres g
	ON g.genre_id = mg.genre_id
WHERE m.tconst IN (SELECT tconst FROM movies LIMIT 10)
ORDER BY m.primary_title;

-- Actor filmography (random actor)
SELECT a.primary_name AS actor_name,
	m.primary_title AS movie_title,
	m.start_year AS year_released
FROM movie_actors ma
LEFT JOIN actors a
	ON ma.nconst = a.nconst
LEFT JOIN movies m
	ON m.tconst = ma.tconst
WHERE ma.nconst = (SELECT nconst FROM movie_actors ORDER BY RANDOM() LIMIT 1);

-- Top 50 actors who appeared most in Horror movies
SELECT a.nconst, a.primary_name, COUNT(*) AS appeared_in_horror
FROM movies m
LEFT JOIN movie_genres mg
	ON m.tconst = mg.tconst
LEFT JOIN genres g
	ON g.genre_id = mg.genre_id
LEFT JOIN movie_actors ma
	ON ma.tconst = m.tconst
LEFT JOIN actors a
	ON a.nconst = ma.nconst
WHERE g.genre_name = 'Horror'
GROUP BY a.nconst, a.primary_name
ORDER BY appeared_in_horror DESC
LIMIT 50;

-- Full cast of a specific movie ("3 Idiots")
SELECT a.primary_name AS actor_name, ma.characters
FROM movies m
LEFT JOIN movie_actors ma
	ON ma.tconst = m.tconst
LEFT JOIN actors a
	ON a.nconst = ma.nconst
WHERE m.primary_title = '3 Idiots'
ORDER BY ma.ordering;

-- Co-stars: pairs of actors who appeared in the same movie together
WITH co_stars AS (
	SELECT ma1.tconst, ma1.nconst AS actor1, ma2.nconst AS actor2
	FROM movie_actors ma1
	JOIN movie_actors ma2
		ON ma1.tconst = ma2.tconst
	WHERE ma1.nconst > ma2.nconst
),
actors_name AS (
	SELECT m.primary_title,
		a1.primary_name AS actor_1,
		a2.primary_name AS actor_2
	FROM co_stars c
	JOIN movies m
		ON m.tconst = c.tconst
	JOIN actors a1
		ON a1.nconst = c.actor1
	JOIN actors a2
		ON a2.nconst = c.actor2
	LIMIT 20
)
SELECT *
FROM actors_name;
