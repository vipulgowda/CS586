CREATE SCHEMA IF NOT EXISTS "graduate_project_ipl";

CREATE TABLE graduate_project_ipl.ipl_data (
id INTEGER,
inning INTEGER,
over INTEGER,
ball INTEGER,
batsman VARCHAR(50),
non_striker VARCHAR(50),
bowler VARCHAR(50),
batsman_runs INTEGER,
extra_runs INTEGER,
total_runs INTEGER,
non_boundary INTEGER,
is_wicket INTEGER,
dismissal_kind VARCHAR(50),
player_dismissed VARCHAR(50),
fielder VARCHAR(50),
extras_type VARCHAR(20),
batting_team VARCHAR(50),
bowling_team VARCHAR(50)
);


CREATE TABLE graduate_project_ipl.ipl_venue (
id INTEGER,
city VARCHAR(30),
date DATE,
player_of_match VARCHAR(40),
venue VARCHAR(80),
neutral_venue VARCHAR(80),
team1 VARCHAR(50),
team2 VARCHAR(50),
toss_winner VARCHAR(50),
toss_decision VARCHAR(20),
winner VARCHAR(50),
result VARCHAR(20),
result_margin VARCHAR(20),
eliminator VARCHAR(20),
method VARCHAR(20),
umpire1 VARCHAR(30),
umpire2 VARCHAR(30)
);

\copy graduate_project_ipl.ipl_data FROM 'IPL_ball.csv' WITH (FORMAT csv, header);

\copy graduate_project_ipl.ipl_venue FROM 'IPL_Matches.csv' WITH (FORMAT csv, header);

---
-- Extras Table
---
CREATE TABLE graduate_project_ipl.extras
(
	id SERIAL PRIMARY KEY,
	type VARCHAR(20) UNIQUE NOT NULL
);

insert into graduate_project_ipl.extras (type) select distinct extras_type from graduate_project_ipl.ipl_data;
DELETE FROM graduate_project_ipl.extras where type='NA';

---
-- Umpires Table
---

CREATE TABLE graduate_project_ipl.umpires
(
	id SERIAL PRIMARY KEY,
	name VARCHAR(50) UNIQUE NOT NULL
);

insert into graduate_project_ipl.umpires (name) SELECT umpire1 from graduate_project_ipl.ipl_venue
UNION
SELECT umpire2 from graduate_project_ipl.ipl_venue;

---
-- Dismissal Table
---
CREATE TABLE graduate_project_ipl.dismissal 
(
	id SERIAL PRIMARY KEY,
	type VARCHAR(50) UNIQUE NOT NULL
);

insert into graduate_project_ipl.dismissal (type) SELECT distinct dismissal_kind from graduate_project_ipl.ipl_data;
DELETE FROM graduate_project_ipl.dismissal where type='NA';


---
-- Players Table
---

CREATE TABLE graduate_project_ipl.players
(
	id SERIAL PRIMARY KEY,
	name VARCHAR(50) UNIQUE NOT NULL
);

insert into graduate_project_ipl.players (name) SELECT distinct batsman from graduate_project_ipl.ipl_data
UNION
SELECT distinct non_striker from graduate_project_ipl.ipl_data
UNION
SELECT distinct bowler from graduate_project_ipl.ipl_data;

---
-- Venues Table
---

CREATE TABLE graduate_project_ipl.venues 
(
	id SERIAL PRIMARY KEY,
	city VARCHAR(50) NOT NULL,
	venue VARCHAR(80) UNIQUE NOT NULL
);

INSERT INTO graduate_project_ipl.venues (city,venue) SELECT distinct city, venue from graduate_project_ipl.ipl_venue order by city;

---
-- Team Table
---

CREATE TABLE graduate_project_ipl.team
(
	id SERIAL PRIMARY KEY,
	name VARCHAR(50) UNIQUE NOT NULL
);

INSERT INTO graduate_project_ipl.team (name) 
SELECT team1 from graduate_project_ipl.ipl_venue UNION SELECT team2 from graduate_project_ipl.ipl_venue;

---
-- Dummy Table to join team and players
---

CREATE TABLE graduate_project_ipl.players_team_dump
(
	player_id VARCHAR(50),
	team_id VARCHAR(50)
)

