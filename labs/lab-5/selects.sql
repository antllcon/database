# Извлечь имена всех активных пользователей, которые правильно ответили на все вопросы готового к
# использованию квиза с названием <ваше название>. Квиз должен быть не удалённым курсом.
# Если у пользователя нет имени, отображать его email.


SELECT COALESCE(u.name, u.email) AS user_identifier
FROM user u
         JOIN
     enrollment e ON u.id = e.user_id
         JOIN
     course c ON e.course_id = c.id
         JOIN
     quiz q ON c.id = q.course_id
         JOIN
     quiz_question qq ON q.id = qq.quiz_id
         LEFT JOIN
     attempt a ON e.id = a.enrollment_id
         LEFT JOIN
     quiz_attempt_answer qaa ON a.id = qaa.attempt_id AND qq.id = qaa.question_id
WHERE u.state = 'active'
  AND c.deleted_at IS NULL
  AND q.state = 'ready'
GROUP BY u.id, u.name, u.email, q.id
HAVING COUNT(DISTINCT qq.id) = SUM(CASE
                                       WHEN qq.type = 'multiple_choice' THEN IS_MULTIPLE_CHOICE_CORRECT(qaa.id, qq.id)
                                       WHEN qq.type = 'sequence' THEN IS_SEQUENCE_CORRECT(qaa.id, qq.id)
                                       ELSE 0
    END);

# 2. Извлечь все прохождения, не пройденные до конца (когда один или несколько вопросов не пройдены).
SELECT DISTINCT COALESCE(u.name, u.email) AS user_identifier,
                c.name                    AS course_name
FROM user u
         JOIN
     enrollment e ON u.id = e.user_id
         JOIN
     course c ON e.course_id = c.id
         JOIN
     quiz q ON c.id = q.course_id
         LEFT JOIN
     attempt a ON e.id = a.enrollment_id
         LEFT JOIN
     quiz_question qq ON q.id = qq.quiz_id
WHERE NOT EXISTS (SELECT 1
                  FROM quiz_attempt_answer qaa_inner
                  WHERE qaa_inner.attempt_id = a.id)
   OR (
    (SELECT COUNT(qq_total.id) FROM quiz_question qq_total WHERE qq_total.quiz_id = q.id)
        >
    (SELECT COUNT(qaa_answered.id) FROM quiz_attempt_answer qaa_answered WHERE qaa_answered.attempt_id = a.id)
    );

DELIMITER //

# Подсчитать среднее количество вопросов в квизе, на которые правильно ответили уволенные пользователи в период до 2025,
# а также посчитать посчитать среднее количество вопросов в квизе, на которые правильно ответили активные пользователи
# в период за 2025. И сделать текстовый вывод, кто проходит квизы лучше. Сделать в единый SQL запрос
WITH UserStats AS (SELECT u.state,
                          AVG(CASE
                                  WHEN qq.type = 'multiple_choice' THEN IS_MULTIPLE_CHOICE_CORRECT(qaa.id, qq.id)
                                  WHEN qq.type = 'sequence' THEN IS_SEQUENCE_CORRECT(qaa.id, qq.id)
                                  ELSE 0
                              END) AS avg_correct_answers
                   FROM user u
                            JOIN
                        enrollment e ON u.id = e.user_id
                            JOIN
                        attempt a ON e.id = a.enrollment_id
                            JOIN
                        quiz_attempt_answer qaa ON a.id = qaa.attempt_id
                            JOIN
                        quiz_question qq ON qaa.question_id = qq.id
                   WHERE (u.state = 'fired' AND a.start_date < '2025-01-01')
                      OR (u.state = 'active' AND a.start_date >= '2025-01-01')
                   GROUP BY u.state)
SELECT CASE
           WHEN (SELECT avg_correct_answers FROM UserStats WHERE state = 'fired') >
                (SELECT avg_correct_answers FROM UserStats WHERE state = 'active')
               THEN 'Уволенные пользователи лучше проходят квизы.'
           WHEN (SELECT avg_correct_answers FROM UserStats WHERE state = 'fired') <
                (SELECT avg_correct_answers FROM UserStats WHERE state = 'active')
               THEN 'Активные пользователи лучше проходят квизы.'
           ELSE 'Обе группы пользователей проходят квизы одинаково.'
           END AS comparison_text;

# Функция для проверки правильности ответа на вопрос с множественным выбором
CREATE FUNCTION IS_MULTIPLE_CHOICE_CORRECT(answer_id INT, question_id INT)
    RETURNS TINYINT(1)
    DETERMINISTIC
    READS SQL DATA
