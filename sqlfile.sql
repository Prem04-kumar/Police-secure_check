# What are the top 10 vehicle_Number involved in drug-related stops?

select * from securecheck.police_logs;
SELECT vehicle_number, COUNT(*) AS stop_count
FROM police_logs
WHERE drugs_related_stop = 'Yes'
GROUP BY vehicle_number
ORDER BY stop_count DESC
LIMIT 10;


# Which vehicles were most frequently searched?

SELECT vehicle_number, COUNT(*) AS search_count
FROM police_logs
WHERE search_conducted = 'Yes'
GROUP BY vehicle_number
ORDER BY search_count DESC

# Which driver age group had the highest arrest rate?

SELECT 
  CASE
    WHEN driver_age BETWEEN 18 AND 25 THEN '18-25'
    WHEN driver_age BETWEEN 26 AND 35 THEN '26-35'
    WHEN driver_age BETWEEN 36 AND 45 THEN '36-45'
    WHEN driver_age BETWEEN 46 AND 60 THEN '46-60'
    WHEN driver_age > 60 THEN '60+'
    ELSE 'Unknown'
  END AS age_group,
  COUNT(*) AS total_stops,
  SUM(CASE WHEN stop_outcome = 'Arrest' THEN 1 ELSE 0 END) AS total_arrests,
  ROUND(SUM(CASE WHEN stop_outcome = 'Arrest' THEN 1 ELSE 0 END) / COUNT(*) * 100, 2) AS arrest_rate_percent
FROM securecheck.police_logs
WHERE driver_age IS NOT NULL
GROUP BY age_group
ORDER BY arrest_rate_percent DESC
LIMIT 1;


## What is the gender distribution of drivers stopped in each country?

SELECT 
  country_name,
  COUNT(*) AS total_stops,
  SUM(CASE WHEN driver_gender = 'Male' THEN 1 ELSE 0 END) AS male_count,
  SUM(CASE WHEN driver_gender = 'Female' THEN 1 ELSE 0 END) AS female_count
FROM securecheck.police_logs
GROUP BY country_name
ORDER BY total_stops 

## Which race and gender combination has the highest search rate?

SELECT 
  driver_race,
  driver_gender,
  COUNT(*) AS total_stops,
  SUM(CASE WHEN search_conducted = 'Yes' THEN 1 ELSE 0 END) AS total_searches,
  ROUND(SUM(CASE WHEN search_conducted = 'Yes' THEN 1 ELSE 0 END) / COUNT(*) * 100, 2) AS search_rate_percent
FROM securecheck.police_logs
WHERE driver_race IS NOT NULL AND driver_gender IS NOT NULL
GROUP BY driver_race, driver_gender
ORDER BY search_rate_percent DESC
LIMIT 1

# What time of day sees the most traffic stops?

SELECT 
  HOUR(stop_time) AS hour_of_day,
  COUNT(*) AS total_stops
FROM securecheck.police_logs
GROUP BY hour_of_day
ORDER BY total_stops DESC
LIMIT 1;

## What is the average stop duration for different violations?

SELECT 
  violation,
  SEC_TO_TIME(AVG(TIME_TO_SEC(stop_duration))) AS avg_duration
FROM securecheck.police_logs
WHERE stop_duration IS NOT NULL
GROUP BY violation
ORDER BY avg_duration 

# Are stops during the night more likely to lead to arrests?

SELECT 
  CASE 
    WHEN HOUR(stop_time) BETWEEN 6 AND 18 THEN 'Day'
    ELSE 'Night'
  END AS time_period,
  COUNT(*) AS total_stops,
  SUM(CASE WHEN stop_outcome = 'Arrest' THEN 1 ELSE 0 END) AS total_arrests,
  ROUND(SUM(CASE WHEN stop_outcome = 'Arrest' THEN 1 ELSE 0 END) / COUNT(*) * 100, 2) AS arrest_rate_percent
FROM securecheck.police_logs
WHERE stop_time IS NOT NULL
GROUP BY time_period
ORDER BY arrest_rate_percent DESC;

# Which violations are most associated with searches or arrests?

SELECT 
  violation,
  COUNT(*) AS total_stops,
  SUM(CASE WHEN search_conducted = 'Yes' THEN 1 ELSE 0 END) AS total_searches,
  SUM(CASE WHEN stop_outcome = 'Arrest' THEN 1 ELSE 0 END) AS total_arrests,
  ROUND(SUM(CASE WHEN search_conducted = 'Yes' THEN 1 ELSE 0 END) / COUNT(*) * 100, 2) AS search_rate_percent,
  ROUND(SUM(CASE WHEN stop_outcome = 'Arrest' THEN 1 ELSE 0 END) / COUNT(*) * 100, 2) AS arrest_rate_percent
FROM securecheck.police_logs
GROUP BY violation
ORDER BY search_rate_percent DESC, arrest_rate_percent DESC;


# Which violations are most common among younger drivers (<25)?

SELECT 
  violation,
  COUNT(*) AS violation_count
FROM securecheck.police_logs
WHERE driver_age < 25
GROUP BY violation
ORDER BY violation_count DESC;

# Is there a violation that rarely results in search or arrest?
SELECT 
  violation,
  COUNT(*) AS total_stops,
  SUM(CASE WHEN search_conducted = 'Yes' THEN 1 ELSE 0 END) AS total_searches,
  SUM(CASE WHEN stop_outcome = 'Arrest' THEN 1 ELSE 0 END) AS total_arrests,
  ROUND(SUM(CASE WHEN search_conducted = 'Yes' THEN 1 ELSE 0 END) / COUNT(*) * 100, 2) AS search_rate_percent,
  ROUND(SUM(CASE WHEN stop_outcome = 'Arrest' THEN 1 ELSE 0 END) / COUNT(*) * 100, 2) AS arrest_rate_percent
