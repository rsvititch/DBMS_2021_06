-- ДЗ №4
--Напишите запрос на добавление данных с выводом информации о добавленных строках.

  -- Подключил к Postgres БД Sakila, заполнил часть таблиц данными из Sakila:
CREATE EXTENSION dblink;
INSERT INTO genres
  (genre_id,
   genre_name)
	SELECT category_id,
         name
	FROM dblink('host=localhost user=postgres password=123456 dbname=sakila', 'SELECT * from category')
       AS genres(category_id integer, name varchar(30), last_update timestamp)
	     RETURNING genre_id, genre_name;

INSERT INTO creators
    (creator_id,
    creator_credentials)
  	SELECT DISTINCT ON
      (credentials) actor_id, concat(first_name, ' ', last_name) as credentials
  	FROM dblink('host=localhost user=postgres password=123456 dbname=sakila', 'SELECT * from actor')
    AS creators(actor_id int, first_name varchar(45), last_name varchar(45), last_update timestamp)
  	RETURNING creator_id, creator_credentials;

    -- Заполнил справочники значениями

INSERT INTO movies_types
    (movie_type,
    movie_type_name)
  	VALUES
		(1,'Normal'),
		(2, 'Trailer'),
		(3,'Commercials'),
		(4,'Director_s Cut');

INSERT INTO movies_roles
    (role_id,
    role_name)
  	VALUES
		(1,'Actor'),
		(2, 'Director'),
		(3,'Screeenwriter'),
		(4,'Producer');

INSERT INTO Movies_Genres
    (movie_id,
    genre_id)
  SELECT movie_id,genre_id
    	FROM
    dblink('host=localhost user=postgres password=123456 dbname=sakila', 'SELECT film_id, category_id FROM film_category')
    AS sakilaDB(movie_id	integer, genre_id integer);

    -- заполнил таблицу Movies. Данные частично взял из Sakila, потом дополнил
    --значениями по умолчанию, потом значения по умолчанию частично поменял
    -- другими в зав-ти от Movie_ID.
    -- Использовал временную таблицу, т.к в таблице Movies стоит проверка
    -- на Null, неудобно вставлять сразу все.

CREATE TEMPORARY table t1 (
    Movie_ID int,
    Name_Eng varchar(4000),
    Name_Ru  varchar(4000),
    Annotation  text,
    Age_Rating  int,
    Release_Date date,
    Release_Exp_Date date,
    Movie_Release_Year int,
    Country text,
    Rating_IMDB_Date  date,
    Rating_Kinopoisk  decimal(3,2),
    Rating_Kinopoisk_Date date,
    Rating_IMDB decimal(3,2),
    Movie_type int);

INSERT INTO t1
    (movie_id,
    name_eng,
    name_ru,
    annotation,
    movie_release_year,
    Rating_Kinopoisk,
    Rating_IMDB)
  SELECT
    movie_id,
    name_eng,
    name_eng,
    annotation,
    movie_release_year,
    rental_rate,
    rental_rate
  FROM dblink('host=localhost user=postgres password=123456 dbname=sakila', 'SELECT film_id, title, description, release_year, rental_rate FROM film')
    AS t1(movie_id	integer, name_eng	varchar(4000), annotation text, movie_release_year int, rental_rate numeric(3,2));

UPDATE T1 set
    (movie_type,
    rating_imdb_date,
    rating_kinopoisk_date,
    age_rating,
    release_date,
    release_exp_date,
    country)
    =
    (1,
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP,
    0,
    CURRENT_DATE - interval '5 years',
    CURRENT_DATE + interval '5 years',
    'USA');

UPDATE T1 set
    (age_rating,
    release_date,
    release_exp_date,
    country)
    =
    (6,
    CURRENT_DATE - interval '3 years',
    CURRENT_DATE + interval '3 years',
    'Russia')
    WHERE
    mod(movie_id,10) = 0;

UPDATE T1 set
    (age_rating,
    release_date,
    release_exp_date,
    country)
    =
    (12,
    CURRENT_DATE - interval '2 years',
    CURRENT_DATE + interval '2 years',
    'Spain')
    WHERE
    mod(movie_id,3) = 0;