BEGIN
    DECLARE correct_count INT;
    DECLARE selected_correct_count INT;
    DECLARE selected_incorrect_count INT;

    SELECT COUNT(mcqav.id)
    INTO correct_count
    FROM multiple_choice_question_available_values mcqav
    WHERE mcqav.question_id = question_id
      AND mcqav.is_correct = TRUE;

    SELECT COUNT(qamc.value_id)
    INTO selected_correct_count
    FROM quiz_attempt_multiple_choice qamc
             JOIN multiple_choice_question_available_values mcqav_selected ON qamc.value_id = mcqav_selected.id
    WHERE qamc.answer_id = answer_id
      AND mcqav_selected.is_correct = TRUE;

    SELECT COUNT(qamc.value_id)
    INTO selected_incorrect_count
    FROM quiz_attempt_multiple_choice qamc
             JOIN multiple_choice_question_available_values mcqav_selected ON qamc.value_id = mcqav_selected.id
    WHERE qamc.answer_id = answer_id
      AND mcqav_selected.is_correct = FALSE;

    IF selected_correct_count = correct_count AND selected_incorrect_count = 0 THEN
        RETURN 1;
    ELSE
        RETURN 0;
    END IF;
END //

# Функция для проверки правильности ответа на вопрос с последовательностью
CREATE FUNCTION IS_SEQUENCE_CORRECT(answer_id INT, question_id INT)
    RETURNS TINYINT(1)
    DETERMINISTIC
    READS SQL DATA
BEGIN
    DECLARE correct_sequence TEXT;
    DECLARE user_sequence TEXT;

    SELECT GROUP_CONCAT(sqav.value ORDER BY sqav.id)
    INTO correct_sequence
    FROM sequence_question_available_values sqav
    WHERE sqav.question_id = question_id;

    SELECT GROUP_CONCAT(sqav_attempt.value ORDER BY qas.position)
    INTO user_sequence
    FROM quiz_attempt_sequence qas
             JOIN sequence_question_available_values sqav_attempt ON qas.value_id = sqav_attempt.id
    WHERE qas.answer_id = answer_id;

    IF correct_sequence = user_sequence THEN
        RETURN 1;
    ELSE
        RETURN 0;
    END IF;
END //

DELIMITER ;

# 4. Посчитать статистику: на какие типы вопросов у готовых квизов и активных пользователей в процентном соотношении
# больше правильных ответов. Например, на вопросы с последовательностью 50% правильных ответов,
# а на вопросы с множественным выбором 60% правильных ответов. Проценты сравнить.
SELECT qq.type                         AS question_type,
       (SUM(CASE
                WHEN qq.type = 'multiple_choice' THEN IS_MULTIPLE_CHOICE_CORRECT(qaa.id, qq.id)
                WHEN qq.type = 'sequence' THEN IS_SEQUENCE_CORRECT(qaa.id, qq.id)
                ELSE 0
           END) / COUNT(qaa.id)) * 100 AS percentage_correct
FROM user u
         JOIN
     enrollment e ON u.id = e.user_id
         JOIN
     attempt a ON e.id = a.enrollment_id
         JOIN
     quiz_attempt_answer qaa ON a.id = qaa.attempt_id
         JOIN
     quiz_question qq ON qaa.question_id = qq.id
         JOIN
     quiz q ON qq.quiz_id = q.id
WHERE u.state = 'active'
  AND q.state = 'ready'
GROUP BY qq.type;

# 8. Извлечь 10 активных пользователей, которые суммарно набрали наибольшее количество баллов
# в вопросах с последовательностью в готовых к использованию квизах с максимально допустимой
# продолжительностью прохождения до 10 минут.
SELECT COALESCE(u.name, u.email)               AS user_identifier,
       SUM(IS_SEQUENCE_CORRECT(qaa.id, qq.id)) AS total_sequence_score
FROM user u
         JOIN
     enrollment e ON u.id = e.user_id
         JOIN
     attempt a ON e.id = a.enrollment_id
         JOIN
     quiz_attempt_answer qaa ON a.id = qaa.attempt_id
         JOIN
     quiz_question qq ON qaa.question_id = qq.id
         JOIN
     quiz q ON qq.quiz_id = q.id
WHERE qq.type = 'sequence'
GROUP BY u.id, user_identifier
ORDER BY total_sequence_score DESC
LIMIT 10;

# 9. Посчитать среднюю оценку (QuizMark) за квизы, если бы там были только вопросы с последовательностью,
# без вопросов с множественным выбором.
SELECT AVG(qm.mark) AS average_mark
FROM quiz q
         JOIN
     quiz_question qq ON q.id = qq.quiz_id
         JOIN
     quiz_attempt_answer qaa ON qq.id = qaa.question_id
         JOIN
     attempt a ON qaa.attempt_id = a.id
         JOIN
     quiz_mark qm ON q.id = qm.quiz_id
WHERE qq.type = 'sequence'
  AND IS_SEQUENCE_CORRECT(qaa.id, qq.id) = 1;