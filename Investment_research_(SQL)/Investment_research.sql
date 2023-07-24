/* Подсчёт закрытых компаний */

SELECT COUNT(id)
FROM company
WHERE status = 'closed'

/* Отображение количества привлечённых средств для новостных компаний США. */

SELECT funding_total
FROM company
WHERE category_code = 'news'
      AND country_code = 'USA'
ORDER BY funding_total DESC

/* Поиск общей суммы сделок по покупке одних компаний другими в долларах */

SELECT SUM(price_amount)
FROM acquisition
WHERE term_code = 'cash'
      AND EXTRACT(YEAR FROM CAST(acquired_at AS date)) BETWEEN '2011' AND '2013'

/* Отображение имени, фамилии и названия аккаунтов людей в твиттере,
у которых названия аккаунтов начинаются на 'Silver'. */

SELECT first_name,
       last_name,
       twitter_username
FROM people
WHERE twitter_username LIKE 'Silver%'

/* Вывод на экран всей информации о людях, 
у которых названия аккаунтов в твиттере содержат подстроку 'money', 
а фамилия начинается на 'K'. */

SELECT *
FROM people
WHERE twitter_username LIKE '%money%'
      AND last_name LIKE 'K%'

/* Отображение для каждой страны общей суммы привлечённых инвестиций, 
которые получили компании, зарегистрированные в этой стране. */

SELECT country_code,
       SUM(funding_total) AS fund_tot
FROM company
GROUP BY country_code
ORDER BY fund_tot DESC

/* Составление таблицы, которая содержит дата проведения раунда, 
а также минимальное и максимальное значения суммы инвестиций, привлечённых в эту дату. 
Минимальное значение суммы инвестиций не должно быть равно нулю и максимальному значению.  */

SELECT CAST(funded_at AS date) AS fund_date,
       MIN(raised_amount),
       MAX(raised_amount)
FROM funding_round
GROUP BY fund_date
HAVING MIN(raised_amount) != 0
       AND MIN(raised_amount) != MAX(raised_amount)

/* Создание поля с категориями по параметрам */

SELECT *,
      CASE
          WHEN invested_companies >= 100 THEN 'high_activity'
          WHEN invested_companies < 100 AND invested_companies >= 20 THEN 'middle_activity'
          WHEN invested_companies < 20 THEN 'low_activity'
      END
FROM fund

/* Для каждой из категорий, назначенных в предыдущем задании, 
  посчитаем округлённое до ближайшего целого числа среднее количество инвестиционных раундов, 
  в которых фонд принимал участие. */ 

SELECT
       CASE
           WHEN invested_companies>=100 THEN 'high_activity'
           WHEN invested_companies>=20 THEN 'middle_activity'
           ELSE 'low_activity'
       END AS activity,
      ROUND(AVG(investment_rounds)) AS avg_round
FROM fund
GROUP BY activity
ORDER BY avg_round

/* Анализ стран с фондами, которые чаще всего инвестируют в стартапы */

SELECT country_code,
       MIN(invested_companies),
       MAX(invested_companies),
       AVG(invested_companies)
FROM fund
WHERE EXTRACT(YEAR FROM CAST(founded_at AS date)) BETWEEN '2010' AND '2012'
GROUP BY country_code
HAVING MIN(invested_companies) > 0
ORDER BY AVG(invested_companies) DESC, country_code
LIMIT 10;

/* Отображение имени и фамилии всех сотрудников стартапов с  добавлением поля 
с названием учебного заведения, которое окончил сотрудник, если эта информация известна. */

SELECT first_name,
       last_name,
       ed.instituition
FROM people AS ppl
LEFT JOIN education AS ed ON ppl.id = ed.person_id

/* Топ 5 компаний по количеству университетов, которые окончили их сотрудники. */

SELECT c.name,
       COUNT(DISTINCT edu.instituition) AS inst_count