FROM securecheck.police_logs
GROUP BY violation
HAVING search_rate_percent < 5 AND arrest_rate_percent < 5
ORDER BY total_stops DESC;

# Which countries report the highest rate of drug-related stops?

SELECT 
  country_name,
  COUNT(*) AS total_stops,
  SUM(CASE WHEN drugs_related_stop = 'Yes' THEN 1 ELSE 0 END) AS drug_related_stops,
  ROUND(SUM(CASE WHEN drugs_related_stop = 'Yes' THEN 1 ELSE 0 END) / COUNT(*) * 100, 2) AS drug_stop_rate_percent
FROM securecheck.police_logs
GROUP BY country_name
ORDER BY drug_stop_rate_percent DESC


# What is the arrest rate by country and violation?
SELECT 
  country_name,
  violation,
  COUNT(*) AS total_stops,
  SUM(CASE WHEN stop_outcome = 'Arrest' THEN 1 ELSE 0 END) AS total_arrests,
  ROUND(SUM(CASE WHEN stop_outcome = 'Arrest' THEN 1 ELSE 0 END) / COUNT(*) * 100, 2) AS arrest_rate_percent
FROM securecheck.police_logs
GROUP BY country_name, violation
ORDER BY arrest_rate_percent DESC;

# Which country has the most stops with search conducted?

SELECT 
  country_name,
  COUNT(*) AS search_count
FROM securecheck.police_logs
WHERE search_conducted = 'Yes'
GROUP BY country_name
ORDER BY search_count DESC
LIMIT 1;

# Yearly Breakdown of Stops and Arrests by Country (Using Subquery and Window Functions)
SELECT 
  country_name,
  stop_year,
  total_stops,
  total_arrests,
  ROUND(total_arrests / total_stops * 100, 2) AS arrest_rate_percent,
  RANK() OVER (PARTITION BY stop_year ORDER BY total_arrests DESC) AS arrest_rank_in_year
FROM (
  SELECT 
    country_name,
    YEAR(stop_date) AS stop_year,
    COUNT(*) AS total_stops,
    SUM(CASE WHEN stop_outcome = 'Arrest' THEN 1 ELSE 0 END) AS total_arrests
  FROM securecheck.police_logs
  WHERE stop_date IS NOT NULL
  GROUP BY country_name, YEAR(stop_date)
) AS yearly_data
ORDER BY stop_year, arrest_rank_in_year;

# Time Period Analysis of Stops (Joining with Date Functions) , Number of Stops by Year,Month, Hour of the Day
SELECT 
  YEAR(stop_date) AS stop_year,
  MONTH(stop_date) AS stop_month,
  HOUR(stop_time) AS stop_hour,
  COUNT(*) AS total_stops
FROM securecheck.police_logs
WHERE stop_date IS NOT NULL AND stop_time IS NOT NULL
GROUP BY stop_year, stop_month, stop_hour
ORDER BY stop_year, stop_month, stop_hour;


# 4.Violations with High Search and Arrest Rates (Window Function)

SELECT 
  violation,
  total_stops,
  total_searches,
  total_arrests,
  ROUND(total_searches / total_stops * 100, 2) AS search_rate_percent,
  ROUND(total_arrests / total_stops * 100, 2) AS arrest_rate_percent,
  RANK() OVER (ORDER BY total_searches / total_stops DESC) AS search_rank,
  RANK() OVER (ORDER BY total_arrests / total_stops DESC) AS arrest_rank
FROM (
  SELECT 
    violation,
    COUNT(*) AS total_stops,
    SUM(CASE WHEN search_conducted = 'Yes' THEN 1 ELSE 0 END) AS total_searches,
    SUM(CASE WHEN stop_outcome = 'Arrest' THEN 1 ELSE 0 END) AS total_arrests
  FROM securecheck.police_logs
  GROUP BY violation
) AS violation_stats
ORDER BY search_rate_percent DESC, arrest_rate_percent DESC;

# Driver Demographics by Country (Age, Gender, and Race)
SELECT 
  country_name,
  driver_gender,
  driver_race,
  CASE
    WHEN driver_age BETWEEN 16 AND 25 THEN '16-25'
    WHEN driver_age BETWEEN 26 AND 35 THEN '26-35'
    WHEN driver_age BETWEEN 36 AND 50 THEN '36-50'
    WHEN driver_age > 50 THEN '51+'
    ELSE 'Unknown'
  END AS age_group,
  COUNT(*) AS driver_count
FROM securecheck.police_logs
WHERE driver_age IS NOT NULL AND driver_gender IS NOT NULL AND driver_race IS NOT NULL
GROUP BY country_name, driver_gender, driver_race, age_group
ORDER BY country_name, driver_count DESC;

#  Violations with Highest Arrest Rates

SELECT 
  violation,
  COUNT(*) AS total_stops,
  SUM(CASE WHEN stop_outcome = 'Arrest' THEN 1 ELSE 0 END) AS total_arrests,
  ROUND(SUM(CASE WHEN stop_outcome = 'Arrest' THEN 1 ELSE 0 END) / COUNT(*) * 100, 2) AS arrest_rate_percent
FROM securecheck.police_logs
GROUP BY violation
ORDER BY arrest_rate_percent DESC
LIMIT 5;


