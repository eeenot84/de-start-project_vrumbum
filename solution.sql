-- Этап 1. Создание и заполнение БД
--Создание схемы raw_data
CREATE SCHEMA IF NOT EXISTS raw_data;

--Создание таблицы sales
CREATE TABLE raw_data.sales (
    id SERIAL PRIMARY KEY,
    auto VARCHAR(100) NOT NULL,
    gasoline_consumption DECIMAL(5,2),
    price NUMERIC(10,2) NOT NULL,
    date DATE NOT NULL,
    person_name VARCHAR(100) NOT NULL,
    phone VARCHAR(20) NOT NULL,
    discount NUMERIC(5,2) DEFAULT 0,
    brand_origin VARCHAR(50)
);

--Создание схемы car_shop
CREATE SCHEMA IF NOT EXISTS car_shop;

-- Таблица брендов
CREATE TABLE car_shop.brand (
    brand_id SERIAL PRIMARY KEY,
    brand_name VARCHAR(50) NOT NULL, -- название бренда (например: Lada, BMW)
    brand_origin VARCHAR(50) NOT NULL, -- страна происхождения бренда
    UNIQUE (brand_name, brand_origin) -- запрет на дубликаты брендов из одной страны
);

-- Таблица цветов
CREATE TABLE car_shop.color (
    color_id SERIAL PRIMARY KEY,
    color_name VARCHAR(30) NOT NULL, -- название цвета (например: red, grey)
    UNIQUE (color_name)
);

-- Таблица автомобилей
CREATE TABLE car_shop.auto (
    auto_id SERIAL PRIMARY KEY,
    auto_name VARCHAR(100) NOT NULL, -- модель автомобиля без бренда (например: Vesta, F80)
    brand_id INTEGER NOT NULL REFERENCES car_shop.brand(brand_id),
    gasoline_consumption DECIMAL(5,2), -- расход бензина в литрах (может быть NULL для электрокаров)
    UNIQUE (auto_name, brand_id) -- один бренд не может продавать 2 одинаковых модели
);

-- Связующая таблица цвет <-> автомобиль (многие ко многим)
CREATE TABLE car_shop.auto_color (
    auto_id INTEGER NOT NULL REFERENCES car_shop.auto(auto_id),
    color_id INTEGER NOT NULL REFERENCES car_shop.color(color_id),
    PRIMARY KEY (auto_id, color_id)
);

-- Таблица клиентов
CREATE TABLE car_shop.client (
    client_id SERIAL PRIMARY KEY,
    person_name VARCHAR(100) NOT NULL, -- имя и фамилия покупателя
    phone VARCHAR(30) NOT NULL,
    UNIQUE (person_name, phone)
);

-- Таблица заказов
CREATE TABLE car_shop.sale_order (
    order_id SERIAL PRIMARY KEY,
    auto_id INTEGER NOT NULL REFERENCES car_shop.auto(auto_id),
    client_id INTEGER NOT NULL REFERENCES car_shop.client(client_id),
    color_id INTEGER NOT NULL REFERENCES car_shop.color(color_id),
    price NUMERIC(10,2) NOT NULL CHECK (price > 0), -- цена со скидкой
    date DATE NOT NULL, -- дата покупки
    discount NUMERIC(5,2) DEFAULT 0 CHECK (discount >= 0 AND discount <= 100) -- скидка в процентах
);

--Вставляем данные в таблицу
-- Вставка брендов
INSERT INTO car_shop.brand (brand_name, brand_origin)
SELECT DISTINCT
    split_part(split_part(auto, ',', 1), ' ', 1) AS brand,
    brand_origin
FROM raw_data.sales
WHERE brand_origin IS NOT NULL;

-- Вставка цветов
INSERT INTO car_shop.color (color_name)
SELECT DISTINCT
    trim(split_part(auto, ',', 2)) AS color
FROM raw_data.sales;

-- Вставка авто
INSERT INTO car_shop.auto (auto_name, gasoline_consumption, brand_id)
SELECT DISTINCT
    trim(substring(split_part(auto, ',', 1) FROM position(' ' IN split_part(auto, ',', 1)) + 1)) AS auto_name,
    gasoline_consumption,
    b.brand_id
FROM raw_data.sales s
JOIN car_shop.brand b
  ON split_part(split_part(s.auto, ',', 1), ' ', 1) = b.brand_name
 AND s.brand_origin = b.brand_origin;

-- Вставка связей авто <-> цвет
INSERT INTO car_shop.auto_color (auto_id, color_id)
SELECT DISTINCT
    a.auto_id,
    c.color_id
FROM raw_data.sales s
JOIN car_shop.brand b
  ON split_part(split_part(s.auto, ',', 1), ' ', 1) = b.brand_name
 AND s.brand_origin = b.brand_origin
JOIN car_shop.auto a
  ON trim(substring(split_part(s.auto, ',', 1) FROM position(' ' IN split_part(s.auto, ',', 1)) + 1)) = a.auto_name
 AND a.brand_id = b.brand_id
JOIN car_shop.color c
  ON trim(split_part(s.auto, ',', 2)) = c.color_name;

-- Вставка клиентов
INSERT INTO car_shop.client (person_name, phone)
SELECT DISTINCT person_name, phone
FROM raw_data.sales;

-- Вставка заказов
INSERT INTO car_shop.sale_order (auto_id, client_id, color_id, price, date, discount)
SELECT
    a.auto_id,
    cl.client_id,
    c.color_id,
    s.price,
    s.date,
    s.discount
FROM raw_data.sales s
JOIN car_shop.brand b
  ON split_part(split_part(s.auto, ',', 1), ' ', 1) = b.brand_name
 AND s.brand_origin = b.brand_origin
JOIN car_shop.auto a
  ON trim(substring(split_part(s.auto, ',', 1) FROM position(' ' IN split_part(s.auto, ',', 1)) + 1)) = a.auto_name
 AND a.brand_id = b.brand_id
JOIN car_shop.color c
  ON trim(split_part(s.auto, ',', 2)) = c.color_name
JOIN car_shop.client cl
  ON s.person_name = cl.person_name AND s.phone = cl.phone;


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


---- Задание 6. Напишите запрос, который покажет количество всех пользователей из США.
SELECT COUNT(*) AS persons_from_usa_count
FROM car_shop.client
WHERE phone LIKE '+1%';


