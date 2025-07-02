SELECT
    f.title,
    GROUP_CONCAT(CONCAT(a.first_name, ' ', a.last_name) ORDER BY a.last_name SEPARATOR ', ') AS actor_names
FROM
    sakila.film f
JOIN sakila.film_actor fa ON f.film_id = fa.film_id
JOIN sakila.actor a ON fa.actor_id = a.actor_id
GROUP BY f.title
ORDER BY f.title
LIMIT 10;
