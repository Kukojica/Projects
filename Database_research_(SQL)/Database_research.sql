/* Поиск количества вопросов, которые набрали больше 300 очков или как минимум 100 раз были добавлены в «Закладки». */

SELECT COUNT(id)
FROM stackoverflow.posts
WHERE (score > 300 OR favorites_count >= 100) 
    AND post_type_id = 1

/* Определение среднего количества вопросов в день, которые задавали с 1 по 18 ноября 2008 включительно. */

WITH cn AS
    (SELECT COUNT(*) AS cnt,
           creation_date:: date AS dt
    FROM stackoverflow.posts
    WHERE post_type_id = 1
          AND creation_date::date BETWEEN '2008-11-01' AND '2008-11-18'
    GROUP BY dt)
SELECT ROUND(AVG(cnt))
FROM cn

/* Определение количества пользователей, которые получили значки сразу в день регистрации. */

SELECT COUNT(DISTINCT u.id)
FROM stackoverflow.users u
JOIN stackoverflow.badges b ON u.id = b.user_id
WHERE b.creation_date::date = u.creation_date::date

/* Определение количества уникальных постов пользователя с именем Joel Coehoorn, которые получили хотя бы один голос. */
  
SELECT COUNT(DISTINCT p.id)
FROM stackoverflow.posts p
JOIN stackoverflow.users u ON p.user_id = u.id
JOIN stackoverflow.votes v ON p.id = v.post_id
WHERE u.display_name = 'Joel Coehoorn'

/* Выгрузка всех полей таблицы vote_types м добавление к таблице поля rank. */

SELECT *,
      RANK() OVER (ORDER BY id DESC)         
FROM stackoverflow.vote_types
ORDER BY id

/* Отображение 10 пользователей, которые поставили больше всего голосов типа Close. */

WITH vote AS
    (SELECT COUNT(v.id) AS cnt,
           u.id AS i,
           ROW_NUMBER() OVER (ORDER BY COUNT(v.id) DESC) AS n
    FROM stackoverflow.votes v
    JOIN stackoverflow.users u ON v.user_id = u.id
    WHERE vote_type_id = 6
    GROUP BY i
    ORDER BY cnt DESC)
SELECT i,
       cnt
FROM vote
WHERE n < 11
ORDER BY cnt DESC, i DESC

/* Отображение 10 пользователей по количеству значков, 
полученных в период с 15 ноября по 15 декабря 2008 года включительно. */

WITH badge AS
    (SELECT user_id,
           COUNT(id) AS cnt,
           DENSE_RANK() OVER (ORDER BY COUNT(id) DESC) AS rank,
           ROW_NUMBER() OVER (ORDER BY COUNT(id) DESC) AS n
    FROM stackoverflow.badges
    WHERE creation_date::date BETWEEN '2008-11-15' AND '2008-12-15'
    GROUP BY user_id)
SELECT user_id,
       cnt,
       rank
FROM badge
WHERE n <= 10
ORDER BY cnt DESC, user_id

  /* Определение того, сколько в среднем очков получает пост каждого пользователя. */

SELECT title,
       user_id,
       score,
       ROUND(AVG(score) OVER (PARTITION BY user_id))
FROM stackoverflow.posts
WHERE title IS NOT NULL
      AND score != 0

  /* Отображение заголовков постов, которые были написаны пользователями, получившими более 1000 значков. */

WITH ui AS    
    (SELECT user_id,
           COUNT(id) AS cnt
    FROM stackoverflow.badges 
    GROUP BY user_id
    HAVING COUNT(id) > 1000)
SELECT title
FROM stackoverflow.posts p
JOIN ui ON ui.user_id = p.user_id
WHERE title IS NOT NULL

  /* Выгрузка данных о пользователях из США и разделение пользователей на три группы в зависимости от количества просмотров их профилей. */

SELECT id,
       views,
       CASE
           WHEN views >= 350 THEN 1
           WHEN views >= 100 AND views < 350 THEN 2
           WHEN views < 100 THEN 3
       END
FROM stackoverflow.users
WHERE location LIKE '%United States%'
      AND views != 0

  /* Отображение лидеров каждой группы — пользователей, которые набрали максимальное число просмотров в своей группе. */

SELECT id,
       cat,
       views
