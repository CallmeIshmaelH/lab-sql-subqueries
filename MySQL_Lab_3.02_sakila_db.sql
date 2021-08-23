-- LAB 3.02
use sakila;

-- 1. How many copies of the film Hunchback Impossible exist in the inventory system?

-- first find the film_id of Hunchback Impossible from the film table.

select film_id from sakila.film f where f.title like ('%Hunchback Impossible%');

-- now we can execute this as a subquery for the counts of the film
select count(film_id) as Hunchback_Impossible_stock 
from sakila.inventory where film_id = (select film_id from sakila.film f where f.title like ('%Hunchback Impossible%'));

-- SIMPLIFIED version:
select count(film_id) as Hunchback_impossible_stock
from inventory where film_id in 
	(select film_id from film where title = ('Hunchback Impossible'));


-- 2. List all films whose length is longer than the average of all the films.

-- first find the average of all films
select AVG(f.length) as Average_length from sakila.film f; 

-- now use the above as a subquery in the where clause
select * 
from sakila.film 
where film.length > (select AVG(f.length) as Average_length from sakila.film f)
order by film.length desc; 

-- SIMPLIFIED version:
select * from film where `length`> 
	(select AVG(`length`) from film)
order by film.`length` desc;


-- 3. Use subqueries to display all actors who appear in the film Alone Trip.

-- define a query to select the actor_ids from the film 'Alone Trip'
select film_id 
from sakila.film 
where film.title 
like ('%Alone Trip%');

-- define a query to get a list of the actor_ids using the film_id above
select actor_id 
from sakila.film_actor 
where film_id = (
select film_id 
from sakila.film 
where film.title 
like ('%Alone Trip%'));

-- define a query to get the actor names using the above query as a subquery

select * from sakila.actor 
where actor_id in (
	select actor_id 
	from sakila.film_actor 
	where film_id = (
		select film_id 
		from sakila.film 
		where film.title 
		like ('%Alone Trip%'))
); 

-- SIMPLIFIED VERSION:
select * from actor where actor_id in
	(select actor_id from film_actor where film_id = 
		(select film_id from film where title = 'Alone Trip'));

-- 4. Sales have been lagging among young families, and you wish to target all family movies for a promotion.
--    Identify all movies categorized as family films.

-- Get the category id for movies with the 'Family' category
select category_id from sakila.category c where c.name like '%Family%';

-- Get the film_ids from the film_category table with this category id

select film_id from sakila.film_category fc where fc.category_id = (select category_id from sakila.category c where c.name like '%Family%');

-- build the full query using the above subqueries
select * from sakila.film f where f.film_id in (select film_id from sakila.film_category fc where fc.category_id = (select category_id from sakila.category c where c.name like '%Family%'));

-- SIMPLIFIED VERSION
select * from film where film_id in
	(select film_id from film_category where category_id = 
		(select category_id from category where name = 'Family')
	);


-- 5. Get name and email from customers from Canada using subqueries.

-- get country_id based on country name
select country_id 
from sakila.country c 
where c.country like '%Canada%';

-- get city_id based on country_id
select city_id 
from sakila.city ci 
where ci.country_id = (
	select country_id 
	from sakila.country c 
	where c.country like '%Canada%');

-- get address_id based on city_id
select address_id 	
from address a 
where a.city_id in (
	select city_id 
	from sakila.city ci 
	where ci.country_id = (
		select country_id 
		from sakila.country c 
		where c.country like '%Canada%')) ;

-- get customers from Canada based on address_ids
select * 
from customer 
where customer.address_id in(
	select address_id 
	from address a 
	where a.city_id in (
		select city_id 
		from sakila.city ci 
		where ci.country_id = (
			select country_id 
			from sakila.country c 
			where c.country like '%Canada%')) 
		);
	
-- SIMPLIFIED VERSION
select * from customer where address_id in 
	(select address_id from address where city_id in
		(select city_id from city where country_id in
			(select country_id from country where country = 'Canada'))
		);	

--    Do the same with joins. Note that to create a join, you will have to identify the correct tables
--    with their primary keys and foreign keys, that will help you get the relevant information.
select cus.* 
from sakila.country c 
join sakila.city ci 
using(country_id)
join sakila.address a
using(city_id)
join sakila.customer cus 
on cus.address_id = a.address_id 
where c.country like '%Canada%';


-- 6. Which are films starred by the most prolific actor? 
--    Most prolific actor is defined as the actor that has acted in the most number of films. 
--    First you will have to find the most prolific actor and then use that actor_id to find the different films that he/she starred.

-- find the most prolific actor by counting the number of films each actor has appeared in and order by descending--
select actor_id, count(film_id) as Total_films 
from sakila.film_actor
group by actor_id
order by Total_films desc limit 1;

-- find the films which this actor_id appears insert 
select film_id 
from sakila.film_actor fa
where fa.actor_id = (
	select actor_id 
	from(
		select actor_id, count(film_id) as Total_films 
		from sakila.film_actor
		group by actor_id
		order by Total_films desc limit 1
		)sub1);
	
