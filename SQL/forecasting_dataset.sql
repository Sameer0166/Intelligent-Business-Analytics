SELECT
    order_date::DATE AS date,
    ROUND(SUM(final_amount), 2) AS daily_revenue,
    COUNT(DISTINCT order_id) AS daily_orders,
    COUNT(DISTINCT customer_id) AS daily_customers
FROM ecommerce.orders
WHERE order_date IS NOT NULL
GROUP BY order_date::DATE
ORDER BY date;