FROM company AS c
INNER JOIN people AS ppl ON c.id = ppl.company_id
INNER JOIN education AS edu ON ppl.id = edu.person_id
GROUP BY c.name
ORDER BY inst_count DESC
LIMIT 5;

/* Список с уникальными названиями закрытых компаний, 
для которых первый раунд финансирования оказался последним.. */

SELECT DISTINCT c.name
FROM company AS c
INNER JOIN funding_round as fr ON c.id = fr.company_id
WHERE c.status = 'closed'
      AND fr.is_last_round = 1
      AND fr.is_first_round = 1

/* Список уникальных номеров сотрудников, которые работают в компаниях, 
отобранных в предыдущем задании. */

SELECT id
FROM people AS ppl
WHERE company_id IN (SELECT c.id
                   FROM company AS c
                   INNER JOIN funding_round AS fr ON c.id = fr.company_id
                   WHERE c.status = 'closed'
                         AND is_first_round = 1
                         AND is_last_round = 1)

/* Таблица, в которую вошли пары с номерами сотрудников из предыдущей задачи 
и учебным заведением, которое окончил сотрудник. */

SELECT DISTINCT ppl.id AS person,
       edu.instituition AS inst
FROM people AS ppl
RIGHT JOIN education AS edu ON ppl.id = edu.person_id
WHERE company_id IN (SELECT c.id
                      FROM company AS c
                       LEFT JOIN funding_round AS fr ON c.id = fr.company_id
                        WHERE c.status = 'closed'
                         AND fr.is_first_round = 1
                         AND fr.is_last_round = 1)

/* Количество учебных заведений для каждого сотрудника из предыдущего задания. */

SELECT DISTINCT ppl.id as person,
       COUNT(edu.instituition) as inst_count
FROM people AS ppl
INNER JOIN education AS edu ON ppl.id = edu.person_id
WHERE company_id IN (SELECT c.id
                   FROM company AS c
                   INNER JOIN funding_round AS fr ON c.id = fr.company_id
                   WHERE c.status = 'closed'
                         AND is_first_round = 1
                         AND is_last_round = 1)
GROUP BY person

/* Среднее число учебных заведений, которые окончили сотрудники разных компаний. */

SELECT AVG(sort.count_inst)
FROM
    (SELECT ppl.id,
        COUNT(edu.instituition) AS count_inst
    FROM people AS ppl
    INNER JOIN education AS edu ON ppl.id = edu.person_id
    WHERE company_id IN (SELECT c.id
                       FROM company AS c
                       INNER JOIN funding_round AS fr ON c.id = fr.company_id
                       WHERE c.status = 'closed'
                             AND is_first_round = 1
                             AND is_last_round = 1)
    GROUP BY ppl.id) AS sort

/* Среднее число учебных заведений, которые окончили сотрудники Facebook. */

SELECT AVG(sort.inst_count)
FROM (SELECT ppl.id,
            COUNT(edu.instituition) AS inst_count
        FROM people AS ppl
        INNER JOIN education AS edu ON ppl.id = edu.person_id
        WHERE company_id = (SELECT id
                            FROM company
                            WHERE name = 'Facebook')
        GROUP BY ppl.id) AS sort

/* Таблица с данными о компаниях, в истории которых было больше шести важных этапов, 
а раунды финансирования проходили с 2012 по 2013 год включительно. */

SELECT sort.fund AS name_of_fund,
       sort.company AS name_of_company,
       sort.amount AS amount
FROM
    (SELECT c.name AS company,
       fnd.name AS fund,
       c.id AS id,
       c.milestones,
       fr.raised_amount AS amount
    FROM investment AS inv
    LEFT JOIN company AS c ON inv.company_id = c.id
    LEFT JOIN fund AS fnd ON inv.fund_id = fnd.id
    INNER JOIN funding_round AS fr ON inv.funding_round_id = fr.id      
    WHERE EXTRACT(YEAR FROM CAST(fr.funded_at AS date)) IN ('2012','2013')) AS sort
