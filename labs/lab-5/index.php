<?php
//include __DIR__ . '/static/view/view.php';
require __DIR__ . '/src/config/db.php';
require __DIR__ . '/src/cleaner.php';

/**
 * Генерирует курсы с использованием пакетных вставок.
 * @param mysqli $mysql
 * @return array Массив созданных ID курсов
 * @throws Exception
 */
function CreateCourses(mysqli $mysql): array
{
    $courseTypes = ['quiz', 'video', 'audio'];
    $createdCourses = [];

    $mysql->begin_transaction();
    try {
        // Подготавливаем запросы заранее
        $stmtCourse = $mysql->prepare("INSERT INTO course (name, course_type, description) VALUES (?, ?, ?)");
        if (!$stmtCourse) throw new Exception("Prepare failed: " . $mysql->error);

        $stmtQuiz = $mysql->prepare("INSERT INTO quiz (course_id, source_url, weight, available_duration, state) VALUES (?, ?, ?, NULL, ?)");
        if (!$stmtQuiz) throw new Exception("Prepare failed: " . $mysql->error);

        $stmtVideo = $mysql->prepare("INSERT INTO video (course_id, source_url, duration, format, size) VALUES (?, ?, ?, ?, ?)");
        if (!$stmtVideo) throw new Exception("Prepare failed: " . $mysql->error);

        $stmtAudio = $mysql->prepare("INSERT INTO audio (course_id, source_url, duration) VALUES (?, ?, ?)");
        if (!$stmtAudio) throw new Exception("Prepare failed: " . $mysql->error);

        foreach ($courseTypes as $type) {
            $count = rand(100, 300);
            for ($i = 0; $i < $count; $i++) {
                $name = ucfirst($type) . " course №$i";
                $description = "Описание для $name";

                $stmtCourse->bind_param("sss", $name, $type, $description);
                $stmtCourse->execute();
                $courseId = $stmtCourse->insert_id;
                $createdCourses[] = $courseId;

                switch ($type) {
                    case 'quiz':
                        $source = "https://youtube.com/quiz/$courseId";
                        $weight = 'medium';
                        $state = 'ready';
                        $stmtQuiz->bind_param("isss", $courseId, $source, $weight, $state);
                        $stmtQuiz->execute();
                        break;
                    case 'video':
                        $source = "https://ispring.com/video/$courseId.mp4";
                        $duration = rand(300, 1200);
                        $format = 'mp4';
                        $size = rand(10000, 50000);
                        $stmtVideo->bind_param("isisi", $courseId, $source, $duration, $format, $size);
                        $stmtVideo->execute();
                        break;
                    case 'audio':
                        $source = "https://tg.com/audio/$courseId.mp3";
                        $duration = rand(120, 600);
                        $stmtAudio->bind_param("isi", $courseId, $source, $duration);
                        $stmtAudio->execute();
                        break;
                }
            }
        }

        $mysql->commit();
    } catch (Exception $e) {
        $mysql->rollback();
        throw $e;
    } finally {
        $stmtCourse->close();
        $stmtQuiz->close();
        $stmtVideo->close();
        $stmtAudio->close();
    }
    return $createdCourses;
}

/**
 * Генерирует вопросы для квизов с использованием пакетных вставок.
 * @param mysqli $db
 * @param array $quizzes
 * @throws Exception
 */
