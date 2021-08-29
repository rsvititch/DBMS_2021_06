-- 1. Создать индекс к какой-либо из таблиц вашей БД. Прислать текстом результат команды explain, в которой используется данный индекс
CREATE INDEX MOVIES_INDEX_MOVIEID ON MOVIES(MOVIE_ID);

EXPLAIN (ANALYZE)
SELECT *
FROM MOVIES
WHERE MOVIE_ID = 1;
    --результат:
    -- Index Scan using movies_index_movieid on movies  (cost=0.28..8.29 rows=1 width=172) (actual time=0.032..0.034 rows=1 loops=1)
    -- Index Cond: (movie_id = 1)
    -- Planning Time: 0.443 ms
    -- Execution Time: 0.077 ms
-- 2. Реализовать индекс для полнотекстового поиска
ALTER TABLE MOVIES ADD COLUMN TEXT_TS
TSVECTOR;


UPDATE MOVIES
SET TEXT_TS = TO_TSVECTOR(NAME_ENG || ANNOTATION);


CREATE INDEX MOVIES_INDEX_ANNOTATION ON MOVIES USING GIN (TEXT_TS);

EXPLAIN (ANALYZE,
         COSTS OFF)
SELECT *
FROM MOVIES
WHERE TEXT_TS @@ TO_TSQUERY('drama');
    -- результат:
    -- Bitmap Heap Scan on movies (actual time=0.070..0.221 rows=106 loops=1)
    -- Recheck Cond: (text_ts @@ to_tsquery('drama'::text))
    -- Bitmap Index Scan on movies_index_annotation (actual time=0.061..0.061 rows=106 loops=1)
    -- Index Cond: (text_ts @@ to_tsquery('drama'::text))
    -- Planning Time: 0.754 ms
    -- Execution Time: 0.314 ms
EXPLAIN (ANALYZE,
         COSTS OFF)
SELECT *
FROM MOVIES
WHERE ANNOTATION ILIKE '%drama%';
    -- результат:
    -- Seq Scan on movies (actual time=0.010..1.590 rows=106 loops=1)
    -- Planning Time: 0.194 ms
    -- Execution Time: 1.609 ms
    -- получается что текстовый поиск с инжексом gin работает почти в 5 раз быстрее чем SEQUENCE SCAN
-- 3. Реализовать индекс на часть таблицы или индекс на поле с функцией
    -- создадим временную таблицу movies_and_genres где будут имена жанров:
CREATE
TEMPORARY TABLE movies_and_genres AS
  (SELECT movies.*,
          genres.genre_name
   FROM movies
   INNER JOIN movies_genres ON movies.movie_id = movies_genres.movie_id
   INNER JOIN genres ON movies_genres.genre_id = genres.genre_id);

CREATE INDEX MOVIES_AND_GENRES_INDEX ON MOVIES_AND_GENRES (NAME_ENG)
WHERE GENRE_NAME = 'Horror';

EXPLAIN (ANALYZE,
         COSTS OFF)
SELECT *
FROM MOVIES_AND_GENRES
WHERE NAME_ENG = 'LOLA AGENT'
  AND GENRE_NAME = 'Horror';
    -- результат:
    -- Index Scan using movies_and_genres_index on movies_and_genres (actual time=0.028..0.030 rows=1 loops=1)
    -- Planning Time: 0.060 ms
    -- Execution Time: 0.043 ms
-- 4. Создать индекс на несколько полей
CREATE INDEX MOVIES_INDEX_NAME_ANNOTATION ON MOVIES (NAME_ENG, ANNOTATION);

EXPLAIN (ANALYZE,
         COSTS OFF)
SELECT *
FROM MOVIES
WHERE NAME_ENG = 'MARS ROMAN'
  AND ANNOTATION ILIKE '%drama%';
    -- результат:
    -- Index Scan using movies_index_name_annotation on movies (actual time=0.022..0.023 rows=1 loops=1)
    -- Planning Time: 0.258 ms
    -- Execution Time: 0.044 ms
