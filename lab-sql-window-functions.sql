use sakila;

-- 1.1 Rank films by their length and create an output table that includes the title, length, and rank columns only. Filter out any rows with null or zero values in the length column.

Select title, length, rank() over(order by length desc) as 'rank'
from film
where length is not null 
and length > 0;

-- 1.2 Rank films by length within the rating category and create an output table that includes the title, length, 
-- rating and rank columns only. Filter out any rows with null or zero values in the length column.

 select title, length, rating, rank() over(partition by rating order by length desc) as `rank`
 from film
 where length is not null
 and length > 0;

-- 1.3 Produce a list that shows for each film in the Sakila database, the actor or actress who has acted in the greatest number of films,
-- as well as the total number of films in which they have acted. Hint: Use temporary tables, CTEs, or Views when appropiate to simplify your queries.

WITH actor_film_counts AS (
    SELECT 
        actor_id,
        COUNT(*) AS total_films
    FROM film_actor
    GROUP BY actor_id
),
film_actor_ranked AS (
    SELECT 
        fa.film_id,
        fa.actor_id,
        afc.total_films,
        RANK() OVER (
            PARTITION BY fa.film_id
            ORDER BY afc.total_films DESC
        ) AS rnk
    FROM film_actor fa
    JOIN actor_film_counts afc 
        ON fa.actor_id = afc.actor_id
)
SELECT 
    f.title,
    a.first_name,
    a.last_name,
    far.total_films
FROM film_actor_ranked far
JOIN film f 
    ON far.film_id = f.film_id
JOIN actor a 
    ON far.actor_id = a.actor_id
WHERE far.rnk = 1
ORDER BY f.title;

-- 2.1 Retrieve the number of monthly active customers, i.e., the number of unique customers who rented a movie in each month.

SELECT 
    DATE_FORMAT(rental_date, '%Y-%m') AS rental_month,
    COUNT(DISTINCT customer_id) AS active_customers
FROM rental
GROUP BY DATE_FORMAT(rental_date, '%Y-%m')
ORDER BY rental_month;

-- 2.2 Retrieve the number of active users in the previous month

SELECT 
    COUNT(DISTINCT customer_id) AS active_users_last_month
FROM rental
WHERE rental_date >= DATE_FORMAT(CURRENT_DATE - INTERVAL 1 MONTH, '%Y-%m-01')
  AND rental_date <  DATE_FORMAT(CURRENT_DATE, '%Y-%m-01');

-- 2.3 Calculate the percentage change in the number of active customers between the current and previous month.

WITH monthly_counts AS (
    SELECT
        DATE_FORMAT(rental_date, '%Y-%m') AS rental_month,
        COUNT(DISTINCT customer_id) AS active_customers
    FROM rental
    GROUP BY DATE_FORMAT(rental_date, '%Y-%m')
),
current_prev AS (
    SELECT
        (SELECT active_customers 
         FROM monthly_counts
         WHERE rental_month = DATE_FORMAT(CURRENT_DATE, '%Y-%m')
        ) AS current_month,
        
        (SELECT active_customers 
         FROM monthly_counts
         WHERE rental_month = DATE_FORMAT(CURRENT_DATE - INTERVAL 1 MONTH, '%Y-%m')
        ) AS previous_month
)
SELECT
    current_month,
    previous_month,
    ROUND(
        ((current_month - previous_month) / previous_month) * 100,
        2
    ) AS percentage_change
FROM current_prev;

SELECT 
    DATE_FORMAT(rental_date, '%Y-%m') AS rental_month,
    COUNT(*) AS rentals
FROM rental
GROUP BY rental_month
ORDER BY rental_month DESC;


WITH monthly_counts AS (
    SELECT
        DATE_FORMAT(rental_date, '%Y-%m') AS rental_month,
        COUNT(DISTINCT customer_id) AS active_customers
    FROM rental
    GROUP BY DATE_FORMAT(rental_date, '%Y-%m')
)
SELECT 
    sub.current_month,
    sub.previous_month,
    ROUND(
        ((sub.current_month - sub.previous_month) / sub.previous_month) * 100,
        2
    ) AS percentage_change
FROM (
    SELECT
        (SELECT active_customers 
         FROM monthly_counts
         WHERE rental_month = '2005-08') AS current_month,
         
        (SELECT active_customers 
         FROM monthly_counts
         WHERE rental_month = '2005-07') AS previous_month
) AS sub;

-- 2.4 Calculate the number of retained customers every month, i.e., customers who rented movies in the current and previous months.


WITH CustomerRentals AS (
    SELECT 
        DISTINCT customer_id, 
        EXTRACT(YEAR FROM rental_date) AS rental_year,
        EXTRACT(MONTH FROM rental_date) AS rental_month
    FROM 
        sakila.rental
),
RepeatRentals AS (
    SELECT DISTINCT 
        cr1.customer_id,
        CONCAT(cr1.rental_year, '-', LPAD(cr1.rental_month, 2, '0')) AS current_month,
        CONCAT(cr2.rental_year, '-', LPAD(cr2.rental_month, 2, '0')) AS previous_month
    FROM 
        CustomerRentals cr1
    JOIN 
        CustomerRentals cr2 ON cr1.customer_id = cr2.customer_id 
    WHERE 
        (cr1.rental_year = cr2.rental_year AND cr1.rental_month = cr2.rental_month + 1) 
        OR 
        (cr1.rental_year = cr2.rental_year + 1 AND cr1.rental_month = 1 AND cr2.rental_month = 12)
)
SELECT 
    current_month,
    COUNT(DISTINCT customer_id) AS retained_customers
FROM 
    RepeatRentals
GROUP BY 
    current_month
ORDER BY 
    current_month;

