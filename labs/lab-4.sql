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
    FOREIGN KEY (`parent_id`) REFERENCES `comment` (`id`),
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

CREATE TABLE  IF NOT EXISTS `thread`
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
    ADD COLUMN `last_login` DATETIME                NULL AFTER `is_active`,
    ADD COLUMN `avatar`     LONGBLOB                NULL,
    ADD COLUMN `gender`     ENUM ('male', 'female') NULL DEFAULT NULL AFTER `avatar`
;

ALTER TABLE `thread`
    ADD COLUMN `is_visible` TINYINT(1)   NOT NULL DEFAULT 1 AFTER `is_locked`,
    ADD COLUMN `color_code` VARCHAR(255) NOT NULL DEFAULT '#FFFFFF' AFTER `description`,
    ADD COLUMN `is_starred` TINYINT(1)   NOT NULL DEFAULT 0
;

SELECT *
FROM `news_block`;

DROP DATABASE `news_feed`;

# ЗАДАНИЕ 2.