INSERT into graduate_project_ipl.players_team_dump
Select p1.batsman as player_id, p1.batting_team as team_id from graduate_project_ipl.ipl_data p1
UNION 
Select p2.bowler as player_id, p2.bowling_team as team_id from graduate_project_ipl.ipl_data p2
UNION
Select p3.non_striker as player_id, p3.batting_team as team_id from graduate_project_ipl.ipl_data p3
order by team_id, player_id;

---
-- Player-Team Join Table
---

CREATE TABLE graduate_project_ipl.players_team
(
	player_id INTEGER REFERENCES graduate_project_ipl.players(id) ,
	team_id INTEGER REFERENCES graduate_project_ipl.team(id),
  PRIMARY KEY (player_id, team_id)
);

INSERT INTO graduate_project_ipl.players_team
SELECT 
(SELECT id from graduate_project_ipl.players p where p.name=pt.player_id) as player_id,
(SELECT id from graduate_project_ipl.team t where t.name=pt.team_id) as team_id
from graduate_project_ipl.players_team_dump pt;

DROP TABLE graduate_project_ipl.players_team_dump;

---
-- Matches Table
---

CREATE TABLE graduate_project_ipl.matches
(
	id SERIAL PRIMARY KEY,
	match_id INTEGER,
	date DATE NOT NULL,
	venue_id INTEGER,
	toss_decision VARCHAR(20) NOT NULL,
	toss_winning_team_id INTEGER,
	result VARCHAR(50),
	result_margin VARCHAR(50),
	method VARCHAR(20) DEFAULT NULL,
  winning_team_id INTEGER,
  player_of_match_id INTEGER,
  team1_id INTEGER,
  team2_id INTEGER,
  umpire1_id INTEGER,
  umpire2_id INTEGER,
  FOREIGN KEY(venue_id) REFERENCES graduate_project_ipl.venues(id),
  FOREIGN KEY(toss_winning_team_id) REFERENCES graduate_project_ipl.team(id),
	FOREIGN KEY(winning_team_id)  REFERENCES graduate_project_ipl.team(id) ON DELETE CASCADE ON UPDATE CASCADE,
	FOREIGN KEY(player_of_match_id)  REFERENCES graduate_project_ipl.players(id) ON DELETE CASCADE ON UPDATE CASCADE,
	FOREIGN KEY(team1_id)  REFERENCES graduate_project_ipl.team(id) ON DELETE CASCADE ON UPDATE CASCADE,
	FOREIGN KEY(team2_id)  REFERENCES graduate_project_ipl.team(id) ON DELETE CASCADE ON UPDATE CASCADE,
	FOREIGN KEY(umpire1_id)  REFERENCES graduate_project_ipl.umpires(id) ON DELETE CASCADE ON UPDATE CASCADE,
	FOREIGN KEY(umpire2_id)  REFERENCES graduate_project_ipl.umpires(id) ON DELETE CASCADE ON UPDATE CASCADE
);

INSERT INTO graduate_project_ipl.matches (
	match_id ,
	date,
	venue_id ,
	toss_decision ,
	toss_winning_team_id ,
	result ,
	result_margin ,
	method ,
	winning_team_id ,
	player_of_match_id ,
	team1_id ,
	team2_id ,
	umpire1_id ,
	umpire2_id 
)
SELECT 
iv.id as match_id,
iv.date,
v.id as venue_id,
iv.toss_decision as toss_decision,
(SELECT id from graduate_project_ipl.team where team.name = iv.toss_winner) as toss_winning_team_id,
iv.result as result,
iv.result_margin as result_margin,
iv.method as method,
(SELECT id from graduate_project_ipl.team where team.name = iv.winner) as winning_team_id,
(SELECT id from graduate_project_ipl.players where name = iv.player_of_match) as player_of_match_id,
(SELECT id from graduate_project_ipl.team where team.name = iv.team1) as team1_id,
(SELECT id from graduate_project_ipl.team where team.name = iv.team2) as team2_id,
(SELECT id from graduate_project_ipl.umpires where name = iv.umpire1) as umpire1_id,
(SELECT id from graduate_project_ipl.umpires where name = iv.umpire2) as umpire2_id
from graduate_project_ipl.ipl_venue iv
join graduate_project_ipl.venues v on v.venue = iv.venue and v.city  = iv.city
order by match_id;

---
-- Balls Table
---


