-- 1. How many olympics games have been held?
SELECT
    COUNT(DISTINCT games) AS total_olympics_games
FROM athlete_events;

-- 2. List down all Olympics games held so far.
-- We found 1956 Summer Olympics hold by Melbourne & Stockholm together
SELECT
    DISTINCT year,
    season,
    city
FROM athlete_events
ORDER BY year;

-- 3. Mention the total no of nations who participated in each olympics game?

SELECT
    games,
	count(1) as num_of_nations
FROM
(SELECT 
    distinct games,
	n.region
FROM athlete_events a
JOIN noc_regions n
ON a.noc = n.noc
GROUP BY games,n.region) as t
GROUP BY games
ORDER BY games;

-- Q4. Which year saw the highest and lowest no of countries participating in olympics

WITH A as
(SELECT
    games,
	num_of_nations,
	dense_rank()over(order by num_of_nations) as rk1,
	dense_rank()over(order by num_of_nations desc) as rk2
FROM
(SELECT
    games,
	count(distinct noc) as num_of_nations
FROM athlete_events
GROUP BY games) as t)

SELECT
    MAX(case WHEN rk1 = 1 THEN concat(games,'-',num_of_nations) end) as lowest_countries,
	MAX(case WHEN rk2 = 1 THEN concat(games,'-',num_of_nations) end) as highest_countries
FROM A;

-- 5. Which nation has participated in all of the olympic games
-- step 1.Build CTE to find the number of games that each region attend,
-- step 2.Then find distinct total games
-- step 3.Finally JOIN 2 tables together to find the region that have the same attendence with total games

WITH participated_games AS
(SELECT
    region,
	count(*) as participated_games
FROM
(SELECT
    distinct games,
	region
FROM athlete_events a
JOIN noc_regions n
ON a.noc = n.noc
GROUP BY games,region
ORDER BY games) as t1
GROUP BY region)

SELECT
    region,
	participated_games
FROM participated_games p 
JOIN 
(SELECT
    COUNT(DISTINCT games) as total_games
 FROM athlete_events) as t2
 ON p.participated_games = t2.total_games;
 
-- 6. Identify the sport which was played in all summer olympics.
-- step 1. find total no of summer olympic games
-- step 2. find for each sport,how many games where they played in
-- step 3. compare 1 & 2

WITH number_of_games AS
(SELECT 
    distinct sport,
	count(distinct games) as num_of_games
FROM athlete_events
WHERE season = 'Summer'
GROUP BY sport)

SELECT
    sport,
	num_of_games
FROM number_of_games n
JOIN 
(SELECT
    COUNT(DISTINCT games) as total_summer_games
FROM athlete_events a
WHERE season = 'Summer') as t
ON n.num_of_games = t.total_summer_games;

-- 7. Which Sports were just played only once in the olympics.
-- Step 1. find number of sport played in each games
-- Step 2. find sport only played once

with t1 as
(select sport, count(1) as no_of_games
from
(select distinct games, sport
 from athlete_events) as a1
 group by sport)

SELECT
    t1.sport,
	no_of_games,
	games
FROM t1
JOIN 
(SELECT 
    distinct games,
    sport
FROM athlete_events) as a2
ON t1.sport = a2.sport
WHERE t1.no_of_games = 1
ORDER BY sport;

-- 8. Fetch the total no of sports played in each olympic games.
SELECT
    DISTINCT games,
    COUNT(DISTINCT sport) AS no_of_games
FROM athlete_events
GROUP BY games
ORDER BY no_of_games DESC;

-- 9. Fetch oldest athletes to win a gold medal
-- step 1. find athlete who won the gold medal
-- step 2. filter athlete by age
SELECT
    DISTINCT name,
    sex,
    age,
    team,
    games,
    city,
    sport,
    event,
    medal
FROM
(SELECT
    DISTINCT name,
    sex,
    age,
    team,
    games,
    city,
    sport,
    event,
    medal,
    DENSE_RANK()OVER(ORDER BY age DESC) AS rk
FROM athlete_events
WHERE medal = 'Gold' AND age != 'NA') AS t
WHERE rk = 1;

