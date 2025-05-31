# ЗАДАНИЕ 1.
# Создайте БД для модуля новостной ленты на основании ER диаграммы из предыдущей
# лабораторной работы.

# Требования:
# Как минимум один идентификатор должен быть числовым.
# Как минимум один идентификатор должен быть типа UUID.
# Как минимум один идентификатор должен быть типа VARCHAR.
# Уникальные столбцы в таблице должны гарантировать уникальность на уровне схемы базы данных.
# Добавьте как минимум 2 новых отношения на своё усмотрение. Отношения должны содержать не менее 5 атрибутов и могут быть связаны через вспомогательные таблицы.
# Добавьте как минимум по 3 новых поля (поля придумаете сами) в 2 отношения через изменение существующей таблицы

CREATE DATABASE IF NOT EXISTS `news_feed`;
USE `news_feed`;

CREATE TABLE IF NOT EXISTS `news`
(
    `id`           INT UNSIGNED AUTO_INCREMENT,
    `name`         VARCHAR(255)        NOT NULL,
    `image_id`     BINARY(16)          NOT NULL,
    `author_id`    INT UNSIGNED        NOT NULL,
    `is_published` TINYINT(1) UNSIGNED NOT NULL DEFAULT 0,
    PRIMARY KEY (`id`)
)
    ENGINE = InnoDB
    CHARACTER SET = utf8mb4
    COLLATE utf8mb4_unicode_ci
;

CREATE TABLE IF NOT EXISTS `news_block`
(
    `block_id` BINARY(16)            NOT NULL,
    `news_id`  INT UNSIGNED          NOT NULL,
    `position` TINYINT(255) UNSIGNED NOT NULL DEFAULT 0,
    PRIMARY KEY (`block_id`),
    UNIQUE (`news_id`, `position`),
    FOREIGN KEY (`news_id`) REFERENCES `news` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
)
    ENGINE = InnoDB
    CHARACTER SET = utf8mb4
    COLLATE utf8mb4_unicode_ci
;

CREATE TABLE IF NOT EXISTS `text_block`
(
    `block_id` BINARY(16) NOT NULL,
    `text`     TEXT       NOT NULL,
    PRIMARY KEY (`block_id`),
    FOREIGN KEY (`block_id`) REFERENCES `news_block` (`block_id`) ON DELETE CASCADE ON UPDATE CASCADE
)
    ENGINE = InnoDB
    CHARACTER SET = utf8mb4
    COLLATE utf8mb4_unicode_ci
;

CREATE TABLE IF NOT EXISTS `image_block`
(
    `block_id` BINARY(16) NOT NULL,
    `image`    LONGBLOB   NOT NULL,
    PRIMARY KEY (`block_id`),
    FOREIGN KEY (`block_id`) REFERENCES `news_block` (`block_id`) ON DELETE CASCADE ON UPDATE CASCADE
)
    ENGINE = InnoDB
    CHARACTER SET = utf8mb4
    COLLATE utf8mb4_unicode_ci
;

CREATE TABLE IF NOT EXISTS `news_view`
(
    `news_id`    INT UNSIGNED  NOT NULL,
    `ip_address` VARBINARY(16) NOT NULL,
    `view_time`  TIMESTAMP     NOT NULL DEFAULT NOW(),
    UNIQUE (`news_id`, `ip_address`),
    FOREIGN KEY (`news_id`) REFERENCES `news` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
)
    ENGINE = InnoDB
    CHARACTER SET = utf8mb4
    COLLATE utf8mb4_unicode_ci
;

CREATE TABLE IF NOT EXISTS `comment`
(
    `id`         INT UNSIGNED AUTO_INCREMENT,
    `news_id`    INT UNSIGNED        NOT NULL,
    `ip_address` VARBINARY(16)       NOT NULL,
    `text`       TEXT                NOT NULL,
    `is_deleted` TINYINT(1) UNSIGNED NOT NULL DEFAULT 0,
    `parent_id`  INT UNSIGNED        NULL,
    PRIMARY KEY (`id`),
    FOREIGN KEY (`parent_id`) REFERENCES `comment` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
    FOREIGN KEY (`news_id`) REFERENCES `news` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
)
    ENGINE = InnoDB
    CHARACTER SET = utf8mb4
    COLLATE utf8mb4_unicode_ci
