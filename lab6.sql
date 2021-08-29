-- написать запрос суммы очков с группировкой и сортировкой по годам
SELECT YEAR_GAME,
       SUM(POINTS)
FROM STATISTIC
GROUP BY YEAR_GAME
ORDER BY YEAR_GAME;
-- написать cte показывающее тоже самое
WITH T1 AS
  (SELECT YEAR_GAME,
          POINTS
   FROM STATISTIC
   ORDER BY YEAR_GAME)
SELECT YEAR_GAME,
       SUM (POINTS)
FROM T1
GROUP BY YEAR_GAME;
-- используя функцию LAG вывести кол-во очков по всем игрокам за текущий код и за предыдущий.
WITH T1 AS
  (SELECT YEAR_GAME,
          SUM(POINTS)
   FROM STATISTIC
   WHERE YEAR_GAME >=2019
   GROUP BY YEAR_GAME
   ORDER BY YEAR_GAME DESC)
SELECT YEAR_GAME,
       SUM AS SUM_YEAR,
              LAG(SUM, 1) OVER (
                                ORDER BY SUM) AS SUM_PREVIOUS_YEAR
FROM T1;
