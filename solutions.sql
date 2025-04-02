-- Add you solution queries below:

-- 1. How many copies of the film _Hunchback Impossible_ exist in the inventory system?

SELECT sakila.film.film_id, COUNT(sakila.film.film_id)
FROM sakila.inventory
INNER JOIN sakila.film
ON sakila.inventory.film_id = sakila.film.film_id
WHERE title = 'HUNCHBACK IMPOSSIBLE'
GROUP BY sakila.film.film_id

-- RESULT: 6 copies.

-- 2. List all films whose length is longer than the average of all the films.

SELECT title, length
FROM sakila.film
WHERE length > (SELECT AVG(length) FROM sakila.film)

-- RESULT: 489 films longer than AVG length

-- 3. Use subqueries to display all actors who appear in the film _Alone Trip_.

SELECT *
FROM sakila.actor
WHERE actor_id IN (
	SELECT actor_id
	FROM sakila.film_actor
	WHERE film_id = (
		SELECT film_id
		FROM sakila.film
		WHERE title = "ALONE TRIP"
	)
);

-- 4. Sales have been lagging among young families, and you wish to target all family movies for a promotion. Identify all movies categorized as family films.

-- continued using subqueries for practice

SELECT title
FROM sakila.film
WHERE sakila.film.film_id IN (
	-- all the film ids of category family
	SELECT film_id
	FROM sakila.film_category
	WHERE sakila.film_category.category_id = (
		-- only id for category Family
		SELECT category_id
		FROM sakila.category
		WHERE sakila.category.name = "Family"
	)
)

-- 5. Get name and email from customers from Canada using subqueries. Do the same with joins. Note that to create a join, you will have to identify the correct tables with their primary keys and foreign keys, that will help you get the relevant information.

-- Solution with subqueries
SELECT customer_id, first_name, last_name, email
FROM sakila.customer
WHERE sakila.customer.address_id IN (
	-- address ids on cities in Canada
	SELECT address_id
	FROM sakila.address
	WHERE sakila.address.city_id IN (
		-- city ids from cities in Canada
		SELECT city_id
		FROM sakila.city
		WHERE country_id = (
			-- only ountry id for Canada
			SELECT country_id
			FROM sakila.country
			WHERE sakila.country.country = "Canada"
		)
	)
)

-- Solution with join
CREATE TEMPORARY TABLE sakila.cities_with_countries
SELECT city_id, city, sakila.country.country_id, country
FROM sakila.city
JOIN sakila.country
ON sakila.city.country_id = sakila.country.country_id;

CREATE TEMPORARY TABLE sakila.address_with_city_and_country
SELECT address_id, address, sakila.cities_with_countries.city_id, city, country_id, country
FROM sakila.cities_with_countries
JOIN sakila.address
ON sakila.cities_with_countries.city_id = sakila.address.city_id;

CREATE TEMPORARY TABLE sakila.customers_with_address_and_city_and_country
SELECT customer_id, first_name, last_name, email, sakila.address_with_city_and_country.address_id, address, city_id, city, country_id, country
FROM sakila.address_with_city_and_country
JOIN sakila.customer
ON sakila.address_with_city_and_country.address_id = sakila.customer.address_id;

SELECT customer_id, first_name, last_name, email
FROM sakila.customers_with_address_and_city_and_country
WHERE country = "Canada"

-- 6. Which are films starred by the most prolific actor? Most prolific actor is defined as the actor that has acted in the most number of films. First you will have to find the most prolific actor and then use that actor_id to find the different films that he/she starred.

CREATE TEMPORARY TABLE sakila.film_ids_from_most_prolific_actor
SELECT *
FROM sakila.film_actor
WHERE actor_id = (
	-- most prolific actor id
	SELECT actor_id
	FROM sakila.film_actor
	GROUP BY actor_id
	ORDER BY COUNT(film_id) DESC
	LIMIT 1
);

SELECT title
FROM sakila.film_ids_from_most_prolific_actor
JOIN sakila.film
ON sakila.film_ids_from_most_prolific_actor.film_id = sakila.film.film_id

-- 7. Films rented by most profitable customer. You can use the customer table and payment table to find the most profitable customer ie the customer that has made the largest sum of payments

CREATE TEMPORARY TABLE sakila.rentals_from_most_profitable_customer
SELECT *
FROM sakila.rental
WHERE sakila.rental.customer_id = (
	-- id of most profitable customer
    SELECT customer_id
	FROM sakila.payment
	GROUP BY customer_id
	ORDER BY SUM(amount) DESC
	LIMIT 1
);

CREATE TEMPORARY TABLE sakila.film_ids_rented_by_most_profitable_customer
SELECT film_id, rental_id, customer_id
FROM sakila.rentals_from_most_profitable_customer
JOIN sakila.inventory
ON sakila.rentals_from_most_profitable_customer.inventory_id = sakila.inventory.inventory_id;

-- film titles rented by most profitable customer
SELECT customer_id, rental_id, sakila.film.film_id, title
FROM sakila.film
JOIN sakila.film_ids_rented_by_most_profitable_customer
ON sakila.film_ids_rented_by_most_profitable_customer.film_id = sakila.film.film_id

-- 8. Get the `client_id` and the `total_amount_spent` of those clients who spent more than the average of the `total_amount` spent by each client.

CREATE TEMPORARY TABLE sakila.customer_totals AS
SELECT customer_id, SUM(amount) AS total_amount
FROM sakila.payment
GROUP BY customer_id;

-- using these "variables" for the average as it did not work by adding this subquery into the WHERE below
SET @avg_total = (
  SELECT AVG(total_amount)
  FROM sakila.customer_totals
);

SELECT customer_id, total_amount
FROM sakila.customer_totals
WHERE total_amount > @avg_total

