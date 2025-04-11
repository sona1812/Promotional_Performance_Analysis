USE `retail_events_db`;
CREATE TABLE `dim_campaigns` (
  `campaign_id` varchar(20) NOT NULL,
  `campaign_name` varchar(50) NOT NULL,
  `start_date` date NOT NULL,
  `end_date` date NOT NULL,
  PRIMARY KEY (`campaign_id`)
);
SELECT * FROM dim_campaign;
SELECT * FROM dim_products;
SELECT * FROM dim_stores;
SELECT * FROM fact_campaign_data;
-- List of products with a base price > 500 and that are featured in BOGOF promo type
SELECT DISTINCT f.product_code, p.product_name, f.base_price, f.promo_type
FROM fact_campaign_data AS f
JOIN dim_products AS p ON f.product_code = p.product_code
WHERE f.base_price > 500 AND f.promo_type = "BOGOF"; 

-- Generate a report that provides an overview of the no of stores in each city.
SELECT city, COUNT(store_id) AS total_stores_percity
FROM dim_stores
GROUP BY city
ORDER BY total_stores_percity DESC; 

-- Generate a report that displays each campaign along with total revenue generated before and after promotion
SELECT c.campaign_name, CONCAT(ROUND(SUM(base_price * `quantity_sold(before_promo)`)/1000000,2),'M') AS Revenue_BP,
CONCAT(ROUND(SUM(
CASE
WHEN promo_type = "BOGOF" THEN base_price * `quantity_sold(after_promo)`
WHEN promo_type = "50% OFF" THEN base_price * 0.5 * `quantity_sold(after_promo)`
WHEN promo_type = "25% OFF" THEN base_price * 0.75 * `quantity_sold(after_promo)`
WHEN promo_type = "33% OFF" THEN base_price * 0.67 * `quantity_sold(after_promo)`
WHEN promo_type = "500 Cashback" THEN (f.base_price - 500) * `quantity_sold(after_promo)`
END)/1000000,2),'M') AS Revenue_AP
FROM fact_campaign_data AS f 
JOIN dim_campaign AS c ON c.campaign_id = f.campaign_id
GROUP BY c.campaign_name; 
-- Produce a report that calculates ISU% for each category during Diwali campaign. Aditionally provide rankings for the category based on ISU% 
SELECT category, campaign_name, `ISU%`,
       RANK() OVER (ORDER BY `ISU%` DESC) AS `Rank`
FROM (
    SELECT p.category, 
           c.campaign_name, 
           ((SUM(`quantity_sold(after_promo)`) - SUM(`quantity_sold(before_promo)`)) / SUM(`quantity_sold(before_promo)`)) * 100 AS `ISU%`
    FROM fact_campaign_data AS f 
    JOIN dim_products AS p ON f.product_code = p.product_code
    JOIN dim_campaign AS c ON c.campaign_id = f.campaign_id
    WHERE c.campaign_name = "Diwali"
    GROUP BY p.category, c.campaign_name
) AS ranked_data; 
-- Find out top 3 promo types with respect to revenue generated after promo.
SELECT promo_type,
CONCAT(ROUND(SUM(
CASE
WHEN promo_type = "BOGOF" THEN base_price * `quantity_sold(after_promo)`
WHEN promo_type = "50% OFF" THEN base_price * 0.5 * `quantity_sold(after_promo)`
WHEN promo_type = "25% OFF" THEN base_price * 0.75 * `quantity_sold(after_promo)`
WHEN promo_type = "33% OFF" THEN base_price * 0.67 * `quantity_sold(after_promo)`
WHEN promo_type = "500 Cashback" THEN (f.base_price - 500) * `quantity_sold(after_promo)`
END)/1000000,2),'M') AS Revenue_AP
FROM fact_campaign_data AS f 
GROUP BY promo_type
ORDER BY Revenue_AP DESC
LIMIT 3; 
 
-- Generate a report that provides an overview of stores along with before and after revenue generated
SELECT s.store_id, CONCAT(ROUND(SUM(base_price * `quantity_sold(before_promo)`)/1000000,2),'M') AS Revenue_BP,
CONCAT(ROUND(SUM(
CASE
WHEN promo_type = "BOGOF" THEN base_price * `quantity_sold(after_promo)`
WHEN promo_type = "50% OFF" THEN base_price * 0.5 * `quantity_sold(after_promo)`
WHEN promo_type = "25% OFF" THEN base_price * 0.75 * `quantity_sold(after_promo)`
WHEN promo_type = "33% OFF" THEN base_price * 0.67 * `quantity_sold(after_promo)`
WHEN promo_type = "500 Cashback" THEN (f.base_price - 500) * `quantity_sold(after_promo)`
END)/1000000,2),'M') AS Revenue_AP
FROM fact_campaign_data AS f 
JOIN dim_stores AS s ON s.store_id = f.store_id
GROUP BY s.store_id;  

-- Generate a report that provides an overview of categories along with before and after revenue generated
SELECT p.category, CONCAT(ROUND(SUM(base_price * `quantity_sold(before_promo)`)/1000000,2),'M') AS Revenue_BP,
CONCAT(ROUND(SUM(
CASE
WHEN promo_type = "BOGOF" THEN base_price * `quantity_sold(after_promo)`
WHEN promo_type = "50% OFF" THEN base_price * 0.5 * `quantity_sold(after_promo)`
WHEN promo_type = "25% OFF" THEN base_price * 0.75 * `quantity_sold(after_promo)`
WHEN promo_type = "33% OFF" THEN base_price * 0.67 * `quantity_sold(after_promo)`
WHEN promo_type = "500 Cashback" THEN (f.base_price - 500) * `quantity_sold(after_promo)`
END)/1000000,2),'M') AS Revenue_AP
FROM fact_campaign_data AS f 
JOIN dim_products AS p ON p.product_code = f.product_code
GROUP BY p.category;  

SELECT category, product_name, `IR%`
FROM (
       SELECT p.category, p.product_name, ROUND(SUM(base_price * `quantity_sold(before_promo)`)/1000000,2) AS Revenue_BP,
       ROUND(SUM(
CASE
WHEN promo_type = "BOGOF" THEN base_price * `quantity_sold(after_promo)`
WHEN promo_type = "50% OFF" THEN base_price * 0.5 * `quantity_sold(after_promo)`
WHEN promo_type = "25% OFF" THEN base_price * 0.75 * `quantity_sold(after_promo)`
WHEN promo_type = "33% OFF" THEN base_price * 0.67 * `quantity_sold(after_promo)`
WHEN promo_type = "500 Cashback" THEN (f.base_price - 500) * `quantity_sold(after_promo)`
END)/1000000,2) AS Revenue_AP, ((Revenue_AP - Revenue_BP)/Revenue_BP) * 100 AS `IR%`
FROM fact_campaign_data AS f 
JOIN dim_products AS p ON p.product_code = f.product_code
GROUP BY p.category) AS IR ; 

       

       
       