;

CREATE TABLE IF NOT EXISTS `author`
(
    `author_id`  INT UNSIGNED AUTO_INCREMENT,
    `name`       VARCHAR(255)        NOT NULL,
    `email`      VARCHAR(100)        NOT NULL UNIQUE,
    `bio`        TEXT                NULL,
    `created_at` TIMESTAMP           NOT NULL DEFAULT NOW(),
    `is_active`  TINYINT(1) UNSIGNED NOT NULL DEFAULT 0,
    PRIMARY KEY (`author_id`)
)
    ENGINE = InnoDB
    CHARSET = utf8mb4
    COLLATE = utf8mb4_unicode_ci
;

ALTER TABLE `news`
    ADD FOREIGN KEY (`author_id`) REFERENCES `author` (`author_id`) ON DELETE CASCADE ON UPDATE CASCADE;

CREATE TABLE IF NOT EXISTS `thread`
(
    `thread_id`   VARCHAR(255) NOT NULL,
    `title`       VARCHAR(255) NOT NULL,
    `description` TEXT         NULL,
    `created_by`  INT UNSIGNED NULL,
    `created_at`  TIMESTAMP    NOT NULL DEFAULT NOW(),
    `is_locked`   TINYINT(1)   NOT NULL DEFAULT 0,
    PRIMARY KEY (`thread_id`),
    FOREIGN KEY (`created_by`) REFERENCES `author` (`author_id`) ON DELETE SET NULL ON UPDATE CASCADE
)
    ENGINE = InnoDB
    CHARSET = utf8mb4
    COLLATE = utf8mb4_unicode_ci
;

ALTER TABLE `author`
    ADD COLUMN `last_login` DATETIME                NOT NULL DEFAULT NOW() AFTER `created_at`,
    ADD COLUMN `avatar`     LONGBLOB                NULL,
    ADD COLUMN `gender`     ENUM ('male', 'female') NULL     DEFAULT NULL AFTER `avatar`
;

ALTER TABLE `thread`
    ADD COLUMN `is_visible` TINYINT(1)   NOT NULL DEFAULT 1 AFTER `is_locked`,
    ADD COLUMN `color_code` VARCHAR(255) NOT NULL DEFAULT '#FFFFFF' AFTER `description`,
    ADD COLUMN `is_starred` TINYINT(1)   NOT NULL DEFAULT 0
;

DROP DATABASE `news_feed`;

# ЗАДАНИЕ 2.
# Заполните Базу Данных данными, можете посмотреть задание 1.3 для более
# глубокого понимания того, что требуется в базе данных. Требования к запросам:

# Общее:
# Соблюдены правила форматирования
# Запрос создаёт правильный результат без неожиданных потерь данных
# Каждая сущность должна иметь как минимум 2 запроса на модификацию (UPDATE) одного или нескольких полей

# Частное:
# Как минимум 3 запроса должны быть идемпотентными `INSERT ON DUPLICATE KEY IGNORE`
# Как минимум 3 запроса должны быть готовы к тому, что сущность в БД уже есть `INSERT ON DUPLICATE KEY UPDATE`
# Как минимум 6 операций должны быть в транзакции (3 с COMMIT и 3 с ROLLBACK), выбирайте операции осознанно, с проверкой результата перед коммитом

DESCRIBE `author`;

BEGIN;
INSERT IGNORE INTO `author` (`name`, `email`, `bio`, `avatar`, `gender`)
VALUES ('Иван Петров', 'ivan.petrov@example.com', 'Полный ноль', 10011000110, 'male'),
       ('Мария Пупкина', 'maria.pupkina@sus.com', 'Репетитор по регби', 1101010001, 'female'),
       ('Алексей Марышев', 'alex.marusev@ya.ru', 'Главный по буфету', 01010101010, 'male'),
       ('Алексей Малов', 'malov@gmail.com', 'Лучший программист', 11110111100, 'male')
