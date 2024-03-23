CREATE DATABASE Mini_project ;
USE Mini_project ;

### Part 1 – Sales and Delivery:

SELECT * FROM cust_dimen;

ALTER TABLE cust_dimen MODIFY Customer_Name VARCHAR(30);
ALTER TABLE cust_dimen MODIFY Province VARCHAR(30);
ALTER TABLE cust_dimen MODIFY Region VARCHAR(30);
ALTER TABLE cust_dimen MODIFY Customer_Segment VARCHAR(30);
ALTER TABLE cust_dimen MODIFY Cust_id VARCHAR(10);
ALTER TABLE cust_dimen ADD PRIMARY KEY (Cust_id);

SELECT * FROM market_fact ;
ALTER TABLE market_fact MODIFY Ord_id VARCHAR(30);
ALTER TABLE market_fact MODIFY Prod_id VARCHAR(30);
ALTER TABLE market_fact MODIFY Ship_id VARCHAR(30);
ALTER TABLE market_fact MODIFY Cust_id VARCHAR(30);
ALTER TABLE market_fact MODIFY Sales FLOAT(10,2);
ALTER TABLE market_fact MODIFY Discount FLOAT(10,2);
ALTER TABLE market_fact MODIFY Order_Quantity FLOAT(10,2);
ALTER TABLE market_fact MODIFY Profit FLOAT(10,2);
ALTER TABLE market_fact MODIFY Shipping_Cost FLOAT(10,2);
ALTER TABLE market_fact MODIFY Product_Base_Margin  FLOAT(10,2);


ALTER TABLE orders_dimen MODIFY Order_ID INT(10);
ALTER TABLE orders_dimen MODIFY Order_Priority VARCHAR(30);
ALTER TABLE orders_dimen MODIFY Ord_id VARCHAR(10);
ALTER TABLE orders_dimen ADD primary key(Ord_ID);

SELECT * FROM prod_dimen;
ALTER TABLE prod_dimen MODIFY Product_Category VARCHAR(25);
ALTER TABLE prod_dimen MODIFY Product_Sub_Category VARCHAR(30);
ALTER TABLE prod_dimen MODIFY Prod_id VARCHAR(25);

ALTER TABLE prod_dimen ADD PRIMARY KEY(Prod_id);

SELECT * FROM shipping_dimen ;
ALTER TABLE shipping_dimen  MODIFY Ship_id VARCHAR(15);
ALTER TABLE shipping_dimen ADD PRIMARY KEY(Ship_id);

ALTER TABLE market_fact ADD FOREIGN KEY (Cust_id) REFERENCES cust_dimen(Cust_id);
ALTER TABLE market_fact ADD FOREIGN KEY (Ord_id) REFERENCES orders_dimen(Ord_id);
ALTER TABLE market_fact ADD FOREIGN KEY (Prod_id) REFERENCES prod_dimen(Prod_id);
ALTER TABLE market_fact ADD FOREIGN KEY (Ship_id)  REFERENCES shipping_dimen(Ship_id);

  --    Question 1: Find the top 3 customers who have the maximum number of orders  
  
SELECT cd.Customer_Name, COUNT(Ord_id) Count_of_Order_ID,SUM(Order_Quantity) Maximum_Orders
FROM Cust_dimen AS cd  JOIN market_fact AS mf
ON cd.Cust_id = mf.Cust_id
GROUP BY cd.Customer_Name 
ORDER BY SUM(Order_Quantity) DESC;

 -- Question 2: Create a new column DaysTaken For Delivery that contains the date difference between Order_Date and Ship_Date.
 
SELECT od.Order_ID , od.Order_Date ,od.Ord_id, sd.Ship_Date ,
datediff(str_to_date(Ship_Date , '%d-%m-%Y') , str_to_date(Order_Date , '%d-%m-%Y' )) AS Days_Taken_For_Delivery
FROM orders_dimen od
JOIN shipping_dimen sd
ON od. Order_Id=sd.Order_Id
ORDER BY Days_Taken_For_Delivery DESC;

-- Question 3: Find the customer whose order took the maximum time to get delivered.

