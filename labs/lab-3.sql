CREATE DATABASE IF NOT EXISTS `news_feed`;
USE `news_feed`;

CREATE TABLE IF NOT EXISTS `news`
(
    `id`           INT UNSIGNED AUTO_INCREMENT,
    `name`         VARCHAR(255)        NOT NULL,
    `is_published` TINYINT(1) UNSIGNED NOT NULL DEFAULT 0,
    PRIMARY KEY (`id`)
)
    ENGINE = InnoDB
    CHARACTER SET = utf8mb4
    COLLATE utf8mb4_unicode_ci
;

CREATE TABLE IF NOT EXISTS `text_block`
(
    `block_id` BINARY(16) NOT NULL,
    `text`     TEXT       NOT NULL,
    PRIMARY KEY (`block_id`)
)
    ENGINE = InnoDB
    CHARACTER SET = utf8mb4
    COLLATE utf8mb4_unicode_ci
;

CREATE TABLE IF NOT EXISTS `image_block`
(
    `block_id` BINARY(16) NOT NULL,
    `image`    LONGBLOB   NOT NULL,
    PRIMARY KEY (`block_id`)
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
    UNIQUE (`ip_address`),
    FOREIGN KEY (`parent_id`) REFERENCES `comment` (`id`),
    FOREIGN KEY (`news_id`) REFERENCES `news` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
)
    ENGINE = InnoDB
    CHARACTER SET = utf8mb4
    COLLATE utf8mb4_unicode_ci
;

INSERT INTO `news` (name, is_published)
VALUES ('Top 10 goobie woobies', TRUE),
       ('Italian animals', FALSE),
       ('How to make Database?', FALSE),
       ('Nice memes', TRUE),
       ('Why I live at weekend?', TRUE);

SELECT *
FROM `news_block`;

DROP DATABASE `news_feed`;