;
SELECT *
FROM `author`;
COMMIT;

# DELETE FROM `author` WHERE `email` IN ('ivan.petrov@example.com', 'maria.pupkina@sus.com', 'alex.marusev@ya.ru', 'malov@gmail.com');

BEGIN;
# SELECT `bio`, `is_active` FROM `author` WHERE `author_id` = 5 OR `name` LIKE 'Алексей%';

UPDATE `author`
SET `bio` = 'Известный эксперт'
WHERE `author_id` = 5;
UPDATE `author`
SET `is_active` = 1
WHERE `name` LIKE 'Алексей%';
SELECT *
FROM `author`;
COMMIT;
# UPDATE `author` SET `bio` = 'Полный ноль', `is_active` = 0 WHERE `author_id` = 5;
# UPDATE `author` SET `is_active` = 0 WHERE `author_id` = 7 AND `author_id = 8;

BEGIN;
SET @txt_uuid1 = UUID_TO_BIN(UUID());
SET @txt_uuid2 = UUID_TO_BIN(UUID());
SET @txt_uuid3 = UUID_TO_BIN(UUID());
SET @txt_uuid4 = UUID_TO_BIN(UUID());

SET @img_uuid1 = UUID_TO_BIN(UUID());
SET @img_uuid2 = UUID_TO_BIN(UUID());
SET @img_uuid3 = UUID_TO_BIN(UUID());
SET @img_uuid4 = UUID_TO_BIN(UUID());

DESCRIBE `news`;

INSERT IGNORE INTO `news`(`name`, `image_id`, `author_id`)
VALUES ('Ладно, поехали', @img_uuid1, 5),
       ('Лайв куд би дрим', @img_uuid2, 6),
       ('Иф ай куд тейк ю ап', @img_uuid3, 7),
       ('Э парадайз ап абов', @img_uuid4, 8)
;
SELECT *
FROM `news`;
COMMIT;

# DELETE FROM `news` WHERE `id` BETWEEN 15 AND 18;

BEGIN;
# SELECT `name` FROM `news` WHERE `id` = 15;           # 'Ладно, поехали'
# SELECT `name` FROM `news` WHERE `name` LIKE 'Лайв%'; # 'Лайв куд би дрим'

UPDATE `news`
SET `name` = 'Ладно, понаехали'
WHERE `id` = 15;
UPDATE `news`
SET `name` = 'Rich Вишня не вкусный'
WHERE `name` LIKE 'Лайв%';
SELECT *
FROM `news`;
COMMIT;

# UPDATE `news` SET `name` = 'Ладно, поехали' WHERE `id` = 15;
# UPDATE `news` SET `name` = 'Лайв куд би дрим' WHERE `id` = 16;

DESCRIBE `news_block`;

BEGIN;
INSERT INTO `news_block`(`block_id`, `news_id`, `position`)
VALUES (@txt_uuid1, 15, 1),
       (@img_uuid1, 15, 2),
       (@txt_uuid2, 16, 1),
       (@img_uuid2, 16, 2),
       (@txt_uuid3, 17, 1),
       (@img_uuid3, 17, 2),
       (@txt_uuid4, 18, 1),
       (@img_uuid4, 18, 2)
ON DUPLICATE KEY UPDATE `position` = VALUES(`position`);
;
SELECT *
FROM `news_block`;
COMMIT;


# DELETE FROM `news_block` WHERE `block_id` IN (@txt_uuid1, @img_uuid1, @txt_uuid2, @img_uuid2, @txt_uuid3, @img_uuid3, @txt_uuid4, @img_uuid4);

BEGIN;
# SELECT `block_id`, `position` FROM `news_block` WHERE `position` IN (1, 3);

UPDATE `news_block`
SET `position` = 3
WHERE `position` = 1;
UPDATE `news_block`
SET `position` = 4
WHERE `position` = 5;
SELECT *
FROM `news_block`;
COMMIT;

