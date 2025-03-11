# Задание 1

Последовательно приведите отношение к 1-й, 2-й и 3-й нормальной форме. 
Будьте готовы пояснить свое решение с помощью терминов из лекции.


### 1.1 - 5 баллов
__Попытки прохождения курса__.
Отношение __S__ (email, login, content_title, passed_scores, dates). 
- `email` – email пользователя
- `login` – login пользователяs
- `content_title` – наименование курса
- `passed_scores` – целочисленные баллы за попытку прохождения курса
- `dates` – даты попыток

Первая нормальная форма - та же таблица:
- `email` – email пользователя
- `login` – login пользователя
- `content_title` – наименование курса
- `passed_score` – средний балл за попытку прохождения курса
- `date` – даты попыток

Вторая нормальная форма - декомпозируем на таблицы Users и Attempts:
1. Таблица __Users__ или отношение __SE__ - `email`:
    - `email` – email пользователя
    - `login` – login пользователя

2. Таблица __Attempts__ или отношение __SECD__ - `email`, `content_title`,
 `date`:
    - `email` – email пользователя
    - `content_title` – наименование курса
    - `date` – даты попыток
    - `passed_scores` – средний балл за попытку прохождения курса

Третья нормальная форма уже сформирована, нет транзитивных зависимостей.

### 1.2 - 7 баллов
__Таблица истории оплаты газоснабжения__.
Отношение P (client_inn, volumes, date, addresses, costs). 
- `client_inn` - ИНН плательщика
- `volumes` - обьёмы потребляемого газа
- `date` - дата начисления
- `addresses` - адреса, по которым оплачивался газ, включая город, улицу,
                номер дома и квартиру
- `price` - цена за 1м3 газа в день начисления
- `costs` - суммы начислений, зависит от объёма поставленного газа 

Первая нормальная форма - все атрибуты содержат атомарные значения, 
нет повторяющихся групп данных:
- `client_inn` - ИНН плательщика
- `volume` - обьём потребляемого газа
- `cost` - сумма оплаты
- `date` - дата оплаты
- `adress` - адрес

Вторая нормальная форма - декомпозируем отношение P:
1. Отношение __PCA__
    - `adress`
    - client_inn

2. Отношение __PCAD__ 
    - `adress`
    - `date`
    - volume
    - cost

3. Отношение __PD__
    - `date`
    - price

Третья нормальная форма:
1. Отношение __PCA__
    - `adress`
    - client_inn

2. Отношение __PCAD__ 
    - `adress`
    - `date`
    - volume

3. Отношение __PD__
    - `date`
    - price

4. Отношение  __PCD__
    - `volume`
    - `price`
    - cost

### 1.3 - 8 баллов
__Таблица аттестаций студентов__.
Отношение A (student_email, teacher_emails, subjects, max_attestation_scores, 
min_attestation_scores, student_attestation_scores, date,
are_all_attestations_passed). 

Первая нормальная форма:
- `student_email` - email студента
- `teacher_email` - email преподавателя
- `subject` - предмет (уникальный)
- `date` - дата аттестации
---
- teacher_phone - телефон преподавателя
- teacher_phone_opertaion_system - оп. система телефона преподавателя
- max_attestation_score - максимальные балл за аттестацию
- min_attestation_score - минимальные проходные балл за аттестацию
- student_attestation_score - фактические балл студента за аттестацию
- are_all_attestations_passed - пройдены ли студентом все аттестации 

Вторая нормальная форма:
1.  Отношение __ASD__
    - `subject`
    - `date`
    - max_attestation_score
    - min_attestation_score

2. Отношение __ASD__
    - `student_email`
    - `date`
    - are_all_attestations_passed

3. Отношение __AT__
    - `teacher_email`
    - teacher_phone
    - teacher_phone_opertaion_system

4. Отношение __ASSD__
    - `student_email`
    - `subject`
    - `date`
    - student_attestation_score

5. Отношение __AST__
    - `subject`
    - `student_email`
    - teacher_email

---
Третья нормальная форма:
1. Отношение __ASD__ - Аттестации
    - `subject`
    - `date`
    - max_attestation_score
    - min_attestation_score

2. Отношение __ASD__ 
    - `student_email`
    - `date`
    - are_all_attestations_passed

3. Отношение __ASSD__
    - `student_email`
    - `subject`
    - `date`
    - student_attestation_score

4. Отношение __AT__
    - `teacher_email`
    - teacher_phone

5. Отношение __ATP__:
    - `teacher_phone`
    - teacher_phone_opertaion_system

6. Отношение __AST__
    - `subject`
    - `student_email`
    - teacher_email

### 1.4 - 10 баллов
__Прейскурант цен запчастей для велосипеда__
Первая нормальная форма:
`provider_inn` — ИНН поставщика (первичный ключ).
`provider_city` — город поставщика.
`provider_address` — полный адрес поставщика.
`provider_name` — имя поставщика.
`provider_score` — средняя оценка поставщика.
`is_provider_trusted` — флаг доверия поставщику.
`spare_part_name` — наименование запчасти.
`bike_type` — тип велосипеда.
`price` — цена запчасти для конкретного велосипеда.
---
Вторая нормальная форма
1. Отношение __BI__
    - `provider_inn` 
    - provider_name
    - provider_city 
    - provider_address
    - is_provider_trusted 
    - provider_score

2. Отношение __BISB__ 
    - `provider_inn`
    - `spare_part_name`
    - `bike_type `
    - price
---
Третья нормальная форма:
1. Отношение __BI__
    - `provider_inn`
    - provider_name 
    - provider_score
    - provider_address
    
2. Отношение __BA__
    - `provider_address`
    - provider_city  

3. Отношение __BS__
    - `provider_score`
    - is_provider_trusted

4. Отношение __BISB__ 
    - `provider_inn`
    - `spare_part_name`
    - `bike_type` 
    - price