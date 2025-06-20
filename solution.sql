-- Этап 1. Создание и заполнение БД



-- Этап 2. Создание выборок

---- Задание 1. Напишите запрос, который выведет процент моделей машин, у которых нет параметра `gasoline_consumption`.
SELECT
  ROUND(
    COUNT(*) FILTER (WHERE gasoline_consumption IS NULL) * 100.0 / COUNT(*),
    2
  ) AS nulls_percentage_gasoline_consumption
FROM car_shop.auto;


---- Задание 2. Напишите запрос, который покажет название бренда и среднюю цену его автомобилей в разбивке по всем годам с учётом скидки.
SELECT
  b.brand_origin AS brand_name,
  EXTRACT(YEAR FROM so.date) AS year,
  ROUND(AVG(so.price * (1 - so.discount / 100.0)), 2) AS price_avg
FROM car_shop.sale_order AS so
JOIN car_shop.auto AS a ON so.auto_id = a.auto_id
JOIN car_shop.brand AS b ON a.brand_id = b.brand_id
GROUP BY b.brand_origin, EXTRACT(YEAR FROM so.date)
ORDER BY b.brand_origin, year;


---- Задание 3. Посчитайте среднюю цену всех автомобилей с разбивкой по месяцам в 2022 году с учётом скидки.
SELECT
  EXTRACT(MONTH FROM so.date) AS month,
  EXTRACT(YEAR FROM so.date) AS year,
  ROUND(AVG(so.price * (1 - so.discount / 100.0)), 2) AS price_avg
FROM car_shop.sale_order AS so
WHERE EXTRACT(YEAR FROM so.date) = 2022
GROUP BY year, month
ORDER BY month;

---- Задание 4. Используя функцию STRING_AGG, напишите запрос,
-- который выведет список купленных машин у каждого пользователя через запятую.
-- Пользователь может купить две одинаковые машины — это нормально.
-- Название машины покажите полное, с названием бренда — например: Tesla Model 3.
-- Отсортируйте по имени пользователя в восходящем порядке. Сортировка внутри самой строки с машинами не нужна.
SELECT
  c.person_name AS person,
  STRING_AGG(b.brand_origin || ' ' || a.auto_name, ', ') AS cars
FROM car_shop.sale_order AS so
JOIN car_shop.client AS c ON so.client_id = c.client_id
JOIN car_shop.auto AS a ON so.auto_id = a.auto_id
JOIN car_shop.brand AS b ON a.brand_id = b.brand_id
GROUP BY c.person_name
ORDER BY c.person_name;

---- Задание 4. Напишите запрос, который выведет список купленных машин у каждого пользователя.

---- Задание 5. Напишите запрос,
-- который вернёт самую большую и самую маленькую цену продажи автомобиля с разбивкой по стране без учёта скидки.
-- Цена в колонке price дана с учётом скидки.
SELECT
  b.brand_origin,
  MAX(so.price) AS price_max,
  MIN(so.price) AS price_min
FROM car_shop.sale_order AS so
JOIN car_shop.auto AS a ON so.auto_id = a.auto_id
JOIN car_shop.brand AS b ON a.brand_id = b.brand_id
GROUP BY b.brand_origin
ORDER BY b.brand_origin;

--Новая версия запроса цена без скидки
SELECT
  b.brand_origin,
  -- Расчёт цены без скидки
  MAX(ROUND(so.price / (1 - so.discount / 100.0), 2)) AS base_price_max,
  MIN(ROUND(so.price / (1 - so.discount / 100.0), 2)) AS base_price_min
FROM car_shop.sale_order AS so
JOIN car_shop.auto AS a ON so.auto_id = a.auto_id
JOIN car_shop.brand AS b ON a.brand_id = b.brand_id
GROUP BY b.brand_origin
ORDER BY b.brand_origin;

---- Задание 5. Напишите запрос, который покажет количество всех пользователей из США.

---- Задание 6. Напишите запрос, который покажет количество всех пользователей из США.
SELECT COUNT(*) AS persons_from_usa_count
FROM car_shop.client
WHERE phone LIKE '+1%';