# UPDATE `news_block` SET `position` = 1 WHERE `block_id` IN (@txt_uuid1, @txt_uuid2, @txt_uuid3, @txt_uuid4);
# UPDATE `news_block` SET `position` = 2 WHERE `block_id` IN (@img_uuid1, @img_uuid2, @img_uuid3, @img_uuid4);

DESCRIBE `text_block`;
DESCRIBE `image_block`;

BEGIN;
INSERT INTO `text_block` (`block_id`, `text`)
VALUES (@txt_uuid1, 'Куда поехали то?'),
       (@txt_uuid2, 'Просто сейчас 03:48 и очень крутая музыка'),
       (@txt_uuid3, 'Эври бади денс нау туц туц'),
       (@txt_uuid4, 'Влад спит закинув ногу вверх... Как?')
ON DUPLICATE KEY UPDATE `text` = VALUES(`text`);


INSERT INTO `text_block` (`block_id`, `text`)
VALUES (@txt_uuid1, 'Бара бара бара')
;

SELECT *
FROM `text_block`;

COMMIT;

UPDATE `text_block`
SET `text` = 'Куда понаехали то?'
WHERE `block_id` = @txt_uuid1;
UPDATE `text_block`
SET `text` = 'Просто сейчас 03:58 и убойная музыка'
WHERE `block_id` = @txt_uuid2;

INSERT INTO `image_block` (`block_id`, `image`)
VALUES (@img_uuid1, 000100101010),
       (@img_uuid2, 010100101011),
       (@img_uuid3, 111010101011),
       (@img_uuid4, 110010101110)
ON DUPLICATE KEY UPDATE `image` = VALUES(`image`);
;

UPDATE `image_block`
SET `image` = 111111111111
WHERE `block_id` = @img_uuid1;
UPDATE `image_block`
SET `image` = 111000000111
WHERE `block_id` = @img_uuid2;

SELECT *
FROM `image_block`;

DESCRIBE `news_view`;

INSERT IGNORE INTO `news_view` (`news_id`, `ip_address`)
VALUES (15, INET6_ATON('192.168.1.1')),
       (15, INET6_ATON('192.168.1.2')),
       (15, INET6_ATON('192.168.1.3')),
       (16, INET6_ATON('192.168.1.4')),
       (16, INET6_ATON('192.168.1.5')),
       (17, INET6_ATON('192.168.1.6')),
       (17, INET6_ATON('192.168.1.7')),
       (18, INET6_ATON('192.168.1.8'))
;

UPDATE `news_view`
SET `ip_address` = '192.168.2.1'
WHERE `news_id` = 18;
UPDATE `news_view`
SET `ip_address` = '192.168.3.1'
WHERE `news_id` = 18;

SELECT *
FROM `news_view`;

DESCRIBE `comment`;

INSERT INTO `comment` (`news_id`, `ip_address`, `text`, `is_deleted`, `parent_id`)
VALUES (15, INET6_ATON('192.168.1.1'), 'Отличная статья!', 0, NULL),
       (16, INET6_ATON('192.168.1.2'), 'Просто ужас, автор глупый', 0, NULL),
       (17, INET6_ATON('192.168.1.3'), 'Не согласен с выводами', 0, NULL),
       (18, INET6_ATON('192.168.1.4'), 'Все плохо!!!! Забаньте автора', 0, NULL);
;

INSERT INTO `comment` (`news_id`, `ip_address`, `text`, `is_deleted`, `parent_id`)
VALUES (15, INET6_ATON('192.168.1.5'), 'Вообще-то она ужасная!', 0, 1),
       (16, INET6_ATON('192.168.1.6'), 'Кто как обзывается - тот сам так называется', 0, 2),
       (17, INET6_ATON('192.168.1.7'), 'Да, смотри на сома из ООП }(.)>><', 0, 3),
       (18, INET6_ATON('192.168.1.8'), 'Я сам кого хочешь забаню, по ip вычислю', 0, 4);
