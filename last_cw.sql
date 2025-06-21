-- Продажи по категориям
WITH category_sales AS (
  SELECT
    p.category,
    SUM(oi.amount) AS total_sales,
    COUNT(DISTINCT oi.order_id) AS order_count
  FROM order_items oi
  JOIN products p ON oi.product_id = p.id
  GROUP BY p.category
),
total_all_sales AS (
  SELECT SUM(amount) AS total_sales FROM order_items
)
SELECT
  cs.category,
  cs.total_sales,
  ROUND(cs.total_sales::numeric / cs.order_count, 2) AS avg_per_order,
  ROUND(cs.total_sales / tas.total_sales * 100, 2) AS category_share
FROM category_sales cs, total_all_sales tas
ORDER BY cs.total_sales DESC;

-- Анализ покупателей

WITH order_totals AS (
  SELECT
    o.id AS order_id,
    o.customer_id,
    o.order_date,
    SUM(oi.amount) AS order_total
  FROM orders o
  JOIN order_items oi ON o.id = oi.order_id
  GROUP BY o.id, o.customer_id, o.order_date
),
customer_totals AS (
  SELECT
    customer_id,
    SUM(order_total) AS total_spent,
    ROUND(AVG(order_total), 2) AS avg_order_amount
  FROM order_totals
  GROUP BY customer_id
)
SELECT
  ot.customer_id,
  ot.order_id,
  ot.order_date,
  ot.order_total,
  ct.total_spent,
  ct.avg_order_amount,
  ROUND(ot.order_total - ct.avg_order_amount, 2) AS difference_from_avg
FROM order_totals ot
JOIN customer_totals ct ON ot.customer_id = ct.customer_id
ORDER BY ot.customer_id, ot.order_date;

-- Сравнение продаж по месяцам

WITH sales_by_month AS (
  SELECT
    TO_CHAR(o.order_date, 'YYYY-MM') AS year_month,
    DATE_TRUNC('month', o.order_date) AS month_date,
    SUM(oi.amount) AS total_sales
  FROM orders o
  JOIN order_items oi ON o.id = oi.order_id
  GROUP BY year_month, month_date
),
sales_with_lags AS (
  SELECT
    sbm.year_month,
    sbm.total_sales,
    LAG(sbm.total_sales) OVER (ORDER BY sbm.month_date) AS prev_month_sales,
    LAG(sbm.total_sales, 12) OVER (ORDER BY sbm.month_date) AS prev_year_sales
  FROM sales_by_month sbm
)
SELECT
  year_month,
  total_sales,
  ROUND((total_sales - prev_month_sales) / NULLIF(prev_month_sales, 0) * 100, 2) AS prev_month_diff,
  ROUND((total_sales - prev_year_sales) / NULLIF(prev_year_sales, 0) * 100, 2) AS prev_year_diff
FROM sales_with_lags
ORDER BY year_month;