SELECT cd.Cust_id,cd.Customer_Name,od.Order_ID,od.Order_Date,sd.Ship_id,sd.Ship_Date,
 datediff(str_to_date(Ship_Date , '%d-%m-%Y') , str_to_date(Order_Date , '%d-%m-%Y' )) as max_time_delivery
FROM cust_dimen AS cd JOIN market_fact AS mf
ON cd.Cust_id=mf.Cust_id
JOIN orders_dimen AS OD ON mf.Ord_id=od.Ord_id
JOIN shipping_dimen AS sd 
ON mf.Ship_id=sd.Ship_id
ORDER BY  max_time_delivery DESC 
LIMIT 1;

-- Question 4: Retrieve total sales made by each product from the data (use Windows function)

SELECT Prod_id,Sales , SUM(Sales)  OVER(PARTITION BY Prod_id) AS total_sales FROM  market_fact ;

 --  Question 5: Retrieve the total profit made from each product from the data (use windows function)

SELECT Prod_id,SUM(Profit) OVER(PARTITION BY Prod_id) 
FROM market_fact;

-- Question 6: Count the total number of unique customers in January and how many of them came back every month over the entire year in 2011

SELECT 'every month in 2011' as Description , count(*) AS count FROM 
((SELECT 'count' AS Descirption,count(distinct month) cnt FROM 
(SELECT customer_name,cd.Cust_id,year(str_to_date(Order_Date,'%d-%m-%Y')) year ,month(str_to_date(Order_Date,'%d-%m-%Y')) month 
FROM cust_dimen cd  JOIN market_fact  mf 
ON mf.Cust_id = cd.Cust_id 
JOIN orders_dimen od 
ON od.Ord_id=mf.Ord_id  ) t1 
WHERE year = 2011 
GROUP  BY  customer_name,Cust_id ,year,month
HAVING cnt>=12 )) AS t2
UNION ALL    
(SELECT  'total in january' , count(distinct cust_id)  FROM market_fact 
WHERE Ord_id IN 
(SELECT Ord_id FROM orders_dimen 
WHERE year(str_to_date(Order_Date,'%d-%m-%Y'))=2011 AND month(str_to_date(Order_Date,'%d-%m-%Y'))=1 ));

-- Part 2 – Restaurant

-- Question 1: - We need to find out the total visits to all restaurants under all alcohol categories available.

SELECT DISTINCT gp.name,gp.alcohol,count(rf.userID) AS tot_visits 
FROM rating_final rf 
JOIN geoplaces2 gp 
ON rf.placeID=gp.placeID 
GROUP BY gp.name,gp.alcohol ;
  
-- Question 2: -Let's find out the average rating according to alcohol and price so that 
-- we can understand the rating in respective price categories as well.

SELECT gp.alcohol, gp.price, AVG(rf.rating) AS avg_rating
FROM geoplaces2 gp
JOIN rating_final rf ON gp.placeID = rf.placeID
GROUP BY gp.alcohol, gp.price
ORDER by  AVG(rf.rating) DESC;

-- Question 3:  Let’s write a query to quantify that what are the parking availability as well in different alcohol categories
-- along with the total number of restaurants.

SELECT  gp.alcohol,cp.parking_lot,count(cp.placeID )total_restaurant
FROM chefmozparking AS cp 
JOIN geoplaces2 AS gp 
ON cp.placeID = gp.placeID
GROUP BY cp.parking_lot,gp.alcohol
Order by total_restaurant DESC;

-- Let us now look at a different prospect of the data to check state-wise rating.

-- Question 4: -Also take out the percentage of different cuisine in each alcohol type.

SELECT  gp.alcohol ,cc.Rcuisine,COUNT(*) AS cuisine_count,
ROUND((COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY gp.alcohol))*100 ,2) AS percentage
FROM geoplaces2 gp  JOIN chefmozcuisine cc
ON gp.placeID = cc.placeID
GROUP BY gp.alcohol ,cc.Rcuisine;

-- Questions 5: - let’s take out the average rating of each state.