CREATE TABLE graduate_project_ipl.balls
(
	id SERIAL PRIMARY KEY,
	match_id INTEGER UNIQUE NOT NULL,
	over INTEGER,
	ball INTEGER,
	batsman_id INTEGER,
	batting_team_id INTEGER,
	non_striker_id INTEGER,
	batsman_runs INTEGER,
	extra_runs INTEGER,
	total_runs INTEGER,
	extra_id INTEGER,
	is_wicket INTEGER,
	dismissal_id INTEGER ,
	player_dismissed_id INTEGER,
	fielder_id INTEGER,
	bowler_id INTEGER,
	bowling_team_id INTEGER,
	FOREIGN KEY(match_id) REFERENCES graduate_project_ipl.matches(id) ON DELETE CASCADE ON UPDATE CASCADE,
	FOREIGN KEY(batting_team_id) REFERENCES graduate_project_ipl.team(id) ON DELETE CASCADE ON UPDATE CASCADE,
	FOREIGN KEY(bowling_team_id) REFERENCES graduate_project_ipl.team(id) ON DELETE CASCADE ON UPDATE CASCADE,
	FOREIGN KEY(extra_id) REFERENCES graduate_project_ipl.extras(id) ON DELETE CASCADE ON UPDATE CASCADE,
	FOREIGN KEY(dismissal_id) REFERENCES graduate_project_ipl.dismissal(id) ON DELETE CASCADE ON UPDATE CASCADE,
	FOREIGN KEY(batsman_id) REFERENCES graduate_project_ipl.players(id) ON DELETE CASCADE ON UPDATE CASCADE,
	FOREIGN KEY(non_striker_id) REFERENCES graduate_project_ipl.players(id) ON DELETE CASCADE ON UPDATE CASCADE,
	FOREIGN KEY(fielder_id) REFERENCES graduate_project_ipl.players(id) ON DELETE CASCADE ON UPDATE CASCADE,
	FOREIGN KEY(bowler_id) REFERENCES graduate_project_ipl.players(id) ON DELETE CASCADE ON UPDATE CASCADE,
	FOREIGN KEY(player_dismissed_id) REFERENCES graduate_project_ipl.players(id) ON DELETE CASCADE ON UPDATE CASCADE
);

--drop this constraint.
ALTER TABLE graduate_project_ipl.balls DROP CONSTRAINT balls_match_id_key;

INSERT INTO graduate_project_ipl.balls (
  match_id,
	over,
	ball,
	batsman_id,
	non_striker_id,
	batsman_runs,
	extra_runs ,
	total_runs ,
	extra_id,
	is_wicket ,
	dismissal_id,
	player_dismissed_id,
	fielder_id,
	bowler_id,
	batting_team_id ,
	bowling_team_id
)
SELECT
  id as match_id,
  over as over,
  ball as ball,
  (SELECT id from graduate_project_ipl.players where players.name = ipl_data.batsman) as batsman_id,
  (SELECT id from graduate_project_ipl.players where players.name = ipl_data.non_striker) as  non_striker_id,
  batsman_runs,
  extra_runs,
  total_runs,
  (SELECT id from graduate_project_ipl.extras where extras.type = ipl_data.extras_type) as extra_id,
  is_wicket,
  (SELECT id from graduate_project_ipl.dismissal where dismissal.type = ipl_data.dismissal_kind) as  dismissal_id,
  (SELECT id from graduate_project_ipl.players where players.name = ipl_data.player_dismissed) as player_dismissed_id,
  (SELECT id from graduate_project_ipl.players where players.name = ipl_data.fielder)  as fielder_id,
  (SELECT id from graduate_project_ipl.players where players.name = ipl_data.bowler) as bowler_id,
  (SELECT id from graduate_project_ipl.team where team.name = ipl_data.batting_team) as batting_team_id,      
  (SELECT id from graduate_project_ipl.team where team.name = ipl_data.bowling_team) as bowling_team
from
  graduate_project_ipl.ipl_data 
order by match_id,batting_team, over, ball;

-- Update the match_id
UPDATE graduate_project_ipl.balls b set match_id = (SELECT matches.id from graduate_project_ipl.matches where matches.match_id = b.match_id);

-- Add constraint back
ALTER TABLE graduate_project_ipl.balls
ADD CONSTRAINT balls_match_id_key
FOREIGN KEY (match_id) REFERENCES graduate_project_ipl.matches(id) ON DELETE CASCADE ON UPDATE CASCADE;

--Drop the match_id
ALTER TABLE graduate_project_ipl.matches
DROP COLUMN match_id;

UPDATE graduate_project_ipl.matches
SET method = null
where method = 'NA';

UPDATE graduate_project_ipl.matches set venue_id=1 where id=5;

