<?php

class DatabaseCleaner
{
    private mysqli $mysql;

    public function __construct(mysqli $mysql)
    {
        $this->mysql = $mysql;
    }

    /**
     * @throws Exception
     */
    public function CleanAllTables(): true
    {
        try {
            // Отключаем проверку внешних ключей для безопасного удаления
            $this->mysql->query('SET FOREIGN_KEY_CHECKS = 0');

            // Таблицы в порядке обратном их зависимостям (от дочерних к родительским)
            $tables = [
                'quiz_attempt_sequence',
                'quiz_attempt_multiple_choice',
                'quiz_attempt_answer',
                'attempt',
                'enrollment',
                'sequence_question_available_values',
                'multiple_choice_question_available_values',
                'quiz_question',
                'quiz_mark',
                'quiz',
                'audio',
                'video',
                'user',
                'course'
            ];

            foreach ($tables as $table) {
                $this->mysql->query("TRUNCATE TABLE `$table`");
            }

            // Включаем проверку внешних ключей обратно
            $this->mysql->query('SET FOREIGN_KEY_CHECKS = 1');

            return true;
        } catch (PDOException $e) {
            // В случае ошибки включаем проверку внешних ключей обратно
            $this->mysql->query('SET FOREIGN_KEY_CHECKS = 1');
            throw new Exception("Error cleaning database: " . $e->getMessage());
        }
    }
}
