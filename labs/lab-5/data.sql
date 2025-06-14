SHOW DATABASES;
CREATE DATABASE sc;

USE sc;
SHOW TABLES;

CREATE TABLE IF NOT EXISTS course
(
    id          INT UNSIGNED AUTO_INCREMENT,
    name        VARCHAR(255)                    NOT NULL,
    course_type ENUM ('quiz', 'video', 'audio') NULL,
    description TEXT                            NULL,
    deleted_at  TIMESTAMP                       NULL,
    PRIMARY KEY (id)
)
    ENGINE = InnoDB
    CHARSET = utf8mb4
    COLLATE = utf8mb4_unicode_ci
;

CREATE TABLE IF NOT EXISTS video
(
    id         INT UNSIGNED AUTO_INCREMENT,
    course_id  INT UNSIGNED                NOT NULL,
    source_url VARCHAR(255)                NOT NULL,
    duration   INT UNSIGNED                NOT NULL,
    format     ENUM ('mp4', 'webm', 'avi') NOT NULL,
    size       INT UNSIGNED                NOT NULL,
    PRIMARY KEY (id),
    FOREIGN KEY (course_id) REFERENCES course (id)
)
    ENGINE = InnoDB
    CHARSET = utf8mb4
    COLLATE = utf8mb4_unicode_ci
;

CREATE TABLE IF NOT EXISTS audio
(
    id         INT UNSIGNED AUTO_INCREMENT,
    course_id  INT UNSIGNED NOT NULL,
    source_url VARCHAR(255) NOT NULL,
    duration   INT UNSIGNED NOT NULL,
    PRIMARY KEY (id),
    FOREIGN KEY (course_id) REFERENCES course (id)
)
    ENGINE = InnoDB
    CHARSET = utf8mb4
    COLLATE = utf8mb4_unicode_ci
;

CREATE TABLE IF NOT EXISTS quiz
(
    id                 INT UNSIGNED AUTO_INCREMENT,
    course_id          INT UNSIGNED                            NOT NULL,
    source_url         VARCHAR(255)                            NOT NULL,
    weight             VARCHAR(100)                            NOT NULL,
    available_duration TIMESTAMP                               NULL,
    state              ENUM ('uploaded', 'processed', 'ready') NOT NULL,
    PRIMARY KEY (id),
    FOREIGN KEY (course_id) REFERENCES course (id)
)
    ENGINE = InnoDB
    CHARSET = utf8mb4
    COLLATE = utf8mb4_unicode_ci
;

CREATE TABLE IF NOT EXISTS quiz_mark
(
    id        INT UNSIGNED AUTO_INCREMENT,
    quiz_id   INT UNSIGNED NOT NULL,
    mark      INT UNSIGNED NOT NULL,
    min_score INT UNSIGNED NOT NULL,
    max_score INT UNSIGNED NOT NULL,
    PRIMARY KEY (id),
    FOREIGN KEY (quiz_id) REFERENCES quiz (id),
    CHECK (min_score <= max_score)
)
    ENGINE = InnoDB
    CHARSET = utf8mb4
    COLLATE = utf8mb4_unicode_ci
;

CREATE TABLE IF NOT EXISTS quiz_question
(
    id          INT UNSIGNED AUTO_INCREMENT,
    quiz_id     INT UNSIGNED                         NOT NULL,
    text        TEXT                                 NOT NULL,
    type        ENUM ('multiple_choice', 'sequence') NOT NULL,
    picture_url VARCHAR(255)                         NULL,
    PRIMARY KEY (id),
    FOREIGN KEY (quiz_id) REFERENCES quiz (id)
)
    ENGINE = InnoDB
    CHARSET = utf8mb4
    COLLATE = utf8mb4_unicode_ci
;

CREATE TABLE IF NOT EXISTS multiple_choice_question_available_values
(
    id          INT UNSIGNED AUTO_INCREMENT,
    question_id INT UNSIGNED          NOT NULL,
    value       VARCHAR(255)          NOT NULL,
    is_correct  BOOLEAN DEFAULT FALSE NOT NULL,
    PRIMARY KEY (id),
    FOREIGN KEY (question_id) REFERENCES quiz_question (id)
)
    ENGINE = InnoDB
    CHARSET = utf8mb4
    COLLATE = utf8mb4_unicode_ci