-- CREATE A VIEW TO SEE THE IPL POINTS TABLE
CREATE VIEW graduate_project_ipl.ipl_points_table as
SELECT t.id, t.name, count(*) as matches_won, 
(SELECT count(*) from graduate_project_ipl.matches m join graduate_project_ipl.team te on te.id IN (m.team1_id,m.team2_id) 
where te.id = t.id
group by t.id) as matches_played  
from graduate_project_ipl.matches m 
join graduate_project_ipl.team t on t.id = m.winning_team_id 
group by t.id 
order by matches_won desc;

-------------------------------------------------------------
---
---          INDEXES
---
-------------------------------------------------------------
CREATE INDEX balls_idx_id on graduate_project_ipl.balls(id);
CREATE INDEX venues_idx_id on graduate_project_ipl.venues(id);
CREATE INDEX players_idx_id on graduate_project_ipl.players(id);
CREATE INDEX players_team_idx_id on graduate_project_ipl.players_team(player_id, team_id);
CREATE INDEX dismissal_idx_id on graduate_project_ipl.dismissal(id);
CREATE INDEX team_idx_id on graduate_project_ipl.team(id);
CREATE INDEX match_idx_id on graduate_project_ipl(id);
CREATE INDEX extra_idx_id on graduate_project_ipl(id);


--------------------------------------------------------------
----
----         QUERYING TABLES
----
---------------------------------------------------------------
--1.Query to find the top 5 teams that won in their home ground along with matches played in their home ground. 

select
	v.city,
	v.venue,
	(
	select
		name
	from
		graduate_project_ipl.team
	where
		id = m.team1_id) as home_team,
	count(*) as matches_played,
	count(case when winning_team_id = m.team1_id then 1 end)as matches_won
from
	graduate_project_ipl.matches m
join graduate_project_ipl.venues v on
	m.venue_id = v.id
group by
	v.city,
	v.venue,
	home_team
having
	count(*) > 1
order by
	matches_won desc
limit 5;
--2.Query to find the teams that won both the toss and the match. 

select
	m.date,
	v.city,
	t.name
from
	graduate_project_ipl.matches m
join graduate_project_ipl.team t 
on
	t.id = m.toss_winning_team_id
	and t.id = m.winning_team_id
join graduate_project_ipl.venues v on
	v.id = m.venue_id;
--3.Query to find all the players who a particular team's bowlers dismissed. - Imran Tahir

select
	p.name as player
from
	graduate_project_ipl.balls b
join graduate_project_ipl.players p on
	b.player_dismissed_id = p.id
	and b.dismissal_id in (2, 4, 5, 6, 8, 9)
where
	b.bowler_id = (
	select
		id
	from
		graduate_project_ipl.players
	where
		name = 'Imran Tahir');
--4.Query to find all the highest score runs for the season. 

select
	p.name as player,
	sum(batsman_runs)
from
	graduate_project_ipl.balls b
join graduate_project_ipl.players p on
	b.batsman_id = p.id
group by
	player
order by
	sum(batsman_runs) desc
limit 5;
--5.Query to find all the highest wickets for the season. 

select
	p.name as player,
	count(*) as wickets_taken
from
	graduate_project_ipl.balls b
join graduate_project_ipl.players p on
	b.bowler_id = p.id
	and b.dismissal_id in (2, 4, 5, 6, 8, 9)
group by
	player
order by
	count(*) desc
limit 5;
--6.List the players who bowled more than 2 overs in a match and had an economy rate (runs per over) of less than 6.

select
	matches_played,
	bowler_name,
	team_name,
	overs,
	(runs / overs) :: real as economy,
	case
		when wickets != 0 then (runs / wickets) :: real
		else 0
	end as average_rate