;

UPDATE `comment`
SET `text` = 'Елки палки... Не выражайся.'
WHERE `parent_id` = 18;
UPDATE `comment`
SET `text` = 'Елки палки... выражайся.'
WHERE `parent_id` = 15;

SELECT *
FROM `comment`;

DESCRIBE `thread`;

INSERT IGNORE INTO `thread` (`thread_id`, `title`, `description`, `created_by`, `is_locked`, `is_visible`, `color_code`,
                             `is_starred`)
VALUES ('tech', 'Сон', 'Обсуждение того кто и как поспал', 5, 0, 1, '#4CAF50', 1),
       ('economy', 'Экономика', 'Новости на бирже', 6, 0, 1, '#2196F3', 0),
       ('sports', 'Спорт', 'Спортивные события и провалы', 7, 0, 1, '#FF5722', 0),
       ('music', 'Музыка', 'Токийский дрифт', 8, 1, 0, '#FF601D', 1)
;

UPDATE `thread`
SET `color_code` = '#FFFFFF'
WHERE `is_starred` = 1;
UPDATE `thread`
SET `title` = 'Музыкалити'
WHERE `thread_id` = 'music';

SELECT *
FROM `thread`;


# ////////////////////////////

# Вы можете решать каждую задачу с помощью нескольких SQL-запросов - допускается использовать
# результат предыдущих запросов в виде констант в следующем запросе (предыдущий результат),
# это избавит от необходимости использовать более сложные механизмы SQL — соединения и подзапросы.
# За использование запросов с JOIN + 5 баллов.

# Запросы 1-6 оцениваются в 1 балл, запросы 6-13 оцениваются в 2 балла.

SHOW DATABASES;

USE news_feed;

SELECT *
FROM news;
SELECT *
FROM author;
SELECT *
FROM thread;
SELECT *
FROM image_block;
SELECT *
FROM text_block;
SELECT *
FROM news_block;
SELECT *
FROM comment;

# 1. Извлечь все опубликованные новости.
SELECT *
FROM news
WHERE is_published;

# 2. Извлечь информацию о миниатюре конкретной новости по идентификатору новости.
SELECT news.id AS news_id, news.name AS news_name, news.image_id AS news_image
FROM news
WHERE news.id = 15;

# 3. Извлеките все ip адреса, с которых были просмотры. В результате они должны быть уникальными.
SELECT DISTINCT ip_address
FROM news_view;

SELECT ip_address, COUNT(*) AS view_count
FROM news_view
GROUP BY ip_address;

# 4. Извлечь информацию для отображения конкретной новости целиком в портале
# пользователя (информацию, которая доступна всем пользователям).
SELECT news.id             AS news_id,
       news.name           AS news_title,
       news.image_id       AS news_image_id,
       author.name         AS author_name,
       news_block.position AS position,
       text_block.text     AS news_text,
       image_block.image   AS news_image

FROM news
         JOIN author ON news.author_id = author.author_id
         JOIN news_block ON news_block.news_id = news.id
         LEFT JOIN text_block ON text_block.block_id = news_block.block_id
         LEFT JOIN image_block ON news_block.block_id = image_block.block_id

WHERE news.is_published
  AND news.id = 15
;

# 5. Извлечь ТОП 5 самых просматриваемых новостей.
SELECT news.id   AS news_id,
       news.name AS news_name,
       COUNT(news_view.news_id)
FROM news
         JOIN news_view ON news.id = news_view.news_id
GROUP BY news.id
ORDER BY COUNT(news_view.news_id) DESC
LIMIT 5;

# 6. Извлечь все новости, которые просматривали после конкретной даты (дату придумаете сами).
SELECT news.id   AS news_id,
       news.name AS news_name
FROM news
         JOIN news_view ON news.id = news_view.news_id
WHERE news.is_published
  AND news_view.view_time > '2025-05-23 09:00:00'
;

# 7. Найти новость с наибольшим количеством блоков контента.
SELECT news.id   AS news_id,
       news.name AS news_name,
       COUNT(news_block.news_id)