;

CREATE TABLE IF NOT EXISTS sequence_question_available_values
(
    id            INT UNSIGNED AUTO_INCREMENT,
    question_id   INT UNSIGNED NOT NULL,
    value         VARCHAR(255) NOT NULL,
    next_value_id INT UNSIGNED NULL,
    PRIMARY KEY (id),
    FOREIGN KEY (question_id) REFERENCES quiz_question (id)
)
    ENGINE = InnoDB
    CHARSET = utf8mb4
    COLLATE = utf8mb4_unicode_ci
;

# Исправить
CREATE TABLE IF NOT EXISTS user
(
    id         INT UNSIGNED AUTO_INCREMENT,
    name       VARCHAR(255)                         NULL,
    email      VARCHAR(255)                         NOT NULL UNIQUE,
    state      ENUM ('active', 'inactive', 'fired') NOT NULL,
    deleted_at TIMESTAMP                            NULL,
    PRIMARY KEY (id)
)
    ENGINE = InnoDB
    CHARSET = utf8mb4
    COLLATE = utf8mb4_unicode_ci
;

CREATE TABLE IF NOT EXISTS enrollment
(
    id         INT UNSIGNED AUTO_INCREMENT,
    user_id    INT UNSIGNED NOT NULL,
    course_id  INT UNSIGNED NOT NULL,
    start_date TIMESTAMP    NULL,
    end_date   TIMESTAMP    NULL,
    PRIMARY KEY (id),
    FOREIGN KEY (user_id) REFERENCES user (id),
    FOREIGN KEY (course_id) REFERENCES course (id)
)
    ENGINE = InnoDB
    CHARSET = utf8mb4
    COLLATE = utf8mb4_unicode_ci
;

CREATE TABLE IF NOT EXISTS attempt
(
    id            INT UNSIGNED AUTO_INCREMENT,
    enrollment_id INT UNSIGNED NOT NULL,
    start_date    TIMESTAMP    NULL,
    score         INT UNSIGNED NULL,
    duration      INT UNSIGNED NULL,
    PRIMARY KEY (id),
    FOREIGN KEY (enrollment_id) REFERENCES enrollment (id)
)
    ENGINE = InnoDB
    CHARSET = utf8mb4
    COLLATE = utf8mb4_unicode_ci
;

CREATE TABLE IF NOT EXISTS quiz_attempt_answer
(
    id          INT UNSIGNED AUTO_INCREMENT,
    attempt_id  INT UNSIGNED NOT NULL,
    question_id INT UNSIGNED NOT NULL,
    value       VARCHAR(255) NULL,
    PRIMARY KEY (id),
    FOREIGN KEY (attempt_id) REFERENCES attempt (id),
    FOREIGN KEY (question_id) REFERENCES quiz_question (id)
)
    ENGINE = InnoDB
    CHARSET = utf8mb4
    COLLATE = utf8mb4_unicode_ci
;

# Добавил
CREATE TABLE IF NOT EXISTS quiz_attempt_multiple_choice
(
    answer_id INT UNSIGNED NOT NULL,
    value_id  INT UNSIGNED NOT NULL,
    PRIMARY KEY (answer_id, value_id),
    FOREIGN KEY (answer_id) REFERENCES quiz_attempt_answer (id),
    FOREIGN KEY (value_id) REFERENCES multiple_choice_question_available_values (id)
)
    ENGINE = InnoDB
    CHARSET = utf8mb4
    COLLATE = utf8mb4_unicode_ci
;

CREATE TABLE IF NOT EXISTS quiz_attempt_sequence
(
    answer_id INT UNSIGNED NOT NULL,
    value_id  INT UNSIGNED NOT NULL,
    position  INT UNSIGNED NOT NULL,
    PRIMARY KEY (answer_id, value_id),
    FOREIGN KEY (answer_id) REFERENCES quiz_attempt_answer (id),
    FOREIGN KEY (value_id) REFERENCES sequence_question_available_values (id)
)
    ENGINE = InnoDB
    CHARSET = utf8mb4
    COLLATE = utf8mb4_unicode_ci
;