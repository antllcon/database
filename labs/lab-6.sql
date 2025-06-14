
DROP DATABASE test;
SHOW DATABASES;
CREATE DATABASE test;
USE test;

CREATE TABLE directory
(
    id   INT UNSIGNED NOT NULL AUTO_INCREMENT,
    name VARCHAR(255) NOT NULL,
    path VARCHAR(255) NOT NULL,
    PRIMARY KEY (id),
    INDEX idx_path (path)
)
    ENGINE = InnoDB
    CHARACTER SET = utf8mb4
    COLLATE utf8mb4_unicode_ci
;

INSERT INTO directory (id, name, path)
VALUES (1, 'root', '1');
INSERT INTO directory (id, name, path)
VALUES (2, 'home', '1.2');
INSERT INTO directory (id, name, path)
VALUES (3, 'etc', '1.3');
INSERT INTO directory (id, name, path)
VALUES (4, 'var', '1.4');
INSERT INTO directory (id, name, path)
VALUES (5, 'antllcon', '1.2.5');
INSERT INTO directory (id, name, path)
VALUES (6, 'stepan', '1.2.6');
INSERT INTO directory (id, name, path)
VALUES (7, 'log', '1.4.7');
INSERT INTO directory (id, name, path)
VALUES (8, 'www', '1.4.8');
INSERT INTO directory (id, name, path)
VALUES (9, 'documents', '1.2.5.9');
INSERT INTO directory (id, name, path)
VALUES (10, 'pictures', '1.2.5.10');
INSERT INTO directory (id, name, path)
VALUES (11, 'nginx', '1.4.8.11');

-- Извлечение поддерева целиком у узла
SELECT child.id, child.name, child.path
FROM directory AS parent
         JOIN directory AS child ON child.path LIKE CONCAT(parent.path, '%')
WHERE parent.id = 4
ORDER BY child.path
;

-- Извлечение данных конкретного листа
SELECT id, name, path
FROM directory
WHERE id = 10
  AND NOT EXISTS (SELECT 1 FROM directory AS sub_dir WHERE sub_dir.path LIKE CONCAT(directory.path, '.%'));

-- Вывод списка родителей для конкретного узла
SELECT parent.id, parent.name, parent.path
FROM directory AS child
         JOIN directory AS parent ON child.path LIKE CONCAT(parent.path, '.%')
WHERE child.id = 9
ORDER BY parent.path
;

-- Вывод братьев или сестер, нужно делать для конкретного id
SELECT id, name, path
FROM directory
WHERE
  -- путь родителя
    path LIKE '1.2.%'
  -- ограничение снизу
  AND path NOT LIKE '1.2.%.%'
;

-- Удаление узла и всех его потомков
DELETE child
FROM directory AS parent
         JOIN directory AS child ON child.path LIKE CONCAT(parent.path, '%')
WHERE parent.id = 4
;

-- Вставка 3 элементов в одного родителя
INSERT INTO directory (name, path)
VALUES ('projects', '1.2.5.12');
INSERT INTO directory (name, path)
VALUES ('downloads', '1.2.5.13');
INSERT INTO directory (name, path)
VALUES ('music', '1.2.5.14');

-- Удаление 2 элементов
DELETE
FROM directory
WHERE id IN (13, 14)
;

SELECT *
FROM directory;

SET @node_to_move_id = 6;
SET @new_parent_id = 10;

SELECT path INTO @old_path FROM directory WHERE id = @node_to_move_id;
SELECT path INTO @new_parent_path FROM directory WHERE id = @new_parent_id;

SET @new_path = CONCAT(@new_parent_path, '.', @node_to_move_id);

UPDATE directory
SET path = CONCAT(@new_path, SUBSTRING(path, LENGTH(@old_path) + 1))
WHERE path = @old_path
   OR path LIKE CONCAT(@old_path, '.%');

SELECT *
FROM directory;

# Представление извлечения поддерева
CREATE VIEW subtree_view AS
SELECT parent.id   AS parent_id,
       parent.name AS parent_name,
       child.id    AS child_id,
       child.name  AS child_name,
       child.path  AS child_path
FROM directory AS parent
         JOIN directory AS child ON child.path LIKE CONCAT(parent.path, '%')
ORDER BY parent.id, child.path;

# Функция извлечения поддерева
DELIMITER $$
CREATE FUNCTION get_subtree_json(root_id INT UNSIGNED)
    RETURNS JSON
    DETERMINISTIC
    READS SQL DATA
BEGIN
    DECLARE root_path VARCHAR(255) UNICODE;
    SELECT path INTO root_path FROM directory WHERE id = root_id;

    IF root_path IS NULL THEN
        RETURN JSON_ARRAY();
    END IF;

    RETURN (SELECT JSON_ARRAYAGG(
                           JSON_OBJECT('id', id, 'name', name, 'path', path)
                   )
            FROM directory
            WHERE path LIKE CONCAT(root_path, '%'));
END$$
DELIMITER ;