from
	(
	select
		bowler_name,
		team_name,
		count(*) as matches_played,
		sum(overs) as overs,
		sum(bowls) as bowls,
		sum(runs) as runs,
		sum(wickets) as wickets
	from
		(
		select
			match_id,
			bowler_name,
			team_name,
			sum(overs_bowled) as overs,
			sum(balls_bowled) as bowls,
			sum(runs) as runs,
			sum(wickets) as wickets
		from
			(
			select
				match_id,
				bowler_name,
				team_name,
				count(*) as overs_bowled,
				sum(balls_bowled) as balls_bowled,
				sum(runs) as runs,
				sum(wickets) as wickets
			from
				(
				select
					b.match_id,
					p.name as bowler_name,
					t.name as team_name,
					b.over as over_number,
					count(*) as balls_bowled,
					sum(b.total_runs) as runs,
					sum(b.is_wicket) as wickets
				from
					graduate_project_ipl.balls b
				join graduate_project_ipl.players p on
					b.bowler_id = p.id
				join graduate_project_ipl.team t on
					b.bowling_team_id = t.id
				group by
					b.match_id,
					p.name,
					t.name,
					b.over
				order by
					b.match_id
              ) as named_table1
			group by
				match_id,
				bowler_name,
				team_name,
				wickets
			order by
				team_name,
				bowler_name
          ) as named_table2
		group by
			match_id,
			bowler_name,
			team_name
      ) as named_table3
	group by
		bowler_name,
		team_name
  ) as named_table3
where
	overs > 2
	and (runs / overs) < 6
order by
	economy;
--7. Find the top 5 matches with the highest win margin in runs. 

 select
	t1.name as team1,
	t2.name as team2,
	t3.name as winning_team,
	m.result_margin
from
	graduate_project_ipl.matches m
join graduate_project_ipl.team t1 on
	t1.id = m.team1_id
join graduate_project_ipl.team t2 on
	t2.id = m.team2_id
join graduate_project_ipl.team t3 on
	t3.id = m.winning_team_id
where
	m.result = 'runs'
order by
	m.result_margin::INTEGER desc
limit 5;
--8. Find all the players who played for different teams. 

select
	player_id,
	team_id,
	count(*) as teams_played
from
	graduate_project_ipl.players_team
group by
	player_id,
	team_id
having
	count(*) > 1;
--No Player played for two teams in a season.
--9. Write a query where man of the match was awarded to losing team player. 

select
	p.name as player_name,
	t1.name as team1,
	t2.name as team2,
	t3.name as winning_team
from
	graduate_project_ipl.matches m
join graduate_project_ipl.team t1 on
	t1.id = m.team1_id
join graduate_project_ipl.team t2 on
	t2.id = m.team2_id
join graduate_project_ipl.team t3 on
	t3.id = m.winning_team_id
join graduate_project_ipl.players p on
	p.id = m.player_of_match_id
join graduate_project_ipl.players_team pt on
	pt.player_id = m.player_of_match_id
	and pt.team_id != m.winning_team_id;
-- No opposition player got player_of_match award; 
--10. Query to find the top 5 players to hit the most sixes 

 select
	p.name,
	count(batsman_runs) as sixes
from
	graduate_project_ipl.balls b
join graduate_project_ipl.players p on
	p.id = b.batsman_id
where
	batsman_runs = 6
group by
	p.name
order by
	sixes desc
limit 5;
--11. Query to find all the teams that gave extra runs for this season. 

select
	t.name,
	sum(extra_runs) as extras_given
from
	graduate_project_ipl.balls b
join graduate_project_ipl.extras e on
	e.id = b.extra_id
join graduate_project_ipl.team t on
	t.id = b.bowling_team_id
group by
	t.name
order by
	extras_given desc;
--12. Query all the matches that were played under the D/L method. 

select
	*
from
	graduate_project_ipl.matches
where
	method = 'D/L';
--13. Query to find the players and their dismissal kind.

select
	p.name,
	d.type,
	COUNT(d.id) as total_dismissals
from
	graduate_project_ipl.balls b
join
  graduate_project_ipl.dismissal d on
	b.dismissal_id = d.id
join 
  graduate_project_ipl.players p on
	p.id = b.batsman_id
where
	type is not null
group by
	p.name,
	d.type
order by
	total_dismissals desc,
	d.type;
--14. Query to show statistics of two teams against head-on-head being played.

select
	total_matches,
	t1.name as team1,
	t2.name as team2,
	team1_wins,
	team2_wins,
	draws
from
	(
	select
		least(team1_id,
		team2_id) as team1,
		greatest(team1_id,
		team2_id) as team2,
		COUNT(*) as total_matches,
		SUM(case when winning_team_id = least(team1_id, team2_id) then 1 else 0 end) as team1_wins,
		SUM(case when winning_team_id = greatest(team1_id, team2_id) then 1 else 0 end) as team2_wins,
		SUM(case when method = 'D/L' then 1 else 0 end) as draws
	from
		graduate_project_ipl.matches
	group by
		least(team1_id,
		team2_id),
		greatest(team1_id,
		team2_id)
	order by
		total_matches desc) as m
