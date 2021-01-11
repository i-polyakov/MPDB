--Поляков Илья, 31 группа
--Задание 1. секционирование
CREATE TABLE profiles_films (
	id 			SERIAL 	NOT NULL,
	profile_id  INTEGER NOT NULL,
	film_id 	INTEGER NOT NULL,
	status 		BOOLEAN NOT NULL,
	rating 		INTEGER DEFAULT 0  CHECK(rating >= 0 AND rating <= 10),

	PRIMARY KEY (id, status),
	UNIQUE  (profile_id, film_id,status),
	FOREIGN KEY (profile_id) REFERENCES profiles(id) ON DELETE CASCADE ON UPDATE CASCADE,
	FOREIGN KEY (film_id) REFERENCES films(id) ON DELETE CASCADE ON UPDATE CASCADE
) PARTITION BY LIST (status);

CREATE TABLE viewedFilms PARTITION OF profiles_films
  FOR VALUES IN ('true');

  CREATE TABLE watchFilms PARTITION OF profiles_films
  FOR VALUES IN ('false');


--Задание 2. Написать триггер
CREATE FUNCTION profiles_films_insert() RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status = 'true' THEN
      INSERT INTO viewedFilms SELECT NEW.*;
    ELSEIF NEW.status = 'false' THEN
      INSERT INTO watchFilms SELECT NEW.*;
    ELSE
      RAISE EXCEPTION 'incorrect status %',  NEW.status;
    END IF;
  	RETURN NEW;
END
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger
	BEFORE INSERT ON profiles_films
	EXECUTE PROCEDURE profiles_films_insert();


--Задание 3. Написать запросы
	SELECT * FROM watchFilms WHERE id>10000 limit 10;
	SELECT * FROM viewedFilms WHERE rating=5 limit 10;