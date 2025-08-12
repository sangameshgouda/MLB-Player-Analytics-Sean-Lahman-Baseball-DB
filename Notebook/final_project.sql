-- PART I: SCHOOL ANALYSIS
-- 1. View the schools and school details tables
select * from schools;
select * from school_details;
select * from players;
-- 2. In each decade, how many schools were there that produced players?
with years as (select round(yearID,-1) as new_year,count( DISTINCT schoolID) as count_of_schools
				from schools
				group by 1
				order by new_year asc)
select * from years;

-- 3. What are the names of the top 5 schools that produced the most players?
with school_details as (select s.playerID,s.schoolID,sd.name_full as school_name
						from schools as s
						left join school_details as sd
						on s.schoolID = sd.schoolID
                        )
select school_name,count(distinct playerID) as count_of_players
from school_details
group by school_name
order by count_of_players desc
limit 5;



-- 4. For each decade, what were the names of the top 3 schools that produced the most players?
with years as (select round(yearID,-1) as new_year,
				s.schoolID as s_id,
                sd.name_full,
				s.playerID 
				from schools as s
                left join school_details as sd
                on s.schoolID = sd.schoolID
				order by yearID asc),
player_cnt as (select new_year,name_full,count(distinct playerID) total_players 
				from years
				group by 1,2
                ),
college_wise as(select new_year,name_full,sum(total_players)over(PARTITION BY new_year,name_full )as total_cnt
					from player_cnt
					order by new_year),
                    
rank_wise as(select new_year,name_full,total_cnt,dense_rank()over(PARTITION BY new_year order by total_cnt desc) as rnk
from college_wise
order by new_year)

select * 
from rank_wise 
where rnk<=3;


-- PART II: SALARY ANALYSIS
-- 1. View the salaries table
select * 
from salaries;
select count(distinct teamID) from salaries;
-- 2. Return the top 20% of teams in terms of average annual spending
with avg_spending as (select teamID,yearID,
							sum(salary) as total_spending
						from salaries
						group by 1,2),
rank_wise as (select teamID,
		avg(total_spending)as avg_spend,
        ntile(5)over(order by avg(total_spending) desc) as rnk
from avg_spending
group by 1)
select * 
from rank_wise
where rnk=1;

-- 3. For each team, show the cumulative sum of spending over the years
with team_year as(select teamID,yearID,sum(salary) as total_spending
					from salaries
					group by 1,2
					order by 1,2)
select teamID,yearID,total_spending,sum(total_spending)over(order by teamID,yearID) as cum_sum
from team_year;

-- 4. Return the first year that each team's cumulative spending surpassed 1 billion
with team_year as(select teamID,yearID,sum(salary) as total_spending
					from salaries
					group by 1,2
					order by 1,2),
sum_sum as      (select teamID,yearID,total_spending,
				sum(total_spending)over(order by teamID,yearID) as cum_sum
				from team_year),
rnk_wise as (select teamID,yearID,row_number()over(partition by teamID order by yearID) as rn
from sum_sum
where cum_sum>=1000000000)

select * from rnk_wise
where rn=1;


-- PART III: PLAYER CAREER ANALYSIS
-- 1. View the players table and find the number of players in the table
select *
from players;
-- 2. For each player, calculate their age at their first game, their last game, and their career length (all in years). Sort from longest career to shortest career.
with playerdetails as (select playerID,nameGiven,
						cast(concat(birthYear,"-",birthMonth,"-",birthDay) as DATE) as date_birth,
                        debut,finalGame
                       from players ),
carrer as (select playerID,nameGiven,
		TIMESTAMPDIFF(year,date_birth,debut) as first_game_age,
        TIMESTAMPDIFF(year,date_birth,finalGame) as final_game_age
from playerdetails)

select playerID,nameGiven,
		first_game_age,
        final_game_age,
        (final_game_age-first_game_age) as len_carrer
