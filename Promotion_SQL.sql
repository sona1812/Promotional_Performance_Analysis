USE retail_events_db;
SELECT * FROM dim_campaign;
SELECT * FROM dim_products;
SELECT * FROM dim_stores; 
SELECT * FROM fact_campaign_data;

---- List of products with a base price > 500 and that are featured in BOGOF promo type
SELECT DISTINCT f.product_code, p.product_name, f.base_price, f.promo_type
FROM fact_campaign_data AS f
JOIN dim_products AS p ON f.product_code = p.product_code
WHERE f.base_price > 500 AND f.promo_type = "BOGOF"; 

----  Generate a report that provides an overview of the no of stores in each city.
SELECT city, COUNT(store_id) AS total_stores_percity
FROM dim_stores
GROUP BY city
ORDER BY total_stores_percity DESC;  

---- Generate a report that displays each campaign along with total revenue generated before and after promotion 
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

---- Produce a report that calculates ISU% for each category during Diwali campaign. Aditionally provide rankings for the category based on ISU% 
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
    
---- Create a report featuring Top 5 Products ranked by IR% across each campaign. The report will provide essential information including product name, category, IR%

WITH product_revenue AS (
  SELECT 
    c.campaign_name,
    p.product_name,
    p.category,
    SUM(base_price * `quantity_sold(before_promo)`) / 1000000 AS Revenue_BP,
    SUM(
      CASE
        WHEN promo_type = 'BOGOF' THEN base_price * `quantity_sold(after_promo)`
        WHEN promo_type = '50% OFF' THEN base_price * 0.5 * `quantity_sold(after_promo)`
        WHEN promo_type = '25% OFF' THEN base_price * 0.75 * `quantity_sold(after_promo)`
        WHEN promo_type = '33% OFF' THEN base_price * 0.67 * `quantity_sold(after_promo)`
        WHEN promo_type = '500 Cashback' THEN (base_price - 500) * `quantity_sold(after_promo)`
        ELSE 0
      END
    ) / 1000000 AS Revenue_AP
  FROM fact_campaign_data AS f
  JOIN dim_campaign AS c ON c.campaign_id = f.campaign_id
  JOIN dim_products AS p ON p.product_code = f.product_code
  GROUP BY c.campaign_name, p.category, p.product_name
),
ranked_ir AS (
  SELECT 
    campaign_name,
    product_name,
    category,
    ROUND(((Revenue_AP - Revenue_BP) / NULLIF(Revenue_BP, 0)) * 100, 2) AS `IR%`,
    RANK() OVER (PARTITION BY campaign_name ORDER BY ((Revenue_AP - Revenue_BP) / NULLIF(Revenue_BP, 0)) DESC) AS rnk
  FROM product_revenue
)
SELECT 
  campaign_name,
  product_name,
  category,
  `IR%`
FROM ranked_ir
WHERE rnk <= 5
ORDER BY campaign_name, rnk;  

---- Top 10 store in terms of IR generated from the promotion 
WITH store_revenue AS (
  SELECT 
    s.store_id,
    s.city,
    
    SUM(base_price * `quantity_sold(before_promo)`) AS revenue_before,
    
    SUM(
      CASE
        WHEN promo_type = 'BOGOF' THEN base_price * `quantity_sold(after_promo)`
        WHEN promo_type = '50% OFF' THEN base_price * 0.5 * `quantity_sold(after_promo)`
        WHEN promo_type = '25% OFF' THEN base_price * 0.75 * `quantity_sold(after_promo)`
        WHEN promo_type = '33% OFF' THEN base_price * 0.67 * `quantity_sold(after_promo)`
        WHEN promo_type = '500 Cashback' THEN (base_price - 500) * `quantity_sold(after_promo)`
        ELSE 0
      END
    ) AS revenue_after
  FROM fact_campaign_data AS f
  JOIN dim_stores AS s ON f.store_id = s.store_id
  GROUP BY s.store_id, s.city
),
store_ir AS (
  SELECT 
    store_id,
    city,
    ROUND(((revenue_after - revenue_before) / NULLIF(revenue_before, 0)) * 100, 2) AS `IR%`
  FROM store_revenue
)
SELECT *
FROM store_ir
ORDER BY `IR%` DESC
LIMIT 10;  

---- Top 2 Promotion type taht resulted in highest IR
WITH promo_revenue AS (
  SELECT 
    promo_type,
    SUM(base_price * `quantity_sold(before_promo)`) AS revenue_before,
    SUM(
      CASE
        WHEN promo_type = 'BOGOF' THEN base_price * `quantity_sold(after_promo)`
        WHEN promo_type = '50% OFF' THEN base_price * 0.5 * `quantity_sold(after_promo)`
        WHEN promo_type = '25% OFF' THEN base_price * 0.75 * `quantity_sold(after_promo)`
        WHEN promo_type = '33% OFF' THEN base_price * 0.67 * `quantity_sold(after_promo)`
        WHEN promo_type = '500 Cashback' THEN (base_price - 500) * `quantity_sold(after_promo)`
        ELSE 0
      END
    ) AS revenue_after
  FROM fact_campaign_data
  GROUP BY promo_type
),
promo_ir AS (
  SELECT 
    promo_type,
    ROUND(((revenue_after - revenue_before) / NULLIF(revenue_before, 0)) * 100, 2) AS `IR%`
  FROM promo_revenue
)
SELECT *
FROM promo_ir
ORDER BY `IR%` DESC
LIMIT 2;  







     