# Процедура извлечения поддерева
DELIMITER $$
CREATE PROCEDURE get_subtree(IN root_id INT UNSIGNED)
BEGIN
    SELECT child.id,
           child.name,
           child.path
    FROM directory AS parent
             JOIN
         directory AS child ON child.path LIKE CONCAT(parent.path, '%')
    WHERE parent.id = root_id
    ORDER BY child.path;
END$$
DELIMITER ;

SELECT * FROM subtree_view WHERE parent_id = 4;
SELECT get_subtree_json(4) AS size;
CALL get_subtree(4);

DROP VIEW IF EXISTS subtree_view;
DROP FUNCTION IF EXISTS get_subtree_json;
DROP PROCEDURE IF EXISTS get_subtree;

# Задание №3
-- Создайте таблицу для хранения полей профиля пользователя в формате JSON.
-- Набор полей у разных пользователей может быть разным, но есть поля,
-- которые обязательно есть у всех пользователей, как минимум 3, например first_name, last_name, login.
-- Для этой таблицы оформите следующие операции в SQL запросах:

-- Добавить пользователя с полями профиля
-- Извлечь last_name у группы пользователей
-- Обновить first_name у группы пользователей
-- Добавьте индекс по полю login
-- Сохраните массив номеров телефонов, извлеките крайний номер телефона
-- Реализуйте поиск по массиву номеров телефонов среди списка пользователей

CREATE TABLE user_json
(
    id        INT UNSIGNED AUTO_INCREMENT,
    user_data JSON,
    PRIMARY KEY (id)
)
    ENGINE = InnoDB
    CHARACTER SET = utf8mb4
    COLLATE utf8mb4_unicode_ci
;

INSERT INTO user_json (user_data)
VALUES ('{
  "login": "ficus",
  "first_name": "Фикус",
  "last_name": "Пикус",
  "email": "superpochta@mail.com",
  "city": "Москва",
  "phone_numbers": [
    "+79161234567",
    "+74957654321"
  ]
}');

INSERT INTO user_json (user_data)
VALUES ('{
  "login": "sus",
  "first_name": "Илья",
  "last_name": "Пупкин",
  "city": "Санкт-Петербург",
  "phone_numbers": [
    "+79219876543"
  ]
}');

INSERT INTO user_json (user_data)
VALUES ('{
  "login": "apple",
  "first_name": "Петр",
  "last_name": "Иванов",
  "email": "petka@ya.com",
  "status": "active",
  "phone_numbers": [
    "+79031112233"
  ]
}');

SELECT *
FROM user_json;

SELECT user_data ->> '$.last_name'
FROM user_json;

UPDATE user_json
SET user_data = JSON_SET(
        user_data,
        '$.first_name', 'Человек',
        '$.last_name', 'Человекоич'
                )
WHERE user_data ->> '$.login' = 'apple';

CREATE INDEX idx_user_json_login ON user_json (
    (CAST(user_data ->> '$.login' AS CHAR(255)))
    );

SELECT user_data ->> '$.phone_numbers[last]'
FROM user_json
WHERE user_data ->> '$.login' = 'ficus';

SELECT user_data ->> '$.login',
       user_data ->> '$.first_name',
       user_data ->> '$.last_name'
FROM user_json
WHERE JSON_CONTAINS(user_data, '"+79219876543"', '$.phone_numbers');

DROP DATABASE test;

# Задание №4
-- Придумайте последовательность SQL запросов для возникновения deadlock в базе данных с деревьями,
-- продемонстрируйте преподавателю и объясните почему так получилось.

CREATE TABLE folder
(
    id   INT UNSIGNED NOT NULL AUTO_INCREMENT,
    name TEXT         NOT NULL,
    icon TEXT         NULL,
    PRIMARY KEY (id)
)
    ENGINE = InnoDB
    DEFAULT CHARSET = utf8mb4
    COLLATE = utf8mb4_unicode_ci
;

CREATE TABLE folder_tree_item
(
    id   INT UNSIGNED NOT NULL AUTO_INCREMENT,
    path VARCHAR(255) NOT NULL,
    PRIMARY KEY (id)
)
    ENGINE = InnoDB
    DEFAULT CHARSET = utf8mb4
    COLLATE = utf8mb4_unicode_ci
;

INSERT INTO folder (name)
VALUES ('root'),
       ('child A'),
       ('child B');

INSERT INTO folder_tree_item (path)
VALUES ('1'),
       ('1/2'),
       ('1/3');

SELECT *
FROM folder;
SELECT *
FROM folder_tree_item;

-- сессия 1
USE test;
START TRANSACTION;
UPDATE folder_tree_item
SET path = '1/3_nested'
WHERE path = '1/3';
-- выполнить сессию 2
UPDATE folder_tree_item
SET path = '1/2_new'
WHERE path = '1/2';

-- сессия 2
USE test;
START TRANSACTION;
UPDATE folder_tree_item
SET path = '1/3_new'
WHERE path = '1/3';
-- выполнить сессию 1
UPDATE folder_tree_item
SET path = '1/2_nested'
WHERE path = '1/2';
