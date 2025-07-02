SELECT
    f.title AS film_title,
    CONCAT(a.first_name, ' ', a.last_name) AS actor_name
FROM
    sakila.film f
JOIN sakila.film_actor fa ON f.film_id = fa.film_id
JOIN sakila.actor a ON fa.actor_id = a.actor_id
ORDER BY f.title, actor_name
LIMIT 20;