FROM news
         JOIN news_block ON news.id = news_block.news_id
GROUP BY news.id, news.name
ORDER BY COUNT(news_block.news_id) DESC
LIMIT 1
;

# 8. Извлечь ТОП 5 самых комментируемых новостей.
SELECT news.id                AS news_id,
       news.name              AS news_name,
       COUNT(comment.news_id) AS count
FROM news
         JOIN comment ON news.id = comment.news_id
GROUP BY news.id, news.name
ORDER BY count
LIMIT 5
;

# 9. Извлечь даты, в которые новости (учитывать все новости) просматривались наиболее часто.
SELECT news_view.view_time      AS view_time,
       COUNT(news_view.news_id) AS count
FROM news_view
GROUP BY news_view.view_time
ORDER BY count DESC
;

# 10. Реализовать поиск по новостям: поиск должен быть на вхождение по названию новости или текстового контента новости.
# Например, при поиске слова `машина` должны извлекаться все новости с упоминанием этого слова
# в названии или контенте новости.

SELECT *
FROM news;
SELECT *
FROM text_block;

SELECT news.id                                     AS news_id,
       news.name                                   AS news_title,
       GROUP_CONCAT(text_block.text SEPARATOR ' ') AS news_content

FROM news
         JOIN news_block ON news.id = news_block.news_id
         JOIN text_block ON news_block.block_id = text_block.block_id

WHERE news.name LIKE '%понаехали%'
   OR text_block.text LIKE '%понаехали%'

GROUP BY news.id, news.name
ORDER BY news.name
;

# 11. Найти комментарий, у которого больше всего вложенных ответов (вглубь).
WITH RECURSIVE high_comment AS (SELECT id,
                                       parent_id,
                                       news_id,
                                       text,
                                       1                      AS depth,
                                       CAST(id AS CHAR(1000)) AS path
                                FROM comment
                                WHERE parent_id IS NULL

                                UNION ALL

                                SELECT comment.id,
                                       comment.parent_id,
                                       comment.news_id,
                                       comment.text,
                                       hc.depth + 1                     AS depth,
                                       CONCAT(hc.path, ',', comment.id) AS path
                                FROM comment
                                         JOIN high_comment hc ON comment.parent_id = hc.id
                                WHERE FIND_IN_SET(comment.id, hc.path) = 0)

SELECT id    AS comment_id,
       news_id,
       text,
       depth AS max_depth,
       path  AS comment_chain
FROM high_comment
ORDER BY depth DESC
LIMIT 1
;

# 12. Придумать запрос с новыми сущностями с использованием HAVING.

# 13. Найти зацикливание в дереве комментариев (перед этим создать зацикливание)
INSERT INTO comment (news_id, ip_address, text, is_deleted, parent_id)
VALUES (15, INET6_ATON('127.0.0.100'), 'Коммент 1', 0, NULL),
       (15, INET6_ATON('127.0.0.101'), 'Коммент 2', 0, 26),
       (15, INET6_ATON('127.0.0.102'), 'Коммент 3', 0, 27)
;

UPDATE comment
SET parent_id = 26
WHERE id = 28;

SELECT *
FROM comment;

EXPLAIN ANALYZE WITH RECURSIVE comment_cycle AS (SELECT id,
                                        parent_id,
                                        1                      AS depth,
                                        CAST(id AS CHAR(1000)) AS path
                                 FROM comment
                                 WHERE parent_id IS NOT NULL

                                 UNION ALL

                                 SELECT comment.id,
                                        comment.parent_id,
                                        comment_cycle.depth + 1,
                                        CONCAT(comment_cycle.path, ',', comment.id)
                                 FROM comment
                                          JOIN comment_cycle ON comment.id = comment_cycle.parent_id
                                 WHERE comment_cycle.depth < 10
                                   AND FIND_IN_SET(comment.id, comment_cycle.path) = 0)
SELECT *
FROM comment_cycle
WHERE FIND_IN_SET(parent_id, path) > 0
;