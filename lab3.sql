--Поляков Илья, 31 группа


--1.Написать представление, которое будет выводить список пользователей и их средний чек для выполненных заказов(login пользователя, средний чек)
CREATE VIEW avg_checks AS 
SELECT 	users.login as user,
		AVG(orders.price) as avg_check
FROM users JOIN orders ON orders.user_id = users.id AND orders.status='F'
GROUP BY users.login;


--2.Написать пользовательскую функцию, которая будет списывать сумму с вашего счета, если это возможно (входные параметры - login пользователя, сумма,
--  возвращаемое значение - остаток на счете)
CREATE OR REPLACE FUNCTION pay(login varchar, value money) 
RETURNS money  AS $$ 
DECLARE a_value money;
BEGIN
	SELECT accounts.value INTO a_value
	FROM users JOIN accounts ON accounts.user_id = users.id
		WHERE users.login = $1;
	IF a_value < $2 THEN 
		RAISE EXCEPTION 'Error';
	ELSE 
		UPDATE accounts SET value = a_value - $2
		WHERE accounts.user_id = (SELECT users.id FROM users WHERE users.login = $1);
		RETURN a_value - $2;
	END IF;
END;
$$ LANGUAGE plpgsql;


--3.Написать хранимую процедуру, которая будет рассчитывать сумму заказа пользователя и скидку на заказ, исходя из стоимости доставки (если таковая имеется) и 
--  стоимости товаров в корзине.
CREATE PROCEDURE order_sum(order_id INT) RETURNS money AS $$
DECLARE o_price MONEY, d_price MONEY;
BEGIN
	SELECT SUM(basket.price), d.price INTO o_price, d_price
	FROM orders
	LEFT JOIN basket 					ON basket.order_id = orders.id
	LEFT JOIN delivery_orders 	AS d_o 	ON d_o.order_id = orders.id
	LEFT JOIN delivery 			AS d 	ON d_o.delivery_id = d.id
	WHERE order.id = $1
	GROUP BY d.price;
	UPDATE orders SET price = o_price + d_price
	WHERE orders.id = $1;
	RETURN NEXT o_price;
	RETURN NEXT d_price;
	RETURN;
END;
$$ LANGUAGE plpgsql;


--4.Написать триггер, который будет пересчитывать сумму заказа пользователя и скидку на заказ, при изменении корзины товаров в заказе.
CREATE FUNCTION func_order_sum_update() RETURNS trigger AS $$
BEGIN
	EXECUTE PROCEDURE order_sum(NEW.id)
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER  func_order_sum_update() 
AFTER UPDATE ON basket 
FOR EACH STATEMENT
EXECUTE FUNCTION  func();


--5.Написать триггер, который будет устанавливать статус заказа "Оплачен", если заказ полностью оплачен, и списывать с остатков на складе то количество товара,
--	которое было в заказе.

CREATE FUNCTION func_order_update() RETURNS trigger AS $$ 
DECLARE pay BOOLEAN;
BEGIN
	SELECT (orders.price = SUM(payment_order.value)) INTO pay
	FROM orders RIGHT JOIN payments_orders ON payments_order.order_id = orders.id
	WHERE orders.id = NEW.id
	GROUP BY orders.id;
	IF pay THEN
		UPDATE orders 	SET status = 'P' WHERE orders.id = NEW.id;
		UPDATE products SET quantity = quantity - pay_basket.quantity
		FROM
			(SELECT baskets.quantity, product_id
			FROM  baskets
			WHERE baskets.order_id = NEW.id AND baskets.product_id = products.id
			) AS pay_basket
		WHERE products.id=pay_basket.product_id;
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER order_update
AFTER ISERT OR UPDATE OF payments_orders ON orders
FOR EACH ROW
EXECUTE FUNCTION func_order_update();

--6.Написать запрос, используя оконную функцию, который для заданного пользователя (login) будет выводить прогресс по сумме его выполненных заказов 
--	(каждая строка должна содержать 3 столбца: login пользователя, сумму заказа и сумму заказов начиная с первого до текущего (прогрессирующая сумма)).
SELECT users.login, orders.price,
SUM(order.price) OVER (
PARTITION BY users.login ORDER BY orders.create_at ASC) AS sums
FROM orders LEFT JOIN users ON orders.user_id = users.id
ORDER BY users.login ASC;