join graduate_project_ipl.team t1
on
	m.team1 = t1.id
join graduate_project_ipl.team t2
on
	m.team2 = t2.id
order by
	total_matches desc;
--15. Query to find the teams losing on which venues for that particular season. 

select
	t.name,
	v.venue
from
	graduate_project_ipl.matches m
join graduate_project_ipl.venues v on
	v.id = m.venue_id
join graduate_project_ipl.team t on
	t.id =(case
		when m.winning_team_id = m.team1_id then m.team2_id
		else m.team1_id
	end);
--16. Query to list the total number of runs scored by a team in a season

select
	t.name,
	sum(b.total_runs)
from
	graduate_project_ipl.balls b
join graduate_project_ipl.team t on
	t.id = b.batting_team_id
group by
	t.name;
--17. Query to list the total number of wickets taken in a season. 

select
	t.name,
	sum(b.is_wicket) as wickets
from
	graduate_project_ipl.balls b
join graduate_project_ipl.team t on
	t.id = b.bowling_team_id
group by
	t.name;
--18. List the bowler who took the most wickets in a single venue 

select
	p.name,
	sum(b.is_wicket) as wickets_taken,
	v.venue
from
	graduate_project_ipl.balls b
join graduate_project_ipl.matches m on
	b.match_id = m.id
join graduate_project_ipl.players p on
	p.id = b.bowler_id
join graduate_project_ipl.venues v on
	v.id = m.venue_id
group by
	p.name,
	v.venue
order by
	wickets_taken desc
limit 5;

--19. Create a view of the batsman statistics match. 
drop view if exists graduate_project_ipl.batting_stats ;

create view graduate_project_ipl.batting_stats as
select
	match_id,
	batsman_name,
	team_name,
	runs,
	bowls_played,
	(runs :: real / bowls_played :: real) * 100 as strike_rate
from
	(
	select
		b.match_id,
		p.name as batsman_name,
		t.name as team_name,
		sum(b.batsman_runs) as runs,
		count(b.ball) as bowls_played
	from
		graduate_project_ipl.balls b
	join graduate_project_ipl.players p on
		b.batsman_id = p.id
	join graduate_project_ipl.team t on
		b.batting_team_id = t.id
	where
		b.extra_runs = 0
	group by
		b.match_id,
		p.name,
		t.name
  ) as named_query1
where
	(runs / bowls_played) > 0
order by
	strike_rate desc;

select
	*
from
	graduate_project_ipl.batting_stats;

--20. Create a view of bowler statistics for that particular match. 
drop view if exists graduate_project_ipl.bowler_stats;

create view graduate_project_ipl.bowler_stats as
select
	matches_played,
	bowler_name,
	team_name,
	overs,
	runs,
	wickets as wickets_taken,
	(runs / overs) :: real as economy,
	case
		when wickets != 0 then (runs / wickets) :: real
		else 0
	end as average_rate
from
	(
	select
		bowler_name,
		team_name,
		count(*) as matches_played,
		sum(overs) as overs,
		sum(bowls) as bowls,
		sum(runs) as runs,
		sum(wickets) as wickets
	from
		(
		select
			match_id,
			bowler_name,
			team_name,
			sum(overs_bowled) as overs,
			sum(balls_bowled) as bowls,
			sum(runs) as runs,
			sum(wickets) as wickets
		from
			(
			select
				match_id,
				bowler_name,
				team_name,
				count(*) as overs_bowled,
				sum(balls_bowled) as balls_bowled,
				sum(runs) as runs,
				sum(wickets) as wickets
			from
				(
				select
					b.match_id,
					p.name as bowler_name,
					t.name as team_name,
					b.over as over_number,
					count(*) as balls_bowled,
					sum(b.total_runs) as runs,
					sum(b.is_wicket) as wickets
				from
					graduate_project_ipl.balls b
				join graduate_project_ipl.players p on
					b.bowler_id = p.id
				join graduate_project_ipl.team t on
					b.bowling_team_id = t.id
				group by
					b.match_id,
					p.name,
					t.name,
					b.over
				order by
					b.match_id
              ) as query1
			group by
				match_id,
				bowler_name,
				team_name,
				wickets
			order by
				team_name,
				bowler_name
          ) as query2
		group by
			match_id,
			bowler_name,
			team_name
      ) as query3
	group by
		bowler_name,
		team_name
  ) as query4
order by
	team_name,
	bowler_name;

select
	*
from
	graduate_project_ipl.bowler_stats;
