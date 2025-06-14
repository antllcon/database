-- Теоретические задания
-- 1. Что такое НФБК?
-- 2. Что такое B+ дерево (свойства)?
-- 3. Как работает NULL в SQL, логические и арифметические операции?
-- 4. Какие виды подзапросов существуют?
-- 5. Как устроена база данных Entity-Attribute-Value?

-- Практическое задание
SHOW DATABASES;
CREATE DATABASE shop;
DROP DATABASE shop;
USE shop;

SHOW TABLES;

CREATE TABLE category
(
    id   INT UNSIGNED NOT NULL AUTO_INCREMENT,
    name VARCHAR(255) NOT NULL,
    path VARCHAR(255) NOT NULL,

    PRIMARY KEY (id),
    UNIQUE INDEX idx_unique_path (path)
)
    ENGINE = InnoDB
    CHARACTER SET = utf8mb4
    COLLATE utf8mb4_unicode_ci
;



CREATE TABLE product
(
    id          INT UNSIGNED NOT NULL AUTO_INCREMENT,
    name        VARCHAR(255) NOT NULL,
    category_id INT UNSIGNED NOT NULL,

    PRIMARY KEY (id)
)
    ENGINE = InnoDB
    CHARACTER SET = utf8mb4
    COLLATE utf8mb4_unicode_ci
;

CREATE TABLE product_field
(
    id         INT UNSIGNED          NOT NULL AUTO_INCREMENT,
    product_id INT UNSIGNED          NOT NULL,
    name       VARCHAR(255)          NOT NULL,
    type       ENUM ('text', 'list') NOT NULL,

    PRIMARY KEY (id),
    FOREIGN KEY (product_id) REFERENCES product (id) ON DELETE CASCADE
)
    ENGINE = InnoDB
    CHARACTER SET = utf8mb4
    COLLATE utf8mb4_unicode_ci
;

# Тут храним значение для поля текста
CREATE TABLE product_field_value
(
    id         INT UNSIGNED NOT NULL AUTO_INCREMENT,
    field_id   INT UNSIGNED NOT NULL,
    text_value TEXT,

    PRIMARY KEY (id),
    FOREIGN KEY (field_id) REFERENCES product_field (id) ON DELETE CASCADE
)
    ENGINE = InnoDB
    CHARACTER SET = utf8mb4
    COLLATE utf8mb4_unicode_ci
;

# Тут храним значения для поля списка
CREATE TABLE product_field_list_item
(
    id       INT UNSIGNED NOT NULL AUTO_INCREMENT,
    field_id INT UNSIGNED NOT NULL,
    value    VARCHAR(255) NOT NULL,

    PRIMARY KEY (id),
    FOREIGN KEY (field_id) REFERENCES product_field (id) ON DELETE CASCADE
)
    ENGINE = InnoDB
    CHARACTER SET = utf8mb4
    COLLATE utf8mb4_unicode_ci
;

CREATE TABLE user
(
    id       INT UNSIGNED NOT NULL AUTO_INCREMENT,
    name     VARCHAR(255) NOT NULL,
    number   VARCHAR(255) NOT NULL,
    is_admin TINYINT(1) DEFAULT 0,

    PRIMARY KEY (id),
    UNIQUE INDEX idx_number (number)
)
    ENGINE = InnoDB
    CHARACTER SET = utf8mb4
    COLLATE utf8mb4_unicode_ci
;

CREATE TABLE basket
(
    id      INT UNSIGNED NOT NULL AUTO_INCREMENT,
    user_id INT UNSIGNED NOT NULL,

    PRIMARY KEY (id),
    UNIQUE INDEX idx_user_id (user_id),
    FOREIGN KEY (user_id) REFERENCES user (id) ON DELETE CASCADE
)
    ENGINE = InnoDB
    CHARACTER SET = utf8mb4
    COLLATE utf8mb4_unicode_ci
;