-- 10. Find the Ratio of male and female athletes participated in all olympic games.
-- step 1. Count the number of female&male athletes
-- step 2. Calculate proportion of sex
SELECT
    CONCAT('1:',CAST(ROUND(Male/CAST(Female AS decimal(7,2)),2) AS Float))sex_ration
FROM
(SELECT
    COUNT(CASE WHEN sex = 'M' THEN id END) AS Male,
    COUNT(CASE WHEN sex = 'F' THEN id END) AS Female
FROM athlete_events) as t;

-- 11. Fetch the top 5 athletes who have won the most gold medals.
-- Step 1. find the number of gold medals won by each thlete
-- Step 2. find top 5 athletes who won the most gold medals
SELECT
    name,
    no_of_medals
FROM
(SELECT 
    name,
    COUNT(medal) AS no_of_medals,
    DENSE_RANK()OVER(ORDER BY COUNT(medal) DESC) AS rk
FROM athlete_events
WHERE medal = 'Gold'
GROUP BY name) AS t
WHERE rk <= 5;

-- 12. Fetch the top 5 athletes who have won the most medals (gold/silver/bronze).
-- step 1. find the number of medals won by each athlete
-- step 2. filter top 5 athletes with the most medals
SELECT
    name,
    no_of_medals
FROM
(SELECT
    name,
    COUNT(medal) AS no_of_medals,
    DENSE_RANK()OVER(ORDER BY COUNT(medal) DESC) AS rk
FROM athlete_events
WHERE medal != 'NA'
GROUP BY name) as t
WHERE rk <= 5;

-- 13. Fetch the top 5 most successful countries in olympics. 
-- Success is defined by no of medals won.
-- Step 1: Join two tables to find the number of medals won by each country
-- Step 2: Filter top 5 countries with the most medals
SELECT
    region,
    total_medals,
    rk
FROM
(SELECT
    region,
    COUNT(medal) AS total_medals,
    DENSE_RANK()OVER(ORDER BY COUNT(medal) DESC) AS rk
FROM athlete_events a
JOIN noc_regions n
ON a.noc = n.noc
WHERE medal != 'NA'
GROUP BY region) as t
WHERE rk <= 5;

-- 14. List down total gold, silver and bronze medals won by each country.
-- Step 1. Join two tables to find gold,silver,bronze medals won by each country
SELECT
    region,
    COUNT(CASE WHEN medal = 'Gold' THEN medal END) AS Gold,
    COUNT(CASE WHEN medal = 'Silver' THEN medal END) AS Silver,
    COUNT(CASE WHEN medal = 'Bronze' THEN medal END) AS Bronze
FROM athlete_events a
JOIN noc_regions n
ON a.noc = n.noc
WHERE medal != 'NA'
GROUP BY region
ORDER BY Gold DESC,Silver DESC,Bronze DESC;

-- 15. List down total gold, silver and bronze medals won by each country corresponding to each olympic games.
-- Step 1: Join two tables to find gold, silver,bronze medals won by each contry
SELECT
    games,
    region,
    COUNT(CASE WHEN medal = 'Gold' THEN medal END) AS Gold,
    COUNT(CASE WHEN medal = 'Silver' THEN medal END) AS Silver,
    COUNT(CASE WHEN medal = 'Bronze' THEN medal END) AS Bronze
FROM athlete_events a
JOIN noc_regions n
ON a.noc = n.noc
WHERE medal != 'NA'
GROUP BY games, region
ORDER BY games,region;

-- 16. Identify which country won the most gold, most silver and most bronze medals in each olympic games.
-- Step 1: Join two tables to find the number of gold,silver and bronze medal won by each region in each olympic
-- Step 2: find the country that won the most gold,silver and bronze medals
SELECT
    DISTINCT games,
    CONCAT(FIRST_VALUE(region)OVER(PARTITION BY games ORDER BY Gold DESC),'-',
          FIRST_VALUE(Gold)OVER(PARTITION BY games ORDER BY Gold DESC)) AS max_gold,
    CONCAT(FIRST_VALUE(region)OVER(PARTITION BY games ORDER BY Silver DESC),'-',
          FIRST_VALUE(Silver)OVER(PARTITION BY games ORDER BY Silver DESC)) AS max_silver,
    CONCAT(FIRST_VALUE(region)OVER(PARTITION BY games ORDER BY Bronze DESC),'-',
          FIRST_VALUE(Bronze)OVER(PARTITION BY games ORDER BY Bronze DESC)) AS max_bronze
