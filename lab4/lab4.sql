--Поляков Илья, 31 группа


--Задание 1.Тестовые данные
INSERT INTO users (login, pASsword, role_id)
SELECT
  'login' || seq AS login,
  'pASsword' || seq AS pASsword, 
  RANDOM() * 2 AS role_id
FROM GENERATE_SERIES(1, 1000000) seq;


SELECT count(*) FROM users;


INSERT INTO profiles (user_id, name, photo, biogrophy)
SELECT
    seq AS user_id,
    'name' || seq AS name,
    'name' || seq ||'.jpg' AS photo,
    'My name is'||'name' || seq AS biogrophy
FROM  GENERATE_SERIES(10202, 1000000) seq  ;

SELECT * FROM profiles limit 10;


INSERT INTO films (name,year,genre,director,country,poster,description ) 
SELECT
  'Film name ' || seq AS name,
  (RANDOM() * 71 + 1950)::INT AS year,
  (
    CASE (RANDOM() * 3)::INT
    WHEN 0 THEN 'драма'
    WHEN 1 THEN 'фантастика'
    WHEN 2 THEN 'боевик'
    WHEN 3 THEN 'комедия'
    END
  ) AS genre,
  'director' || seq AS director,
  (
    CASE (RANDOM() * 3)::INT
    WHEN 0 THEN 'Беларусь'
    WHEN 1 THEN 'США'
    WHEN 2 THEN 'Китай'
    WHEN 3 THEN 'Россия'
    END
  ) AS country,
  'poster' || seq ||'.jpg' AS poster,
  'Some description '|| seq AS description
FROM GENERATE_SERIES(1, 1000000) seq;

SELECT * FROM films limit 10;


INSERT INTO profiles_films(profile_id, film_id, status, rating)
WITH expanded AS (
  SELECT  DISTINCT
  profiles.id AS profile_id,
  (RANDOM() * 990000 + 11011)::INT AS  film_id,
   (
    CASE (RANDOM() * 1)::INT
      WHEN 0 THEN 'false'::boolean
      WHEN 1 THEN 'true'::boolean
    END
  ) AS status
FROM profiles
GROUP BY profile_id, film_id
)


SELECT DISTINCT
    e.profile_id AS profile_id,
    e.film_id AS  film_id,
    e.status AS  status,
   (
    CASE  WHEN( e.status) 
      THEN RANDOM() * 10::INT
    END
     ) AS rating
FROM expanded e;

SELECT * FROM profiles_films limit 10;

--Задание 2. Разработать запрос,

SELECT
   p.name, p.photo, p.biogrophy, f.id
FROM
  profiles p
  JOIN profiles_films p_f ON p_f.profile_id = p.id
  LEFT JOIN films f ON p_f.film_id = f.id
WHERE f.name LIKE 'Film name 1%' 
GROUP BY  p.name,p.photo, p.biogrophy, f.id
HAVING count(f.year)>0
ORDER BY f.id 
limit 10;


--Задание 4. Индекс
create INDEX index_name on films(name);
drop index index_name;