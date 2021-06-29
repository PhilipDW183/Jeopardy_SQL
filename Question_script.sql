#Make sure all the data has been read in correctly
#so inspect the first 10 rows of each table
SELECT * 
from single_table
Limit 10;

SELECT * 
from double_table
Limit 10;

select * 
from final_table
Limit 10;

#We want to change air date to date format
ALTER TABLE single_table
MODIFY ` Air Date` DATE;

ALTER TABLE double_table
MODIFY ` Air Date` DATE;

ALTER TABLE final_table
MODIFY ` Air Date` DATE;

#A lot of the questions relate to either date or category
# The questions relating to category are on the full dataset
#questions relating to date refer to individual datasets
#indexes can be created on date for each dataset
#we can create a temporary table for the aggregated view
#which will have an index on Category to speed it up

CREATE INDEX Air_Date
ON double_table (' Air Date');

CREATE INDEX Air_Date
ON single_table (` Air Date`);

CREATE INDEX Air_Date
ON final_table (` Air Date`);

CREATE VIEW all_stages AS
SELECT * FROM single_table
UNION ALL
SELECT * FROM double_table
UNION ALL
SELECT * FROM final_table;


#Question 1
#Use the view to find the count of the distinct number of categories
SELECT COUNT(DISTINCT category)
FROM all_stages;
#27913 categories found

#Question 2
#list all categories in alphabetical order
SELECT DISTINCT category
FROM all_stages
#order by categories ascending for alphabetical
ORDER BY category ASC
Limit 27913;

#Question 3
#Select all questions from History and Libraries and write
#The Q&A info into a single column seperated by a '?'
#ordered by value

#To order by value need to cast `value` to integer
SELECT category, CAST(replace(replace(`Value`, "$", ""), ',', "") AS DECIMAL) as Val,
#Use concat to add columns together 
CONCAT(Question, "?" ,Answer) AS QA
FROM all_stages
#Where clause for category match
WHERE category = "HISTORY"
OR category = "LIBRARIES"
#order by val 
ORDER BY Val;

#Question 4
#Find a random history question for each unique question value each time
#Bonus points for determinism 

set @num1 =0, @num2 = 0;

#solution from: https://stackoverflow.com/questions/6251101/join-two-tables-in-mysql-with-random-rows-from-the-second
#this is the best solution I could find, does not work completely
SELECT DISTINCT(CAST(replace(replace(a.`Value`, "$", ""), ',', "") AS DECIMAL)) as Value,
b.Question
FROM (
SELECT DISTINCT(CAST(replace(replace(`Value`, "$", ""), ',', "") AS DECIMAL)) as Value,
@num1:=@num1+1 as num
from all_stages) as a
INNER JOIN (
SELECT Question, @num2:=@num2+1 AS num
FROM (
SELECT Question
FROM all_stages
WHERE Category = "History"
ORDER BY RAND()
LIMIT 146) as t
) AS b
ON a.num = b.num;



#Question 5
#Find the number of questions in each category to find the 10 least
#use categories

#Select category, extract count
SELECT category, COUNT(*) as number_of_questions
from all_stages
GROUP BY category
#order by number of questions in increasing order
ORDER BY number_of_questions ASC
#limit to 10 least used
Limit 10;

#Question 6
#Check for duplicate answers

#Query to find if duplicates do exist
SELECT Answer, COUNT(*)
FROM all_stages
GROUP BY Answer
#If count is greater than 1 then there is duplicates
HAVING COUNT(*) > 1
ORDER BY COUNT(*) DESC;

#Show the rows where duplicates exist
SELECT a.*, b.No_of_answers
FROM all_stages a
#join with duplicated answers and their count
JOIN (SELECT Answer, COUNT(*) as No_of_answers
FROM all_stages
GROUP BY Answer
HAVING COUNT(*) > 1) b
#match on where there are duplicate answers
on a.Answer = b.Answer
ORDER BY b.NO_of_answers DESC;



#Trend and Data Modelling

#Question 7
#Can you find the trend in question value over time for 
#each dataset?

#Create queries for each airdate and value
SELECT ` Air Date`, AVG(CAST(replace(replace(` Value`, "$", ""), ',', "") AS DECIMAL))as AVG_Value
FROM double_table
GROUP BY ` Air Date`
ORDER BY ` Air Date` ASC;

SELECT ` Air Date`, AVG(CAST(replace(replace(` Value`, "$", ""), ',', "") AS DECIMAL))as AVG_Value
FROM single_table
GROUP BY ` Air Date`
ORDER BY ` Air Date` ASC;

#Trend analysis undertaken in Python

#Given the trend analysis suggesting no clear trend, the
#predicted question price is simply the current average question
#price for each dataset which is given by:
SELECT AVG(CAST(replace(replace(` Value`, "$", ""), ',', "") AS DECIMAL)) as AVG_Value
FROM single_table
WHERE ` Air Date` >= '2001-11-26';
#value of 619.94

SELECT AVG(CAST(replace(replace(` Value`, "$", ""), ',', "") AS DECIMAL)) as AVG_Value
FROM double_table
WHERE ` Air Date` >= '2001-11-26';
#predicted value of 1280.05

# Question 10
# Is there a correlation between question value and category of question?

#Find the top 10 categories by value
SELECT Category, AVG(CAST(replace(replace(`Value`, "$", ""), ',', "") AS DECIMAL))as AVG_Value
FROM all_stages
GROUP BY Category
ORDER BY AVG_Value DESC
Limit 10;

#Find the bottom 10 categories by value
SELECT Category, AVG(CAST(replace(replace(`Value`, "$", ""), ',', "") AS DECIMAL))as AVG_Value
FROM all_stages
GROUP BY Category
ORDER BY AVG_Value DESC
Limit 10;

#Question 11
#Which month had the most episodes?

#Extract the month name
#extract the count of each distinct show within the month
SELECT monthname(`Air Date`) as Month, COUNT(DISTINCT(`Show Number`)) as Number_of_episodes
FROM all_stages
GROUP BY monthname(`Air Date`) 
#order by number of episodes
ORDER BY Number_of_episodes DESC;
#Month with highest number of episodes is November with 434


# Multiple data sources

#Question 12
#How many countries are used, and how frequently are they used?

#How many countries are used
#Count distinct country name
SELECT COUNT(DISTINCT(b.Name))
FROM all_stages a
#join on countries dataset
INNER JOIN  countries b 
#Find partial match in strings
ON a.Answer LIKE concat("%", b.Name, "%")
OR a.Question LIKE concat("%", b.Name, "%");
#205 countries used


#How frequent are countries used in answers
#count the number of answers containing a given country
SELECT count(a.Answer) as country_occurences, b.Name 
FROM all_stages a
INNER JOIN  countries b 
#join on answer
ON a.Answer LIKE concat('%', b.Name, '%')
#group by the name of the country
group by b.Name
#order by the count
ORDER BY country_occurences DESC; 
#With India being the country most used in an answer with 489 uses


#Question 13
#Any correlation between the country used and value of the question

#Select average value of each country used, get country name
SELECT AVG(CAST(replace(replace(a.`Value`, "$", ""), ',', "") AS DECIMAL)) as AVG_Value, b.Name 
FROM all_stages a
#use join to find partial matches in question and answer
INNER JOIN  countries b 
ON  a.Question LIKE concat('%', b.Name, '%')
OR a.Answer LIKE concat('%', b.Name, '%')
#groupby country name
group by b.Name
#order by value descending
ORDER BY AVG_Value DESC; 

#Results show clear differences in average value between countries
#with Cape Verde on average worth $1733.33 while
#Tokelau worth on average $100