function CreateQuestions(mysqli $db, array $quizzes): void
{
    $db->begin_transaction();
    try {
        $question_stmt = $db->prepare("INSERT INTO quiz_question (quiz_id, text, type, picture_url) VALUES (?, ?, ?, ?)");
        if (!$question_stmt) throw new Exception("Prepare failed: " . $db->error);

        $mc_stmt = $db->prepare("INSERT INTO multiple_choice_question_available_values (question_id, value, is_correct) VALUES (?, ?, ?)");
        if (!$mc_stmt) throw new Exception("Prepare failed: " . $db->error);

        $seq_stmt = $db->prepare("INSERT INTO sequence_question_available_values (question_id, value, next_value_id) VALUES (?, ?, NULL)");
        if (!$seq_stmt) throw new Exception("Prepare failed: " . $db->error);

        foreach ($quizzes as $quiz_id) {
            $question_count = rand(3, 6);
            for ($i = 0; $i < $question_count; $i++) {
                $type = rand(0, 1) ? 'multiple_choice' : 'sequence';
                $text = ucfirst($type) . " question " . uniqid();
                $pic = rand(0, 1) ? "https://photos-ps-21/" : null;

                $question_stmt->bind_param("isss", $quiz_id, $text, $type, $pic);
                $question_stmt->execute();
                $question_id = $question_stmt->insert_id;

                if ($type === 'multiple_choice') {
                    $options = ['a', 'b', 'c', 'd'];
                    $correct_index = rand(0, count($options) - 1);
                    foreach ($options as $index => $value) {
                        $is_correct = $index === $correct_index;
                        $mc_stmt->bind_param("isi", $question_id, $value, $is_correct);
                        $mc_stmt->execute();
                    }
                } else {
                    $steps = ["Step 1", "Step 2", "Step 3"];
                    $ids = [];
                    foreach ($steps as $step) {
                        $seq_stmt->bind_param("is", $question_id, $step);
                        $seq_stmt->execute();
                        $ids[] = $seq_stmt->insert_id;
                    }
                    // Обновления next_value_id лучше делать отдельным запросом после всех вставок,
                    // либо собирать в батч-обновления, но для небольшого количества это не критично.
                    // Если очень много, то рассмотрите ON DUPLICATE KEY UPDATE или отдельную пакетную операцию.
                    for ($j = 0; $j < count($ids) - 1; $j++) {
                        $db->query("UPDATE sequence_question_available_values SET next_value_id = " . $ids[$j + 1] . " WHERE id = " . $ids[$j]);
                    }
                }
            }
        }
        $db->commit();
    } catch (Exception $e) {
        $db->rollback();
        throw $e;
    } finally {
        $question_stmt->close();
        $mc_stmt->close();
        $seq_stmt->close();
    }
}

/**
 * Создает квизы с использованием пакетных вставок.
 * @param mysqli $db
 * @param array $courses
 * @return array
 * @throws Exception
 */
function CreateQuizzes(mysqli $db, array $courses): array
{
    $quiz_ids = [];
    $db->begin_transaction();
    try {
        $stmt = $db->prepare("INSERT INTO quiz (course_id, source_url, weight, available_duration, state) VALUES (?, ?, ?, ?, ?)");
        if (!$stmt) throw new Exception("Prepare failed: " . $db->error);

        foreach ($courses as $course_id) {
            $quiz_count = rand(1, 3);
            for ($i = 0; $i < $quiz_count; $i++) {
                $url = "https://example.com/quiz/" . uniqid();
                $weight = rand(1, 5) . "_points";
                $duration = date('Y-m-d H:i:s', strtotime('+' . rand(1, 30) . ' days'));
                $state = 'ready';

                $stmt->bind_param("issss", $course_id, $url, $weight, $duration, $state);
                $stmt->execute();
                $quiz_ids[] = $stmt->insert_id;
            }
        }
        $db->commit();
    } catch (Exception $e) {
        $db->rollback();
        throw $e;
    } finally {
        $stmt->close();
    }
    return $quiz_ids;
}

/**
 * Создает пользователей с использованием пакетных вставок.
 * @param mysqli $mysql
 * @return array Массив созданных ID пользователей
 * @throws Exception
 */
function CreateUsers(mysqli $mysql): array
{
    $states = ['active', 'inactive', 'fired'];
    $names = ['Stepan', 'Dima', 'Miroslav', 'Vlad', 'Elysey', 'Michao', 'Kirill', 'Kostya'];
    $userIds = [];
    shuffle($names);

    $mysql->begin_transaction();
    try {
        $stmt = $mysql->prepare("INSERT INTO user (name, email, state, deleted_at) VALUES (?, ?, ?, NULL)");
        if (!$stmt) throw new Exception("Prepare failed: " . $mysql->error);

        foreach ($names as $name) {
            $email = strtolower($name) . '@ispring.com';
            $state = $states[array_rand($states)];

            $stmt->bind_param("sss", $name, $email, $state);
            $stmt->execute();
            $userIds[] = $stmt->insert_id;
        }
        $mysql->commit();
    } catch (Exception $e) {
        $mysql->rollback();
        throw $e;
    } finally {
        $stmt->close();
    }
    return $userIds;
}

/**
 * Зачисляет пользователей на курсы с использованием пакетных вставок.
 * @param mysqli $mysql
 * @param array $users
 * @param array $courses
 * @throws Exception
 */