from carrer
order by len_carrer desc;

-- 3. What team did each player play on for their starting and ending years?

select * from players;
select * from salaries;

with player_team as (select p.playerID,p.nameGiven,
						p.debut as starting_year,p.finalGame as ending_year,s.yearID as start_year_id,
						s.teamID as starting_team,e.yearID as end_year_id,e.teamID as ending_team
			         from 			players as p
							inner JOIN salaries as s
							on p.playerID = s.playerID
							and year(p.debut) = s.yearId 
							inner join salaries as e
							on p.playerID=e.playerID and year(p.finalGame)=e.yearID)
                            
select playerID,nameGiven,starting_year,starting_team,ending_year,ending_team
from player_team;

-- 4. How many players started and ended on the same team and also played for over a decade?
with player_team as (select p.playerID,p.nameGiven,
						p.debut as starting_year,p.finalGame as ending_year,s.yearID as start_year_id,
						s.teamID as starting_team,e.yearID as end_year_id,e.teamID as ending_team
			         from 			players as p
							inner JOIN salaries as s
							on p.playerID = s.playerID
							and year(p.debut) = s.yearId 
							inner join salaries as e
							on p.playerID=e.playerID and year(p.finalGame)=e.yearID),
                            
year_cal as (select playerID,nameGiven,starting_year,starting_team,ending_year,ending_team,
					TIMESTAMPDIFF(year,starting_year,ending_year)as total_year_played
				from player_team
				where starting_team=ending_team)
SELECT playerID,nameGiven,total_year_played 
FROM year_cal 
where total_year_played>=10
order by total_year_played desc;


-- PART IV: PLAYER COMPARISON ANALYSIS
-- 1. View the players table
select * from players;
-- 2. Which players have the same birthday?
with player_details as (select playerID,nameGiven,
						cast(concat(birthYear,"-",birthMonth,"-",birthDay) as DATE) as date_birth
						from players)
select p1.nameGiven,p1.date_birth,p2.nameGiven,p2.date_birth
from player_details as  p1
join player_details as p2
on p1.date_birth = p2.date_birth and p1.nameGiven<>p2.nameGiven
where p1.nameGiven<p2.nameGiven;

-- another option

with player_details as (select playerID,nameGiven,
						cast(concat(birthYear,"-",birthMonth,"-",birthDay) as DATE) as date_birth
						from players)
select date_birth,GROUP_CONCAT(nameGiven SEPARATOR ", ") as total_people,count(nameGiven) as cnt
FROM player_details
where date_birth is not null and year(date_birth) between 1980 and 1990
group by 1
having cnt>1
order by 1;

-- 3. Create a summary table that shows for each team, what percent of players bat right, left and both
select * from players;
select * from salaries;
WITH team_details as (select s.teamid,p.playerID,p.bats
						from salaries as s
						join players as p
						on s.playerID = p.playerID)
select teamID,
     round( sum( case when bats="R" then 1 else 0  end)/count(playerID)*100 ,1)as righty,
       round(sum(case when bats="L" then 1 else 0 end)/count(playerID)*100,1)as lefty,
      round( sum(case when bats ="B" THEN 1 ELSE 0 END)/count(playerID)*100,1) AS both_b_l
from team_details 
group by 1;
-- 4. How have average height and weight at debut game changed over the years, and what's the decade-over-decade difference?
select * from players;
with decade_wise as(select round(year(debut),-1) AS decade,avg(weight) as avg_weight,avg(height) as avg_height
					from players
					group by 1
					order by 1),
over_cal as (select decade,avg_weight,
					lag(avg_weight)over(order by decade) as next_decade_weight,
					avg_height,
					lag(avg_height)over(order by decade) as next_decade_height
					from decade_wise)
                    
select decade,(avg_weight-next_decade_weight) as weight_diff,
		(avg_height-next_decade_height) as height_diff
from over_cal
where decade is not null;