-- find the films for each of the film ids returned from the above query
select *
from sakila.film f
where f.film_id in (
	select fa.film_id 
	from sakila.film_actor fa
	where fa.actor_id = (
		select actor_id 
		from(	
			select actor_id, count(film_id) as Total_films 
			from sakila.film_actor
			group by actor_id
			order by Total_films desc limit 1
			)sub1)); 
		
-- SIMPLIFIED VERSION
select * from film where film_id in
(select film_id from film_actor where actor_id = 
	(select actor_id from 
		(select actor_id, count(film_id) from film_actor
		group by actor_id
		order by count(film_id) desc limit 1)sub1 )
			);
		
-- 7. Films rented by most profitable customer. You can use the customer table and payment table to find the most profitable customer
--    i.e. the customer that has made the largest sum of payments Customers who spent more than the average payments.
		
-- find the sum of each customer's payments
select customer_id, sum(amount) as Sum_Customer_Payment
from sakila.payment 
group by customer_id;

-- find the average of the sum of each customer's payments
select avg(Sum_Customer_Payment) as Average_Payment
from (
	  select sum(amount) as 'Sum_Customer_Payment' 
	  from sakila.payment 
	  group by customer_id
	  )sub1;
	  
--find the most profitable customer by selecting all customers with payments greater than average ordered by descending
select customer_id, sum_customer_payment 
from (
	select customer_id, sum(amount) as Sum_Customer_Payment
	from sakila.payment 
	group by customer_id) sub1 
where sum_customer_payment > (
	select avg(Sum_Customer_Payment) as Average_Payment
	from (
	  		select sum(amount) as 'Sum_Customer_Payment' 
	  		from sakila.payment 
	  		group by customer_id
	  	)sub2)
group by customer_id
order by sum_customer_payment desc
limit 1;

-- find the inventory_id of films rented by this customer
select inventory_id 
from sakila.rental r
where r.customer_id = (	
	select customer_id from(
		select customer_id, sum_customer_payment 
		from (
			select customer_id, sum(amount) as Sum_Customer_Payment
			from sakila.payment 
			group by customer_id) sub1 
		where sum_customer_payment > (
				select avg(Sum_Customer_Payment) as Average_Payment
				from (
	  				select sum(amount) as 'Sum_Customer_Payment' 
	  				from sakila.payment 
	  				group by customer_id
	  				)sub2)
	group by customer_id
	order by sum_customer_payment desc
	limit 1)sub3);
	
-- get the film ids for all unique films in the list of inventory_ids
select distinct film_id
from sakila.inventory i 
where i.inventory_id in (
select inventory_id 
from sakila.rental r
where r.customer_id = (	
	select customer_id from(
		select customer_id, sum_customer_payment 
		from (
			select customer_id, sum(amount) as Sum_Customer_Payment
			from sakila.payment 
			group by customer_id) sub1 
		where sum_customer_payment > (
				select avg(Sum_Customer_Payment) as Average_Payment
				from (
	  				select sum(amount) as 'Sum_Customer_Payment' 
	  				from sakila.payment 
	  				group by customer_id
	  				)sub2)
	group by customer_id
	order by sum_customer_payment desc
	limit 1)sub3));
	
-- get film information for films matching ids returned by the previous query
select * from sakila.film f 
where f. film_id in (
	select distinct film_id
	from sakila.inventory i 
	where i.inventory_id in (
		select inventory_id 
		from sakila.rental r
		where r.customer_id = (	
		select customer_id 
			from(
				select customer_id, sum_customer_payment 
				from(
					select customer_id, sum(amount) as Sum_Customer_Payment
					from sakila.payment 
					group by customer_id) sub1 
					where sum_customer_payment > (
							select avg(Sum_Customer_Payment) as Average_Payment
							from (
	  							select sum(amount) as 'Sum_Customer_Payment' 
	  							from sakila.payment 
	  							group by customer_id
	  							)sub2)
		group by customer_id
		order by sum_customer_payment desc
		limit 1)sub3))
		); 
	
-- MUCH SIMPLER VERSION (Thanks to Elizabeth.)
SELECT * FROM film
WHERE film_id IN (
	SELECT film_id FROM inventory WHERE inventory_id IN (
		SELECT inventory_id FROM rental WHERE customer_id =(
			SELECT customer_id FROM payment
			GROUP BY customer_id ORDER BY sum(amount) desc LIMIT 1)));


-- 8. Customers who spent more than the average payments
select * 
from customer where customer_id in (
select customer_id from(
	select *
	from (
		select customer_id, sum(amount) as Sum_Customer_Payment
		from sakila.payment 
		group by customer_id)sub1 
	where sum_customer_payment > (
			select avg(Sum_Customer_Payment) as Average_Payment
			from (
	  			select sum(amount) as 'Sum_Customer_Payment' 
	  			from sakila.payment 
	  			group by customer_id
	  		)sub2)
group by customer_id
order by sum_customer_payment desc)sub3
	);

-- SIMPLIFIED VERSION

select * from customer where customer_id in 
	(select customer_id from 
		(select customer_id, sum(amount) as sum_payments from payment group by customer_id) sub1
	where sum_payments > 
			(select avg(sum_payments) from 
				(select sum(amount) as sum_payments from payment group by customer_id) sub2
group by customer_id
order by sum_payments desc)
);			