SELECT gp.state,AVG(rf.rating) AS avg_rating
FROM rating_final AS rf RIGHT JOIN geoplaces2 AS gp
ON rf.placeID = gP.placeID 
GROUP BY gp.state
ORDER BY AVG(rf.rating) ;

-- Questions 6: -' Tamaulipas' Is the lowest average rated state. 
-- Quantify the reason why it is the lowest rated by providing the summary on the basis of State, alcohol, and Cuisine.

SELECT gp.state,cc.Rcuisine,gp.alcohol
FROM chefmozcuisine AS cc JOIN geoplaces2 AS gp
ON cc.placeID = gp.placeID 
WHERE  (SELECT ROUND(AVG(rating),2) AS avg_rating
FROM rating_final 
WHERE STATE = 'Tamaulipas');

-- Question 7:  - Find the average weight, food rating, and service rating of the customers who have visited KFC 
-- and tried Mexican or Italian types of cuisine, and also their budget level is low.
-- We encourage you to give it a try by not using joins.

SELECT DISTINCT up.userID ,gp.name,r.food_rating,r.service_rating,uc.rcuisine,AVG(up.weight) AS avg_weight 
FROM userprofile up, usercuisine uc, rating_final r, geoplaces2 gp
WHERE up.userid=r.userID AND uc.userid=r.userID AND gp.placeID=r.placeID
AND budget="low" AND gp.name="KFC"
AND Rcuisine IN("Mexican","italian") 
GROUP BY up.userID,gp.name,uc.rcuisine,r.food_rating,r.service_rating;

-- Part 3:  Triggers
-- Question 1:
-- Create two called Student_details and Student_details_backup.

--       Table 1: Attributes 		                     Table 2: Attributes
-- Student id, Student name, mail id, mobile no.	Student id, student name, mail id, mobile no.

-- You have the above two tables Students Details and Student Details Backup. Insert some records into Student details. 

-- Problem:

-- Let’s say you are studying SQL for two weeks. In your institute, there is an employee who has been maintaining the student’s details 
-- and Student Details Backup tables. He / She is deleting the records from the Student details after the students completed the course 
-- and keeping the backup in the student details backup table by inserting the records every time. You are noticing this daily
-- and now you want to help him/her by not inserting the records for backup purpose when he/she delete the records.
-- write a trigger that should be capable enough to insert the student details in the backup table whenever the employee deletes records 
-- from the student details table.

-- Note: Your query should insert the rows in the backup table before deleting the records from student details.
DROP DATABASE students;
CREATE DATABASE students;
USE students;
CREATE TABLE Students_Details(
Student_ID INTEGER NOT NULL PRIMARY KEY,
Student_Name VARCHAR(20),
Mail_ID VARCHAR(30),
MOBILE_NO VARCHAR(10));

CREATE TABLE Student_details_backup(
Student_ID INTEGER NOT NULL PRIMARY KEY,
Student_Name VARCHAR(20),
Mail_ID VARCHAR(30),
MOBILE_NO VARCHAR(10));

INSERT INTO Students_Details VALUES
(1011,'Diya','diya1508@gmail.com','9254876398'),
(1012,'Sashini','sashini2022@gmail.com','9674536271'),
(1013,'Ahana','ahana2906@gmail.com','9567030304'),
(1014,'Bala','bala3109@gmail.com','9078653421'),
(1015,'Nivi','nivi2508@gmail.com','8976450910');
SELECT * FROM Students_Details;
CREATE TRIGGER trigger_backup
BEFORE DELETE 
ON Students_Details FOR EACH ROW
INSERT INTO Student_details_backup(Student_ID,Student_Name,Mail_ID,MOBILE_NO)
VALUES(OLD.Student_ID,OLD.Student_Name,OLD.Mail_ID,OLD.MOBILE_NO);

SELECT * FROM Students_details;

DELETE FROM Students_Details
WHERE Student_ID=1011;
SELECT * FROM Student_details_backup;
DELETE FROM Students_Details;
SELECT * FROM Student_details_backup;
SET SQL_SAFE_UPDATES=0;

SELECT * FROM StudentS_details;