function EnrollUsers(mysqli $mysql, array $users, array $courses): void
{
    $mysql->begin_transaction();
    try {
        $stmt = $mysql->prepare("INSERT INTO enrollment (user_id, course_id, start_date, end_date) VALUES (?, ?, ?, ?)");
        if (!$stmt) throw new Exception("Prepare failed: " . $mysql->error);

        foreach ($users as $user_id) {
            // Выбираем случайное количество курсов для зачисления
            $numCoursesToEnroll = rand(1, min(3, count($courses)));
            $course_ids_to_enroll = (array)array_rand(array_flip($courses), $numCoursesToEnroll);

            foreach ($course_ids_to_enroll as $course_id) {
                $startDate = new DateTime();
                $startDate->modify('-' . rand(1, 30) . ' days');
                $start = $startDate->format('Y-m-d H:i:s');

                $end = null;
                if (rand(0, 1)) {
                    $endDate = clone $startDate;
                    $endDate->modify('+' . rand(5, 20) . ' days');
                    $end = $endDate->format('Y-m-d H:i:s');
                }

                $stmt->bind_param("iiss", $user_id, $course_id, $start, $end);
                $stmt->execute();
            }
        }
        $mysql->commit();
    } catch (Exception $e) {
        $mysql->rollback();
        throw $e;
    } finally {
        $stmt->close();
    }
}

/**
 * Создает оценки для квизов с использованием пакетных вставок.
 * @param mysqli $db
 * @param array $quizzes
 * @throws Exception
 */
function CreateQuizMarks(mysqli $db, array $quizzes): void
{
    $quizMarkOptions = [
        ["mark" => 2, "min" => 0, "max" => 39],
        ["mark" => 3, "min" => 40, "max" => 59],
        ["mark" => 4, "min" => 60, "max" => 79],
        ["mark" => 5, "min" => 80, "max" => 100],
    ];

    $db->begin_transaction();
    try {
        $stmt = $db->prepare("INSERT INTO quiz_mark (quiz_id, mark, min_score, max_score) VALUES (?, ?, ?, ?)");
        if (!$stmt) throw new Exception("Prepare failed: " . $db->error);

        foreach ($quizzes as $quizId) {
            foreach ($quizMarkOptions as $opt) {
                $stmt->bind_param("iiii", $quizId, $opt['mark'], $opt['min'], $opt['max']);
                $stmt->execute();
            }
        }
        $db->commit();
    } catch (Exception $e) {
        $db->rollback();
        throw $e;
    } finally {
        $stmt->close();
    }
}

/**
 * Создает попытки прохождения тестов для зачислений с использованием пакетных вставок.
 * @param mysqli $db
 * @param array $enrollments
 * @param array $questions
 * @param array $mcValues
 * @param array $seqValues
 * @throws Exception
 */
function CreateAttemptsForEnrollments(mysqli $db, array $enrollments, array $questions, array $mcValues, array $seqValues): void
{
    $db->begin_transaction();
    try {
        $attemptStmt = $db->prepare("INSERT INTO attempt (enrollment_id, start_date, score, duration) VALUES (?, ?, ?, ?)");
        if (!$attemptStmt) throw new Exception("Prepare failed for attempt: " . $db->error);

        $answerStmt = $db->prepare("INSERT INTO quiz_attempt_answer (attempt_id, question_id, value) VALUES (?, ?, ?)");
        if (!$answerStmt) throw new Exception("Prepare failed for quiz_attempt_answer: " . $db->error);

        $mcAnswerStmt = $db->prepare("INSERT INTO quiz_attempt_multiple_choice (answer_id, value_id) VALUES (?, ?)");
        if (!$mcAnswerStmt) throw new Exception("Prepare failed for quiz_attempt_multiple_choice: " . $db->error);

        $seqAnswerStmt = $db->prepare("INSERT INTO quiz_attempt_sequence (answer_id, value_id, position) VALUES (?, ?, ?)");
        if (!$seqAnswerStmt) throw new Exception("Prepare failed for quiz_attempt_sequence: " . $db->error);

        foreach ($enrollments as $enroll) {
            $numAttempts = rand(0, 2);

            for ($i = 0; $i < $numAttempts; $i++) {
                $startDate = date('Y-m-d H:i:s', strtotime('-' . rand(0, 30) . ' days'));
                $duration = rand(300, 3600);
                $score = rand(0, 100);

                $attemptStmt->bind_param("isii", $enroll['id'], $startDate, $score, $duration);
                $attemptStmt->execute();
                $attemptId = $attemptStmt->insert_id;

                foreach ($questions as $question) {
                    if ($question['quiz_id'] !== $enroll['course_quiz_id']) {
                        continue;
                    }

                    $answerValue = null; // Для других типов вопросов, если необходимо
                    $answerStmt->bind_param("iis", $attemptId, $question['id'], $answerValue);
                    $answerStmt->execute();
                    $answerId = $answerStmt->insert_id;

                    if ($question['type'] === 'multiple_choice') {
                        $availableValues = array_filter($mcValues, fn($v) => $v['question_id'] === $question['id']);
                        if (empty($availableValues)) continue;

                        $selectedValuesIds = array_column($availableValues, 'id');
                        shuffle($selectedValuesIds);
                        $numToSelect = rand(1, count($selectedValuesIds));
                        $selectedValues = array_slice($selectedValuesIds, 0, $numToSelect);

                        foreach ($selectedValues as $valueId) {
                            $mcAnswerStmt->bind_param("ii", $answerId, $valueId);
                            $mcAnswerStmt->execute();
                        }
                    } elseif ($question['type'] === 'sequence') {
                        $availableValues = array_filter($seqValues, fn($v) => $v['question_id'] === $question['id']);
                        if (empty($availableValues)) continue;

                        $shuffledValuesIds = array_column($availableValues, 'id');
                        shuffle($shuffledValuesIds);

                        $position = 1;
                        foreach ($shuffledValuesIds as $valueId) {
                            $seqAnswerStmt->bind_param("iii", $answerId, $valueId, $position);
                            $seqAnswerStmt->execute();
                            $position++;
                        }
                    }
                }
            }
        }
        $db->commit();
    } catch (Exception $e) {
        $db->rollback();
        throw $e;
    } finally {
        $attemptStmt->close();
        $answerStmt->close();
        $mcAnswerStmt->close();
        $seqAnswerStmt->close();
    }
}