FROM       
    (SELECT id,
        MAX(views) OVER (PARTITION BY cat) AS mx,
        views,
        cat
    FROM
        (SELECT id,
               views,
               CASE
                   WHEN views >= 350 THEN 1
                   WHEN views >= 100 AND views < 350 THEN 2
                   WHEN views < 100 THEN 3
               END AS cat
        FROM stackoverflow.users
        WHERE location LIKE '%United States%'
              AND views != 0) AS cats) AS max_c
WHERE views = mx
ORDER BY views DESC, id ASC

  /* Подсчет ежедневного прироста новых пользователей в ноябре 2008 года. */

WITH user_cnt AS
    (SELECT EXTRACT(DAY FROM creation_date::date) AS day,
           COUNT(id) AS cnt
    FROM stackoverflow.users
    WHERE DATE_TRUNC('month', creation_date::date) = '2008-11-01'
    GROUP BY day)
SELECT day,
       cnt,
       SUM(cnt) OVER (ORDER BY day)
FROM user_cnt

  /* Поиск интервала между регистрацией и временем создания первого поста для каждого пользователя,
  который написал хотя бы один пост. */

SELECT DISTINCT ps.user_id,
       MIN(ps.creation_date) OVER (PARTITION BY ps.user_id) - u.creation_date
FROM stackoverflow.users u
JOIN stackoverflow.posts ps ON ps.user_id = u.id

  /* Подсчет общей суммы просмотров постов за каждый месяц 2008 года. */

SELECT DATE_TRUNC('month', creation_date)::date AS dt,
      SUM(views_count) AS s
FROM stackoverflow.posts
GROUP BY dt
ORDER BY s DESC

  /* Отображение имен самых активных пользователей, которые в первый месяц после регистрации (включая день регистрации) дали больше 100 ответов. */

SELECT u.display_name,
       COUNT(user_id)
FROM stackoverflow.posts ps
JOIN stackoverflow.users u ON ps.user_id = u.id
WHERE post_type_id = 2
GROUP BY u.display_name
HAVING COUNT()

  /* Отображение количества постов за 2008 год по месяцам. */

SELECT DATE_TRUNC('month', ps.creation_date)::date,
       COUNT(ps.id)
FROM stackoverflow.posts ps
WHERE ps.user_id in (SELECT u.id AS u_id
    FROM stackoverflow.posts ps
    JOIN stackoverflow.users u ON ps.user_id = u.id
    WHERE DATE_TRUNC('month', u.creation_date) = '2008-09-01'
          AND DATE_TRUNC('month', ps.creation_date) = '2008-12-01')
GROUP BY 1
ORDER BY 1 DESC

  /* Отображение полей с: идентификатором пользователя, который написал пост; датой создания поста; количеством просмотров у текущего поста;
суммой просмотров постов автора с накоплением. */

SELECT user_id,
       creation_date,
       views_count,
       SUM(views_count) OVER (PARTITION BY user_id ORDER BY creation_date)
FROM stackoverflow.posts
ORDER BY user_id

  /* Определение того, сколько в среднем дней в период с 1 по 7 декабря 2008 года включительно пользователи взаимодействовали с платформой. */

WITH puk AS   
     (SELECT DISTINCT user_id,
               COUNT(DISTINCT creation_date::date) cnt
        FROM stackoverflow.posts
        WHERE creation_date::date BETWEEN '2008-12-01' AND '2008-12-07'
        GROUP BY 1)
SELECT ROUND(AVG(cnt))
FROM puk

  /* Подсчет того, на сколько процентов менялось количество постов ежемесячно с 1 сентября по 31 декабря 2008 года. */

SELECT EXTRACT(MONTH FROM creation_date),
       COUNT(id),
       ROUND(((COUNT(id) * 100)::numeric / LAG(COUNT(id)) OVER()) - 100, 2)
FROM stackoverflow.posts
WHERE DATE_TRUNC('month', creation_date)::date BETWEEN '2008-09-01' AND '2008-12-01'
GROUP BY 1

  /* Выгрузка данных активности пользователя, который опубликовал больше всего постов за всё время. */

WITH usr AS    
    (SELECT user_id AS i,
           COUNT(id) AS cnt
    FROM stackoverflow.posts
    GROUP BY 1
    ORDER BY 2 DESC
    LIMIT 1)
SELECT EXTRACT(WEEK FROM creation_date),
       MAX(creation_date)
FROM usr
JOIN stackoverflow.posts ps ON usr.i = ps.user_id
WHERE creation_date::date BETWEEN '2008-10-01' AND '2008-10-31'
GROUP BY 1