UPDATE T1 set
    (age_rating,
    release_date,
    release_exp_date,
    country)
    =
    (16,
    CURRENT_DATE - interval '1 year',
    CURRENT_DATE + interval '1 years',
    'UK')
    WHERE
    mod(movie_id,7) = 0;

UPDATE T1 set
    (age_rating,
    release_date,
    release_exp_date,
    country)
    =
    (18,
    CURRENT_DATE - interval '2 year',
    CURRENT_DATE + interval '2 year',
    'France')
    WHERE
    mod(movie_id,11) = 0;

INSERT into movies
    (Movie_ID,
    Name_Eng,
    Name_Ru,
    Annotation,
    Age_Rating,
    Release_Date,
    Release_Exp_Date,
    Movie_Release_Year,
    Country,
    Rating_IMDB_Date,
    Rating_Kinopoisk,
    Rating_Kinopoisk_Date,
    Rating_IMDB,
    Movie_type)
  SELECT
    Movie_ID,
    Name_Eng,
    Name_Ru,
    Annotation,
    Age_Rating,
    Release_Date,
    Release_Exp_Date,
    Movie_Release_Year,
    Country,
    Rating_IMDB_Date,
    Rating_Kinopoisk,
    Rating_Kinopoisk_Date,
    Rating_IMDB,
    Movie_type
  FROM t1;

DROP TABLE t1;

-- Напишите запрос с обновлением данных используя UPDATE FROM.
    -- Для выполнения условия задачи создадим таблицу, в которой будут только фильмы ужасов. По умолчанию зададим для фильмов ужасов рейтинг 18+
CREATE table horror_movies
	(movie_id integer,
	genre_name varchar (30),
	age_rating integer DEFAULT 16);

INSERT INTO horror_movies
	SELECT
  movies.movie_id,
  genre_name
	FROM
	movies
	INNER JOIN
	movies_genres
	ON movies.movie_id = movies_genres.movie_id
		INNER JOIN
		genres
		ON movies_genres.genre_id = genres.genre_id
 WHERE genres.genre_name = 'Horror';

    -- теперь заменим в таблице movies рейтинг для всех фильмов ужасов на 18+ используя таблицу horror_movies
    -- (это можно сделать через WHERE с одной таблицей, но надо соблюсти конструкцию UPDATE FROM)

UPDATE movies
		SET age_rating = horror_movies.age_rating
		FROM horror_movies
		WHERE movies.movie_id = horror_movies.movie_id;

-- Напишите запрос по своей базе с регулярным выражением, добавьте пояснение, что вы хотите найти.
SELECT
  name_eng,
  annotation
  FROM
  movies
  WHERE
  name_eng ILIKE '%CLUB%'; -- поиск фильма и аннотации по строке поиска

--Напишите запрос по своей базе с использованием LEFT JOIN и INNER JOIN, как порядок соединений в FROM влияет на результат? Почему?
SELECT name_eng, annotation, genre_name
  	FROM
  	movies
  	INNER JOIN
  	movies_genres
  	ON movies.movie_id = movies_genres.movie_id
  		INNER JOIN
  		genres
  		ON movies_genres.genre_id = genres.genre_id;

SELECT name_eng, annotation, genre_name
  	FROM
  	genres
  	LEFT JOIN
  	movies_genres
  	ON movies_genres.genre_id = genres.genre_id
  		LEFT JOIN
  		movies
  		ON movies.movie_id = movies_genres.movie_id;

      -- поскольку для каждого movie_id определен хотя бы 1 жанр, то порядок и тип JOIN никак на результат не влияет.

--Напишите запрос для удаления данных с оператором DELETE используя join с другой таблицей с помощью using.
    -- посчитаем количество фильмов ужасов в таблице movies
SELECT count(*)
	FROM
	movies
	INNER JOIN
	movies_genres
	ON movies.movie_id = movies_genres.movie_id
		INNER JOIN
		genres
		ON movies_genres.genre_id = genres.genre_id
	WHERE genre_name = 'Horror';
    -- запрос выдает что в базе имеется 56 фильмов в жанре "Ужасы"
    -- удалим из базы фильмов все фильмы ужасов, используя таблицу horror_movies
DELETE FROM movies
	USING horror_movies
	WHERE movies.movie_id = horror_movies.movie_id;
-- теперь запрос select count (*) по фильмам ужасов (см. выше)выдает 0 записей.
DROP TABLE horror_movies;