WHERE sort.milestones > 6

/* Таблица с данными о: названии компании; сумме сделки; названии компании, которую купили; 
сумме инвестиций, вложенных в купленную компанию; доле, которая отображает, 
во сколько раз сумма покупки превысила сумму вложенных в компанию инвестиций, 
округлённая до ближайшего целого числа. */

WITH 
fund_ac AS (SELECT name,
                   funding_total,
                   id
            FROM company
            WHERE id IN (SELECT acquired_company_id
                        FROM acquisition)),
nm AS (SELECT name,
             id
        FROM company
        WHERE id IN (SELECT acquiring_company_id
                    FROM acquisition))
SELECT nm.name,
       price_amount,
       fund_ac.name,
       fund_ac.funding_total,
       ROUND(price_amount / fund_ac.funding_total)
FROM acquisition AS acq
LEFT JOIN fund_ac ON acq.acquired_company_id = fund_ac.id
LEFT JOIN nm ON acq.acquiring_company_id = nm.id
WHERE price_amount != 0
      AND fund_ac.funding_total != 0
ORDER BY price_amount DESC, fund_ac.name
LIMIT 10;

/* Таблица, в которую вошли названия компаний из категории social, 
получившие финансирование с 2010 по 2013 год включительно. */

SELECT c.name,
       EXTRACT(MONTH FROM CAST(fr.funded_at AS date))
FROM company AS c
LEFT JOIN funding_round AS fr ON c.id = fr.company_id
WHERE EXTRACT(YEAR FROM CAST(funded_at AS date)) IN ('2010', '2011', '2012', '2013')
      AND category_code = 'social'
      AND fr.raised_amount != 0

/* Отбор данных по месяцам с 2010 по 2013 год, когда проходили инвестиционные раунды. */

WITH
first AS (SELECT EXTRACT(MONTH FROM CAST(fr.funded_at AS date)) AS month,
               COUNT(DISTINCT fn.name) AS name
        FROM funding_round AS fr
        LEFT JOIN investment AS inv ON fr.id = inv.funding_round_id
        LEFT JOIN fund AS fn ON inv.fund_id = fn.id
        WHERE EXTRACT(YEAR FROM CAST(fr.funded_at AS date)) BETWEEN '2010' AND '2013'
              AND fn.country_code = 'USA'
        GROUP BY month),
second AS (SELECT EXTRACT(MONTH FROM CAST(acquired_at AS date)) AS month,
                  COUNT(acquired_company_id) AS comp,
                  SUM(price_amount) AS price
          FROM acquisition
          GROUP BY month)
SELECT first.month,
       first.name,
       second.comp,
       second.price
FROM first
INNER JOIN second ON first.month = second.month
ORDER BY first.month          

/* Составление сводной таблицы и вывод средней суммы инвестиций для стран, 
в которых есть стартапы, зарегистрированные в 2011, 2012 и 2013 годах. */

WITH
yr_11 AS (SELECT country_code,
                   AVG(funding_total) AS year_2011
            FROM company
            WHERE EXTRACT(YEAR FROM CAST(founded_at AS date)) = '2011'
            GROUP BY country_code),
yr_12 AS (SELECT country_code,
                   AVG(funding_total) AS year_2012
            FROM company
            WHERE EXTRACT(YEAR FROM CAST(founded_at AS date)) = '2012'
            GROUP BY country_code),
yr_13 AS (SELECT country_code,
                   AVG(funding_total) AS year_2013
            FROM company
            WHERE EXTRACT(YEAR FROM CAST(founded_at AS date)) = '2013'
            GROUP BY country_code)
SELECT yr_11.country_code,
       yr_11.year_2011,
       yr_12.year_2012,
       yr_13.year_2013
FROM yr_11
INNER JOIN yr_12 ON yr_11.country_code = yr_12.country_code
INNER JOIN yr_13 ON yr_11.country_code = yr_13.country_code
ORDER BY year_2011 DESC
