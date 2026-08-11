CREATE DATABASE ipl_db;
USE ipl_db;

-- showing tables name with whole union all -- 

SELECT 'matches' AS table_name, COUNT(*) AS total_rows FROM matches
UNION ALL
SELECT 'deliveries', COUNT(*) FROM deliveries
UNION ALL
SELECT 'players', COUNT(*) FROM players
UNION ALL
SELECT 'teams', COUNT(*) FROM teams
UNION ALL
SELECT 'team_aliases', COUNT(*) FROM team_aliases;

--  IPL PROJECT  11 Business Questions — IPL Analytics --

-- Q1) Who are the top 10 run scorers of all time? --

select batter, sum(batter_runs) as totalruns
from deliveries
group by batter
order by totalruns DESC
limit 10;

--  Q2) If a team wins the toss, do their chances of winning the match increase?
--  In what percentage of matches has the team that won the toss also won the match?"

SELECT ROUND(SUM(CASE WHEN toss_winner = match_winner THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS toss_win_percent
FROM matches;

-- CASE WHEN toss_winner = match_winner THEN 1 ELSE 0 END — har match ke liye check: 
-- toss jeetne wali team hi jeeti match? Haan to 1, nahi to 0
-- SUM(...) — saare "haan" (1) wale cases jod diye
-- * 100.0 / COUNT(*) — percentage banaya (jeete hue / total matches)
-- ROUND(..., 2) — 2 decimal tak round kiya


-- Q3) Who scored the most runs in each season? (Season-wise top scorer) 

select season_id,batter ,runs from (
SELECT season_id, batter, SUM(batter_runs) AS runs,
    RANK() OVER (PARTITION BY season_id ORDER BY SUM(batter_runs) DESC) AS rnk
FROM deliveries
GROUP BY season_id, batter 
) t
where rnk = 1;

-- inner query and outer query --
-- 1) inner 
-- GROUP BY season_id, batter — har season ke andar, har batsman ka total runs nikal raha hai
-- (jaise 2023 mein Kohli ke total runs, 2023 mein Dhoni ke total runs, alag-alag)
-- RANK() OVER (PARTITION BY season_id ORDER BY SUM(batter_runs) DESC) — ye window function hai:
-- PARTITION BY season_id = har season ko alag-alag group mein rakho (2023 ka ranking alag, 2024 ka alag)
-- ORDER BY SUM(batter_runs) DESC = us season ke andar, sabse zyada runs wale ko rank 1 do
-- 2) outer 
-- Andar wali query ka result liya, aur usme se sirf wahi rows rakhi jinka rank 1 hai — matlab har season ka sirf top scorer.


-- imp part of this query
-- 3 lines mein poori query:

-- Pehle har season ke andar, har batsman ka total runs nikala aur unhe rank diya (sabse zyada runs wale ko rank 1)
-- Isse ek temporary table (t) bana diya jisme season, batter, runs, aur unka rank hai
-- Fir us table se sirf rank 1 wale rows nikale — matlab har season ka top scorer



-- Q4) How does each player's performance compare to their previous season? (Season-over-season improvement)

SELECT batter, season_id, SUM(batter_runs) AS runs,
    LAG(SUM(batter_runs)) OVER (PARTITION BY batter ORDER BY season_id) AS last_season_runs
FROM deliveries
GROUP BY batter, season_id; 

--  lines mein samajh
-- Har batsman ka har season mein total runs nikala (GROUP BY batter, season_id)
-- LAG() function se, har batsman ke liye pichle season ka runs bhi ek nayi column mein le aaye (last_season_runs)
-- Ab tu ek hi row mein dekh sakta hai — is season ke runs aur pichle season ke runs — compare karne ke liye



-- Q5) Which team scores the most runs in death overs (16-20)

SELECT t.team_name, SUM(d.total_runs) AS runs
FROM deliveries d
JOIN teams t ON d.team_batting = t.team_id
WHERE d.over_number BETWEEN 16 AND 20
GROUP BY t.team_name
ORDER BY runs DESC;



-- Q6) Which bowler gives away the fewest runs in the first 6 overs (powerplay)?

SELECT bowler, SUM(total_runs) AS runs_given, COUNT(DISTINCT match_id) AS matches
FROM deliveries
WHERE over_number BETWEEN 1 AND 6
GROUP BY bowler
HAVING matches >=5
ORDER BY runs_given ASC
LIMIT 10;

-- WHERE over_number BETWEEN 1 AND 6 — sirf powerplay overs ki balls filter kar rahe hain
-- GROUP BY bowler — har bowler ke hisaab se group kar rahe hain
-- SUM(total_runs) — us bowler ne powerplay mein total kitne runs diye
-- COUNT(DISTINCT match_id) — us bowler ne kitne alag matches khele (isse pata chalega experience/sample size)
-- HAVING matches >= 5 — sirf wahi bowlers rakho jinhone kam se kam 5 matches khele ho (warna ek match wale bowler bhi "best" dikh sakte hain agar unhone accidentally 1 hi over kiya ho, jo galat comparison hoga)
-- ORDER BY runs_given ASC — sabse kam runs dene wale upar (kyunki "fewest runs" = best economy)
-- LIMIT 10 — top 10 dikhao


-- Q7 — What percentage of matches does each team win when playing at home?
select t.team_name,
	round(sum( case when m.match_winner = m.team1 then 1 else 0 end)* 100.0 / count(*), 2) as home_win_pct
from matches m
join teams t on m.team1 = t.team_id
group by t.team_name
order by home_win_pct DESC;

--  What percentage of matches does each team win when playing at home?

-- CASE — condition check karna shuru kar rahe hain
-- WHEN matches.match_winner = matches.team1 — check kar: kya match jeetne wali team team1 (home team) hi thi?
-- THEN 1 — agar haan (condition true hai), to 1 de do
-- ELSE 0 — agar nahi (condition false hai), to 0 de do
-- END — condition check khatam


--  Q8) — Who are the top 1 run scorer in each season? (Orange Cap race)


SELECT season_id, batter, runs FROM (
    SELECT season_id, batter, SUM(batter_runs) AS runs,
        RANK() OVER (PARTITION BY season_id ORDER BY SUM(batter_runs) DESC) AS rnk
    FROM deliveries
    GROUP BY season_id, batter
) t
WHERE rnk = 1
ORDER BY season_id;


-- Q9) "Do teams prefer to bat first or field first after winning the toss?"

select toss_decision, count(*) as total
from matches
group by toss_decision;

-- with percentage --

SELECT toss_decision, round(COUNT(*) * 100 / (select count(*) from matches), 2) as percentage 
FROM matches
GROUP BY toss_decision;

-- Q10) Who scored the most runs in each individual match

SELECT match_id, batter, runs FROM (
    SELECT match_id, batter, SUM(batter_runs) AS runs,
        ROW_NUMBER() OVER (PARTITION BY match_id ORDER BY SUM(batter_runs) DESC) AS rnk
    FROM deliveries
    GROUP BY match_id, batter
) t
WHERE rnk = 1
LIMIT 20;

-- Q11. Who are the top 10 bowlers by total wickets taken? (Purple Cap-style ranking)

SELECT bowler, COUNT(*) AS total_wickets
FROM deliveries
WHERE is_wicket = 1
GROUP BY bowler
ORDER BY total_wickets DESC
LIMIT 10;