CREATE TABLE basket_item
(
    id         INT UNSIGNED NOT NULL AUTO_INCREMENT,
    basket_id  INT UNSIGNED NOT NULL,
    product_id INT UNSIGNED NOT NULL,
    quantity   INT UNSIGNED NOT NULL DEFAULT 1 CHECK (quantity > 0),

    PRIMARY KEY (id),
    UNIQUE INDEX idx_cart_product (basket_id, product_id),
    FOREIGN KEY (basket_id) REFERENCES basket (id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES product (id) ON DELETE CASCADE
)
    ENGINE = InnoDB
    CHARACTER SET = utf8mb4
    COLLATE utf8mb4_unicode_ci
;

TRUNCATE TABLE category;
SELECT *
FROM category;
INSERT INTO category (id, name, path)
VALUES (1, 'Продукты', '1/'),
       (2, 'Белок', '1/2/'),
       (3, 'Клетчатка', '1/3/'),
       (4, 'Зерновые', '1/4/'),
       (5, 'Мясо животное', '1/2/5/'),
       (6, 'Молочные продукты', '1/2/6/'),
       (7, 'Яйца', '1/2/7/'),
       (8, 'Овощи', '1/3/8/'),
       (9, 'Фрукты', '1/3/9/'),
       (10, 'Хлеб', '1/4/10/'),
       (11, 'Крупы', '1/4/11/'),
       (12, 'Сыр', '1/2/6/12/'),
       (13, 'Молоко', '1/2/6/13/')
;

TRUNCATE TABLE product;
SELECT *
FROM product;
INSERT INTO product (id, name, category_id)
VALUES (1, 'Стейк из говядины', 5),
       (2, 'Куриное филешка', 5),
       (3, 'Сыр Россикий', 12),
       (4, 'Молоко yola', 13),
       (5, 'Яйца куриные C0', 7),
       (6, 'Морковь красная', 8),
       (7, 'Яблоки Царские', 9),
       (8, 'Бородинский хлеб', 10),
       (9, 'Греча', 11)
;

SELECT *
FROM product_field;

SELECT *
FROM product_field_value;
TRUNCATE TABLE product_field_value;
SELECT *
FROM product_field_list_item;
TRUNCATE TABLE product_field_list_item;

-- Стейк из говядины
INSERT INTO product_field (id, product_id, name, type)
VALUES (1, 1, 'Вес', 'text');
INSERT INTO product_field_value (id, field_id, text_value)
VALUES (1, 1, '500г');
INSERT INTO product_field (id, product_id, name, type)
VALUES (2, 1, 'Производитель', 'text');
INSERT INTO product_field_value (id, field_id, text_value)
VALUES (2, 2, 'Фермерское хозяйство');

-- Куриное филешка
INSERT INTO product_field (id, product_id, name, type)
VALUES (3, 2, 'Упаковка', 'list');
INSERT INTO product_field_list_item (id, field_id, value)
VALUES (1, 3, 'Вакуумная');
INSERT INTO product_field_list_item (id, field_id, value)
VALUES (2, 3, 'Лоток');
INSERT INTO product_field (id, product_id, name, type)
VALUES (4, 2, 'Срок годности', 'text');
INSERT INTO product_field_value (id, field_id, text_value)
VALUES (3, 4, '7 дней');

-- Сыр Российский
INSERT INTO product_field (id, product_id, name, type)
VALUES (5, 3, 'Жирность', 'text');
INSERT INTO product_field_value (id, field_id, text_value)
VALUES (4, 5, '50%');
INSERT INTO product_field (id, product_id, name, type)
VALUES (6, 3, 'Тип', 'list');
INSERT INTO product_field_list_item (id, field_id, value)
VALUES (3, 6, 'Твердый');
INSERT INTO product_field_list_item (id, field_id, value)
VALUES (4, 6, 'Полутвердый');

-- Молоко yola
INSERT INTO product_field (id, product_id, name, type)
VALUES (7, 4, 'Объем', 'text');
INSERT INTO product_field_value (id, field_id, text_value)
VALUES (5, 7, '1 л');
INSERT INTO product_field (id, product_id, name, type)
VALUES (8, 4, 'Жирность', 'text');
INSERT INTO product_field_value (id, field_id, text_value)
VALUES (6, 8, '3.2%');

-- Яйца куриные C0
INSERT INTO product_field (id, product_id, name, type)
VALUES (9, 5, 'Количество в упаковке', 'text');
INSERT INTO product_field_value (id, field_id, text_value)
VALUES (7, 9, '10 шт.');
INSERT INTO product_field (id, product_id, name, type)
VALUES (10, 5, 'Категория', 'text');
INSERT INTO product_field_value (id, field_id, text_value)
VALUES (8, 10, 'C0');

-- Морковь красная
INSERT INTO product_field (id, product_id, name, type)
VALUES (11, 6, 'Происхождение', 'text');
INSERT INTO product_field_value (id, field_id, text_value)
VALUES (9, 11, 'Россия');
INSERT INTO product_field (id, product_id, name, type)
VALUES (12, 6, 'Сорт', 'text');
INSERT INTO product_field_value (id, field_id, text_value)
VALUES (10, 12, 'Нантская');

-- Яблоки Царские
INSERT INTO product_field (id, product_id, name, type)
VALUES (13, 7, 'Сорт', 'text');
INSERT INTO product_field_value (id, field_id, text_value)
VALUES (11, 13, 'Фуджи');
INSERT INTO product_field (id, product_id, name, type)
VALUES (14, 7, 'Цвет', 'text');
INSERT INTO product_field_value (id, field_id, text_value)
VALUES (12, 14, 'Красный');

-- Бородинский хлеб
INSERT INTO product_field (id, product_id, name, type)
VALUES (15, 8, 'Вес', 'text');
INSERT INTO product_field_value (id, field_id, text_value)
VALUES (13, 15, '400г');
INSERT INTO product_field (id, product_id, name, type)
VALUES (16, 8, 'Тип муки', 'text');
INSERT INTO product_field_value (id, field_id, text_value)
VALUES (14, 16, 'Ржаная');

-- Греча
INSERT INTO product_field (id, product_id, name, type)
VALUES (17, 9, 'Производитель', 'text');
INSERT INTO product_field_value (id, field_id, text_value)
VALUES (15, 17, 'Увелка');
INSERT INTO product_field (id, product_id, name, type)
VALUES (18, 9, 'Объем упаковки', 'text');
INSERT INTO product_field_value (id, field_id, text_value)
VALUES (16, 18, '900г');


SELECT *
FROM user;

INSERT INTO user (id, name, number, is_admin)
VALUES (1, 'Иван Иваныч', '+79001234567', 0),
       (2, 'Степан Глухарев', '+79194196248', 1),
       (3, 'Петр Петров', '+79777777777', 0);

SELECT *
FROM basket;

INSERT INTO basket (id, user_id)
VALUES (1, 1),
       (2, 2),
       (3, 3);

SELECT *
FROM basket_item;

INSERT INTO basket_item (id, basket_id, product_id, quantity)
VALUES (1, 1, 1, 1),
       (2, 1, 7, 3),
       (3, 1, 4, 2),
       (4, 2, 2, 2),
       (5, 2, 6, 5),
       (6, 2, 8, 1),
       (7, 3, 3, 1),
       (8, 3, 9, 2),
       (9, 3, 5, 1);

-- Запросы

-- Регистрация
INSERT INTO user (name, number, is_admin)
VALUES ('Вася Пупкин', '+79777777777', 0);

-- Получаю все категории, которые могут быть
SELECT p.id   AS product_id,
       p.name AS product_name,
       c.name AS category_name,
       c.path AS category_path
FROM product AS p
         JOIN
     category AS c ON p.category_id = c.id
WHERE c.path LIKE (SELECT CONCAT(path, '%') FROM category WHERE name = 'Белок');

-- Посмотреть корзину пользователя
SET @user_id_to_view = 2;
EXPLAIN SELECT u.name AS user_name,
       p.name AS product_name,
       bi.quantity
FROM user AS u
         JOIN
     basket AS b ON u.id = b.user_id
         JOIN
     basket_item AS bi ON b.id = bi.basket_id
         JOIN
     product AS p ON bi.product_id = p.id
WHERE u.id = @user_id_to_view;

# Параметры вспомогательные
SET @user_id_param = 2;
SET @product_id_param = 9;
SET @quantity_to_add_param = 5;
SET @quantity_to_remove_param = 4;

-- Создание корзины (если нет)
INSERT IGNORE INTO basket (user_id)
VALUES (@user_id_param);

-- Получить id корзины
SET @basket_id_for_user = (SELECT id
                           FROM basket
                           WHERE user_id = @user_id_param)
;

-- Добавить товар в корзину или обновить его количество, если он уже там
INSERT INTO basket_item (basket_id, product_id, quantity)
VALUES (@basket_id_for_user, @product_id_param, @quantity_to_add_param)
ON DUPLICATE KEY UPDATE quantity = quantity + VALUES(quantity)
;

-- Удаление товара, если он есть
-- обновляем
UPDATE basket_item
SET quantity = quantity - @quantity_to_remove_param
WHERE basket_id = @basket_id_for_user
  AND product_id = @product_id_param;
-- удаляем если 0
DELETE
FROM basket_item
WHERE basket_id = @basket_id_for_user
  AND product_id = @product_id_param
  AND quantity <= 0;


-- Поиск по слову или части слова для поиска
SET @search_term = 'Мя';
SELECT p.id   AS product_id,
       p.name AS product_name,
       c.name AS category_name
FROM product AS p
         JOIN
     category AS c ON p.category_id = c.id
WHERE p.name LIKE CONCAT('%', @search_term, '%') COLLATE utf8mb4_unicode_ci;
SELECT * FROM product;

-- Обновление значения поля продукта, только если пользователь является администратором
SET @user_id_making_change = 2;
SET @product_field_value_id_to_update = 1;
SET @new_text_value = '600г';
UPDATE product_field_value AS pfv
    JOIN product_field AS pf ON pfv.field_id = pf.id
    JOIN product AS p ON pf.product_id = p.id
    -- user для проверки роли
    JOIN user AS u ON u.id = @user_id_making_change
SET
    pfv.text_value = @new_text_value
WHERE
    pfv.id = @product_field_value_id_to_update AND
    u.is_admin = 1;

-- Изменение list
SET @admin_user_id = 2; -- админ
SET @list_item_id_to_update = 1; -- ID элемента
SET @new_list_item_value = 'Вакуумная упаковка'; -- Новое значение
UPDATE product_field_list_item AS pfli
    JOIN product_field AS pf ON pfli.field_id = pf.id
    JOIN product AS p ON pf.product_id = p.id
    JOIN user AS u ON u.id = @admin_user_id
SET
    pfli.value = @new_list_item_value
WHERE
    pfli.id = @list_item_id_to_update AND
    pf.type = 'list' AND
    u.is_admin = 1;

-- Добавить новое значение в поле типа list
SET @target_field_id = 3;
SET @new_item_to_add = 'Пакет';
INSERT INTO product_field_list_item (field_id, value)
SELECT @target_field_id, @new_item_to_add
FROM product_field AS pf
         JOIN user AS u ON u.id = @admin_user_id
WHERE
    pf.id = @target_field_id AND
    pf.type = 'list' AND
    u.is_admin = 1;