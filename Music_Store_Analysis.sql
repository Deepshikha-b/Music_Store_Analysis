--1: Who is the senior most employee based on job title?

SELECT *
FROM employee
ORDER BY levels DESC
LIMIT 1;


--2: Which countries have the most Invoices?

SELECT billing_country
	,COUNT(*) AS total_invoices
FROM invoice
GROUP BY billing_country
ORDER BY total_invoices DESC;


--3: What are the top 3 values of total invoice?

SELECT invoice_id
	,total
FROM invoice
ORDER BY total DESC
LIMIT 3;


/*4: Which city Has the best customers? We would like to throw a promotional music festival in the city we made the most money. Write a query that returns one city that has the highest sum of invoice totals return both the city name and sum of all invoice totals.*/

WITH total_bill AS(
	SELECT il.invoice_id
		,billing_city
		,SUM(unit_price*quantity) AS invoice_total
	FROM invoice_line il
	LEFT JOIN invoice i
	ON il.invoice_id=i.invoice_id
	GROUP BY billing_city,il.invoice_id
	ORDER BY billing_city,il.invoice_id
	)
SELECT billing_city
	,SUM(invoice_total) total_money_spent
FROM total_bill
GROUP BY billing_city
ORDER BY total_money_spent DESC
limit 1;


/*5: Who is the best customer? The customer who has spent the most money will be declared the best customer. Write a query that returns the person who has spent the most money.*/

SELECT i.customer_id
	,first_name ||' '|| last_name AS name
	,SUM(total)
FROM invoice i
LEFT join customer c
ON i.customer_id=c.customer_id
GROUP BY i.customer_id,name
ORDER BY SUM(total) DESC
LIMIT 1;


/*6: Write a query to return the email first name, last name and genre of all rock music listeners.Return your list ordered alphabetically by email, starting with A.*/

SELECT DISTINCT(c.email)
	,c.first_name
	,c.last_name
FROM customer c
 JOIN invoice i
ON c.customer_id = i.customer_id
 JOIN invoice_line il
ON i.invoice_id = il.invoice_id
WHERE track_id IN (SELECT track_id
				   FROM track t
					 JOIN genre g
					ON t.genre_id = g.genre_id
					WHERE g.name = 'Rock')
ORDER BY email;


/*7: Let's invite the artists who have written the most rock music in our data set. Write a query that returns the artist's name and total track count of the top 10 rock bands.*/

SELECT a.artist_id
	,a.name
	,COUNT(g.name)
FROM artist a
JOIN album al
ON a.artist_id = al.artist_id
JOIN track t
ON al.album_id = t.album_id
JOIN genre g
ON t.genre_id = g.genre_id
WHERE g.name = 'Rock'
GROUP BY a.artist_id
ORDER BY COUNT(g.name) DESC 
LIMIT 10;


/*8: Return all the track names that have a song length longer than the average song length. Return the name and milliseconds for each track order by the song length with the longest songs listed first.*/

SELECT name
	,milliseconds
FROM track
WHERE milliseconds> (SELECT avg(milliseconds) FROM track)
ORDER BY milliseconds DESC;


/*9: Find how much amount spent by each customer on the highest selling artist. Write a query to return customer name, artist name and total spent.*/

WITH best_selling_artist AS(
	SELECT artist.artist_id AS artist_id
		,artist.name AS name
		,SUM(invoice_line.unit_price*invoice_line.quantity) AS total_sales
	FROM artist 
	JOIN album ON artist.artist_id = album.artist_id
	JOIN track ON album.album_id = track.album_id
	JOIN invoice_line ON track.track_id = invoice_line.track_id
	GROUP BY artist.artist_id,artist.name
	ORDER BY total_sales DESC
	LIMIT 1
)
SELECT customer.customer_id
	,first_name ||' '||last_name AS full_name
	,best_selling_artist.name
	,SUM(invoice_line.unit_price*invoice_line.quantity) AS amount_spent
FROM customer
JOIN invoice ON customer.customer_id = invoice.customer_id
JOIN invoice_line ON invoice.invoice_id = invoice_line.invoice_id
JOIN track ON invoice_line.track_id = track.track_id
JOIN album ON track.album_id = album.album_id
JOIN best_selling_artist ON album.artist_id = best_selling_artist.artist_id
GROUP BY customer.customer_id
	,full_name
	,best_selling_artist.name
ORDER BY amount_spent DESC


/*10: We want to find out the most popular music genre for each country. We determinethe most popular genre as the genre with the highest amount of purchases. Write a query that returns each country along with the top genre. For countrieswhere the maximum number of purchases is shared, return all genres.*/

WITH amount_spent AS (
	SELECT c.country country
		,g.name AS genre_name
		,SUM(il.unit_price*il.quantity) AS total_spent
	FROM customer c
	JOIN invoice i 
	ON c.customer_id = i.customer_id
	JOIN invoice_line il
	ON i.invoice_id = il.invoice_id
	JOIN track t
	ON il.track_id = t.track_id
	JOIN genre g
	ON t.genre_id = g.genre_id
	GROUP BY c.country,g.name
	ORDER BY 1,3 DESC,2
),
max_spent AS(
	SELECT country,max(total_spent) as total
	FROM amount_spent
	GROUP BY country
)
SELECT amount_spent.country,amount_spent.genre_name,max_spent.total
FROM amount_spent
JOIN max_spent
ON amount_spent.country = max_spent.country
WHERE amount_spent.total_spent=max_spent.total
ORDER BY country


/*11: Write a query that determines the customer that has spent the most on music for each country. Write a query that returns the country along with the top customer, and how much they spend for. countries where the top amount spent is shared, provide all customers who spent this amount.*/

WITH total_spent AS(
	SELECT cust.customer_id AS customer_id,country,first_name,last_name,
		SUM(unit_price*quantity) AS amount,
		ROW_NUMBER() 
			OVER(PARTITION BY country 
			 ORDER BY SUM(unit_price*quantity)DESC) AS rowNo
	FROM customer cust
	JOIN invoice i
	ON cust.customer_id = i.customer_id
	JOIN invoice_line il
	ON i.invoice_id = il.invoice_id
	GROUP BY cust.customer_id,first_name,last_name,country
	ORDER BY country,amount DESC
)
SELECT country,customer_id,first_name,last_name,amount FROM total_spent WHERE
rowno <=1	