/**
 * Получает список зачислений с информацией о курсах и квизах
 */
function GetEnrollmentsWithQuizzes(mysqli $db): array
{
    $result = $db->query("
        SELECT e.id, e.user_id, e.course_id, q.id as course_quiz_id
        FROM enrollment e
        JOIN quiz q ON q.course_id = e.course_id
    ");
    if (!$result) {
        throw new Exception("Failed to get enrollments with quizzes: " . $db->error);
    }
    return $result->fetch_all(MYSQLI_ASSOC);
}

/**
 * Получает список вопросов для квизов
 */
function GetQuestions(mysqli $db): array
{
    $result = $db->query("SELECT id, quiz_id, type FROM quiz_question");
    if (!$result) {
        throw new Exception("Failed to get questions: " . $db->error);
    }
    return $result->fetch_all(MYSQLI_ASSOC);
}

/**
 * Получает варианты ответов для вопросов с множественным выбором
 */
function GetMultipleChoiceValues(mysqli $db): array
{
    $result = $db->query("SELECT id, question_id FROM multiple_choice_question_available_values");
    if (!$result) {
        throw new Exception("Failed to get multiple choice values: " . $db->error);
    }
    return $result->fetch_all(MYSQLI_ASSOC);
}

/**
 * Получает варианты ответов для вопросов с последовательностью
 */
function GetSequenceValues(mysqli $db): array
{
    $result = $db->query("SELECT id, question_id FROM sequence_question_available_values");
    if (!$result) {
        throw new Exception("Failed to get sequence values: " . $db->error);
    }
    return $result->fetch_all(MYSQLI_ASSOC);
}

try {
    $db = GetDatabaseConnection();
    $cleaner = new DatabaseCleaner($db);
    $cleaner->CleanAllTables();
    echo "Таблицы очищены!\n";

    $courses = CreateCourses($db);
    echo "Создано " . count($courses) . " курсов!\n";

    $quizzes = CreateQuizzes($db, $courses);
    echo "Создано " . count($quizzes) . " квизов!\n";

    CreateQuestions($db, $quizzes);
    echo "Созданы вопросы для квизов!\n";

    $users = CreateUsers($db);
    echo "Создано " . count($users) . " пользователей!\n";

    EnrollUsers($db, $users, $courses);
    echo "Пользователи зачислены на курсы!\n";

    CreateQuizMarks($db, $quizzes);
    echo "Оценки для квизов созданы!\n";

    // Получаем данные для создания попыток после того, как все вопросы и ответы созданы
    $enrollments = GetEnrollmentsWithQuizzes($db);
    echo "Получено " . count($enrollments) . " зачислений для обработки попыток.\n";

    $questions = GetQuestions($db);
    echo "Получено " . count($questions) . " вопросов.\n";

    $mcValues = GetMultipleChoiceValues($db);
    echo "Получено " . count($mcValues) . " вариантов для множественного выбора.\n";

    $seqValues = GetSequenceValues($db);
    echo "Получено " . count($seqValues) . " вариантов для последовательностей.\n";

    CreateAttemptsForEnrollments($db, $enrollments, $questions, $mcValues, $seqValues);
    echo "Попытки прохождения тестов созданы!\n";

    echo "Все хорошо, данные успешно сгенерированы!\n";

} catch (Exception $e) {
    die("Ошибка: " . $e->getMessage());
} finally {
    if ($db) {
        $db->close();
        echo "Соединение с базой данных закрыто.\n";
    }
}