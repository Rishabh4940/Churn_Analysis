-- Bank Customer Churn - Diagnostic SQL
-- Reproduces and validates the Python analysis: churn rate, driver
-- breakdowns, high-risk segment, and risk tiering. Validated against pandas

-- overall churn rate
SELECT ROUND(AVG(churn)*100, 2) AS churn_rate FROM churn;

-- churn by products (the headline finding)
SELECT products_number,
       COUNT(*) AS customers,
       ROUND(AVG(churn)*100, 1) AS churn_rate
FROM churn
GROUP BY products_number
ORDER BY products_number;

-- the high-risk profile: country + activity + products
SELECT country, active_member, products_number,
       COUNT(*) AS customers,
       ROUND(AVG(churn)*100, 1) AS churn_rate
FROM churn
GROUP BY country, active_member, products_number
HAVING COUNT(*) >= 30
ORDER BY churn_rate DESC
LIMIT 10;

-- rank countries by churn rate using a window function
WITH country_churn AS (
    SELECT country,
           COUNT(*) AS customers,
           ROUND(AVG(churn)*100, 1) AS churn_rate
    FROM churn
    GROUP BY country
)
SELECT country, customers, churn_rate,
       RANK() OVER (ORDER BY churn_rate DESC) AS risk_rank
FROM country_churn;

-- classify customers into risk tiers based on their profile
SELECT
    CASE
        WHEN products_number >= 3 THEN 'High Risk (3+ products)'
        WHEN active_member = 0 AND products_number = 1 THEN 'High Risk (inactive, single product)'
        WHEN products_number = 2 THEN 'Low Risk (2 products)'
        ELSE 'Medium Risk'
    END AS risk_tier,
    COUNT(*) AS customers,
    ROUND(AVG(churn)*100, 1) AS churn_rate
FROM churn
GROUP BY risk_tier
ORDER BY churn_rate DESC;