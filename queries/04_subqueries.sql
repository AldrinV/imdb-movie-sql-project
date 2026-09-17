/*
  SUBQUERIES
*/

-- Above-average movies (higher than the overall average rating)
SELECT m.primary_title AS movie_title, r.average_rating AS movie_rating
FROM movies m
JOIN ratings r
	ON m.tconst = r.tconst
WHERE r.average_rating > (SELECT AVG(average_rating) FROM ratings)
ORDER BY movie_rating DESC;

-- Above genre-average (movies rated higher than their own genre's average)
SELECT m.primary_title AS movie_title, g.genre_name AS genre, r.average_rating AS movie_rating
FROM movies m
JOIN ratings r
	ON m.tconst = r.tconst
JOIN movie_genres mg
	ON mg.tconst = m.tconst
JOIN genres g
	ON g.genre_id = mg.genre_id
WHERE r.average_rating > (
	SELECT AVG(r2.average_rating)
	FROM ratings r2
	JOIN movie_genres mg2
		ON mg2.tconst = r2.tconst
	WHERE mg2.genre_id = g.genre_id
);

-- Actors who appeared in only one movie
SELECT a.primary_name AS actor_name, m.primary_title AS movie_title
FROM movie_actors ma
JOIN actors a
	ON a.nconst = ma.nconst
JOIN movies m
	ON m.tconst = ma.tconst
WHERE ma.nconst IN (
	SELECT nconst
	FROM movie_actors
	GROUP BY nconst
	HAVING COUNT(*) = 1
);

-- Genres with no low-rated movies (every movie in the genre rated above 7.0)
SELECT g.genre_name AS genre
FROM genres g
WHERE NOT EXISTS (
	SELECT 1
	FROM movie_genres mg1
	JOIN ratings r1
		ON r1.tconst = mg1.tconst
	WHERE mg1.genre_id = g.genre_id
		AND r1.average_rating < 7
);