FROM
(SELECT
    games,
    region,
    COUNT(CASE WHEN medal = 'Gold' THEN medal END) AS Gold,
    COUNT(CASE WHEN medal = 'Silver' THEN medal END) AS Silver,
    COUNT(CASE WHEN medal = 'Bronze' THEN medal END) AS Bronze
FROM athlete_events a
JOIN noc_regions n
ON a.noc = n.noc
GROUP BY games,region) as t
ORDER BY games;

-- 17. Identify which country won the most gold, most silver, most bronze medals and the most medals in each olympic games.

SELECT
    DISTINCT games,
    CONCAT(FIRST_VALUE(region)OVER(PARTITION BY games ORDER BY Total_medals DESC),'-',
          FIRST_VALUE(Total_medals)OVER(PARTITION BY games ORDER BY Total_medals DESC)) AS max_total_medals,
    CONCAT(FIRST_VALUE(region)OVER(PARTITION BY games ORDER BY Gold DESC),'-',
          FIRST_VALUE(Gold)OVER(PARTITION BY games ORDER BY Gold DESC)) AS max_gold,
    CONCAT(FIRST_VALUE(region)OVER(PARTITION BY games ORDER BY Silver DESC),'-',
          FIRST_VALUE(Silver)OVER(PARTITION BY games ORDER BY Silver DESC)) AS max_silver,
    CONCAT(FIRST_VALUE(region)OVER(PARTITION BY games ORDER BY Bronze DESC),'-',
          FIRST_VALUE(Bronze)OVER(PARTITION BY games ORDER BY Bronze DESC)) AS max_bronze
FROM
(SELECT
    games,
    region,
    COUNT(CASE WHEN medal != 'NA' THEN medal END) AS Total_medals,
    COUNT(CASE WHEN medal = 'Gold' THEN medal END) AS Gold,
    COUNT(CASE WHEN medal = 'Silver' THEN medal END) AS Silver,
    COUNT(CASE WHEN medal = 'Bronze' THEN medal END) AS Bronze
FROM athlete_events a
JOIN noc_regions n
ON a.noc = n.noc
GROUP BY games,region) as t
ORDER BY games;

-- 18. Which countries have never won gold medal but have won silver/bronze medals?
SELECT
    DISTINCT region,
    Gold,
    Silver,
    Bronze
FROM
(SELECT
    DISTINCT region,
    COUNT(CASE WHEN medal = 'Gold' THEN medal END) AS Gold,
    COUNT(CASE WHEN medal = 'Silver' THEN medal END) AS Silver,
    COUNT(CASE WHEN medal = 'Bronze' THEN medal END) AS Bronze
FROM athlete_events a
JOIN noc_regions n
ON a.noc = n.noc
GROUP BY region) AS t
WHERE Gold = 0 AND (Silver > 0 OR Bronze > 0)
ORDER BY Silver DESC, Bronze DESC;

-- 19. In which Sport/event, China has won highest medals.
SELECT
    sport,
    total_medals
FROM
(SELECT 
    sport,
    COUNT(medal) AS total_medals,
    DENSE_RANK()OVER(ORDER BY COUNT(medal) DESC) AS rk
FROM athlete_events a
JOIN noc_regions n
ON a.noc = n.noc
WHERE medal != 'NA' AND region = 'China'
GROUP BY sport) AS t
WHERE rk = 1;

-- 20. Break down all olympic games where China won medal for Gymnastics and how many medals in each olympic games
SELECT
    region,
    sport,
    games,
    COUNT(medal) AS total_medals
FROM athlete_events a
JOIN noc_regions n
ON a.noc = n.noc
WHERE medal != 'NA' AND region = 'China' AND sport = 'Gymnastics'
GROUP BY region,sport,games
ORDER BY total_medals DESC;



