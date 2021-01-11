--Поляков Илья, 31 группа

--1.Вывести количество товаров для каждой категории.
SELECT category_id, COUNT(*) FROM products
GROUP BY category_id;


--2.Вывести список пользователей, которые не оплатили хотя бы 1 заказ полностью.
SELECT users.id, users.login 
FROM users JOIN orders s ON users.id=s.user_id 
AND s.price > (SELECT SUM(payments_orders.value) 
	FROM payments_orders JOIN orders ON payments_orders.order_id = s.id
	GROUP BY payments_orders.order_id)
GROUP BY users.id, users.login;


--3.Удалить товары, которые ни разу не были куплены (отсутствуют информация в таблице basket).
DELETE FROM products
WHERE products.id NOT IN (
    SELECT basket.product_id
    FROM basket);


--4.Вывести заказы, которые оплачены только частично.
SELECT s.id, s.price
FROM users JOIN orders s ON users.id=s.user_id 
AND s.price > (SELECT SUM(payments_orders.value) 
	FROM payments_orders JOIN orders ON payments_orders.order_id = s.id
	GROUP BY payments_orders.order_id) 

AND (SELECT SUM(payments_orders.value) 
	FROM payments_orders JOIN orders ON payments_orders.order_id = s.id
	GROUP BY payments_orders.order_id)  > '0'
GROUP BY s.id, s.price;


--5.Вывести для каждого покупателя количество его заказов по статусам.
SELECT users.id, users.login,
COUNT(orders.*) filter (WHERE orders.status = 'N') AS count_n,
COUNT(orders.*) filter (WHERE orders.status = 'D') AS count_d,
COUNT(orders.*) filter (WHERE orders.status = 'P') AS count_p,
COUNT(orders.*) filter (WHERE orders.status = 'F') AS count_f,
COUNT(orders.*) filter (WHERE orders.status = 'C') AS count_c
FROM users RIGHT JOIN orders ON orders.user_id = users.id
GROUP BY users.id;


--6.Вывести средний чек для выполненных заказов (status="F").
SELECT AVG(price) AS avg_price 
FROM orders
WHERE status='F';


--7.Вывести топ-10 самых продаваемых товаров по суммарной прибыли (заказы для этих товаров должны быть полностью оплачены).
SELECT products.*, SUM(basket.price) AS b_sum
FROM products RIGHT JOIN basket ON basket.product_id = products.id 
AND (SELECT orders.id, orders.price, SUM(payments_orders.value) AS paid_num
	FROM orders RIGHT JOIN payments_orders ON payments_orders.order_id = orders.id
	GROUP BY orders.id, payments_orders.value) AS orders_num
WHERE orders_num.price <= orders_num.paid_num
GROUP BY products.id
ORDER BY b_sum DESC LIMIT 10;


--8.Вывести список товаров, которые лежат пока только в корзине и не привязаны к заказу, и их количества не хватает на складе
--  для продажи (считается, что товар списывается со склада только тогда, когда заказ будет доставлен).
SELECT products.*
FROM products p
RIGHT JOIN basket b ON b.product_id = p.id and b.order_id IS NULL
GROUP BY p.id
HAVING SUM(b.quantity)<SUM(p.quantity);


--9.Вывести список пользователей, которые "бросили"  свои корзины (не оформили заказ) за последние 30 дней.
SELECT u.id, us.login
FROM users u JOIN customers ON u.id = customers.user_id
JOIN basket b ON customers.id = b.customer_id
WHERE b.order_id IS NULL AND b.create_at >= (SELECT NOW()-INTERVAL '30' DAY)
ORDER BY u.id;


--10.Добавить скидку 10% на все товары, которые покупались (статус заказов "P" или "F") не более 10 раз.
UPDATE products SET discount=discount* 1.1 
WHERE products.id IN 
	(SELECT basket.product_id
    FROM basket RIGHT JOIN orders ON basket.order_id=orders.id
    WHERE orders.status SIMILAR TO 'P|F'
    GROUP BY basket.product_id
    HAVING COUNT(orders.*) <= 10);


--11.Вывести количество заказов оплаченных полностью с внутреннего счета.
SELECT orders.id, COUNT(*) FROM orders JOIN payments_orders ON orders.id=payments_orders.order_id 
WHERE orders.status= 'P' AND payments_orders.payment_id IS NULL AND payments_orders.from_account IS TRUE
GROUP BY orders.id;


--12.Сделать скидку 50% (без доставки, только на товары) на новые заказы (статус "N") для VIP-пользователей.
UPDATE orders SET discount = discount*1.5 
WHERE orders.user_id IN 
	(SELECT users.id 
    FROM users RIGHT JOIN accounts ON accounts.user_id = users.id
    WHERE accounts.is_vip = true
    GROUP BY users.id)  
AND  orders.status = 'N';


--13.Вывести самую популярную доставку и самый популярный способ оплаты (результат из 2 записей)
SELECT most_pop_delivery.*,most_pop_payment.*
FROM 	(
		SELECT delivery.*, COUNT(delivery_orders.*) AS orders_count
		FROM delivery LEFT JOIN delivery_orders ON delivery_orders.delivery_id = delivery.id 
		GROUP BY delivery.id 
		ORDER BY orders_count DESC LIMIT 1
		) AS most_pop_delivery,

		(
		SELECT payments.*, COUNT(payments_orders .*) AS orders_count 
		FROM payments LEFT JOIN payments_orders ON payments_orders.payment_id = payments.id 
		GROUP BY payments.id 
		ORDER BY orders_count DESC LIMIT 1
		) AS most_pop_payment;


--14.Удалить пустые категории.
DELETE FROM categories
WHERE id NOT IN ( SELECT category_id FROM products);


--15.Вывести список пользователей(опечатка заказов), которые были оплачены полностью не более чем через час, с момента добавления первого товара в корзину.
SELECT orders.id
FROM orders LEFT JOIN payments_orders ON payments_orders.order_id = orders.id
LEFT JOIN basket ON basket.order_id = orders.id
WHERE orders.price IN (SELECT SUM(payments_orders.value) FROM payments_orders WHERE payments_orders.order_id = orders.id)
AND (SELECT date_part('hour', (SELECT MAX(payments_orders.create_at)-MIN(basket.create_at) FROM payments_orders, basket))) <= 1;
GROUP BY orders.id;


--16.Вернуть все деньги пользователей на внутренний счет для заказов, которые были оплачены (как внутренним счетом, так и некоторым 
--способом оплаты) и были отменены (status = "С").
UPDATE accounts
SET value =  value + return_money.sum
FROM 	(
		SELECT orders.id , orders.user_id AS user_id, orders.price, SUM(payments_orders.value)
		FROM orders LEFT JOIN payments_orders ON payments_orders.order_id = orders.id 
		WHERE orders.status = 'C'
		GROUP BY orders.id
		HAVING orders.price=SUM(payments_orders.value) 
		) AS  return_money
WHERE accounts.user_id = return_money.user_id;