<?php
const DB_HOST = 'localhost';
const DB_USER = 'sc_user';
const DB_PASS = '1234';
const DB_NAME = 'sc';
const DB_PORT = '3306';

/**
 * Возвращает подключение к MySQL
 * @return mysqli
 * @throws Exception Если не смоги подключиться
 */
function GetDatabaseConnection(): mysqli
{
    static $connection = null;

    if ($connection !== null && $connection->ping()) {
        return $connection;
    }

    $connection = new mysqli(DB_HOST, DB_USER, DB_PASS, DB_NAME, DB_PORT);

    if ($connection->connect_errno) {
        throw new Exception("Ошибка подключения к БД: " . $connection->connect_error);
    }

    return $connection;
}
