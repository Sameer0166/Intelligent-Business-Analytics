-- ============================================================
-- INTELLIGENT AUTOMATED BUSINESS ANALYTICS PLATFORM
-- LEVEL 5 - ADVANCED BUSINESS ANALYTICS ENGINE
-- PostgreSQL Optimized Version
-- ============================================================

-- ============================================================
-- 1. REGIONAL BUSINESS PERFORMANCE
-- ============================================================

WITH regional_orders AS (
    SELECT
        o.delivery_state AS state,
        COUNT(DISTINCT o.order_id) AS total_orders,
        COUNT(DISTINCT o.customer_id) AS total_customers,
        SUM(o.final_amount) AS total_revenue
    FROM ecommerce.orders o
    GROUP BY o.delivery_state
),
regional_profit AS (
    SELECT
        o.delivery_state AS state,
        SUM(oi.profit) AS total_profit
    FROM ecommerce.orders o
    JOIN ecommerce.order_items oi
        ON o.order_id = oi.order_id
    GROUP BY o.delivery_state
)
SELECT
    ro.state,
    ro.total_orders,
    ro.total_customers,
    ROUND(ro.total_revenue, 2) AS total_revenue,
    ROUND(COALESCE(rp.total_profit, 0), 2) AS total_profit,
    ROUND(
        ro.total_revenue /
        NULLIF(ro.total_orders, 0),
        2
    ) AS average_order_value
FROM regional_orders ro
LEFT JOIN regional_profit rp
    ON ro.state = rp.state
ORDER BY total_revenue DESC;


-- ============================================================
-- 2. REGIONAL PROFITABILITY
-- ============================================================

WITH regional_orders AS (
    SELECT
        o.delivery_state AS state,
        SUM(o.final_amount) AS revenue
    FROM ecommerce.orders o
    GROUP BY o.delivery_state
),
regional_profit AS (
    SELECT
        o.delivery_state AS state,
        SUM(oi.profit) AS profit
    FROM ecommerce.orders o
    JOIN ecommerce.order_items oi
        ON o.order_id = oi.order_id
    GROUP BY o.delivery_state
)
SELECT
    ro.state,
    ROUND(ro.revenue, 2) AS revenue,
    ROUND(COALESCE(rp.profit, 0), 2) AS profit,
    ROUND(
        COALESCE(rp.profit, 0) /
        NULLIF(ro.revenue, 0) * 100,
        2
    ) AS profit_margin
FROM regional_orders ro
LEFT JOIN regional_profit rp
    ON ro.state = rp.state
ORDER BY profit_margin DESC;


-- ============================================================
-- 3. RETURN REASON ANALYSIS
-- ============================================================

WITH total_returns AS (
    SELECT COUNT(*) AS total
    FROM ecommerce.returns
)
SELECT
    r.return_reason,
    COUNT(*) AS total_returns,
    ROUND(
        COUNT(*)::NUMERIC /
        NULLIF(tr.total, 0) * 100,
        2
    ) AS return_percentage
FROM ecommerce.returns r
CROSS JOIN total_returns tr
GROUP BY
    r.return_reason,
    tr.total
ORDER BY total_returns DESC;


-- ============================================================
-- 4. RETURN ANALYSIS BY CATEGORY
-- ============================================================

WITH category_sales AS (
    SELECT
        p.category,
        COUNT(DISTINCT oi.order_item_id) AS sold_items
    FROM ecommerce.order_items oi
    JOIN ecommerce.products p
        ON oi.product_id = p.product_id
    GROUP BY p.category
),
category_returns AS (
    SELECT
        p.category,
        COUNT(DISTINCT r.return_id) AS total_returns
    FROM ecommerce.returns r
    JOIN ecommerce.products p
        ON r.product_id = p.product_id
    GROUP BY p.category
)
SELECT
    cs.category,
    cs.sold_items,
    COALESCE(cr.total_returns, 0) AS total_returns,
    ROUND(
        COALESCE(cr.total_returns, 0)::NUMERIC /
        NULLIF(cs.sold_items, 0) * 100,
        2
    ) AS return_rate
FROM category_sales cs
LEFT JOIN category_returns cr
    ON cs.category = cr.category
ORDER BY return_rate DESC;


-- ============================================================
-- 5. PRODUCT RETURN ANALYSIS
-- ============================================================

WITH product_sales AS (
    SELECT
        oi.product_id,
        COUNT(DISTINCT oi.order_item_id) AS units_sold
    FROM ecommerce.order_items oi
    GROUP BY oi.product_id
),
product_returns AS (
    SELECT
        r.product_id,
        COUNT(DISTINCT r.return_id) AS total_returns
    FROM ecommerce.returns r
    GROUP BY r.product_id
)
SELECT
    p.product_id,
    p.product_name,
    p.category,
    ps.units_sold,
    COALESCE(pr.total_returns, 0) AS total_returns,
    ROUND(
        COALESCE(pr.total_returns, 0)::NUMERIC /
        NULLIF(ps.units_sold, 0) * 100,
        2
    ) AS return_rate
FROM ecommerce.products p
JOIN product_sales ps
    ON p.product_id = ps.product_id
LEFT JOIN product_returns pr
    ON p.product_id = pr.product_id
WHERE COALESCE(pr.total_returns, 0) > 0
ORDER BY total_returns DESC
LIMIT 20;


-- ============================================================
-- 6. SHIPPING METHOD PERFORMANCE
-- ============================================================

SELECT
    s.shipping_method,
    COUNT(*) AS total_shipments,
    ROUND(AVG(s.delivery_days), 2) AS average_delivery_days,
    COUNT(*) FILTER (
        WHERE s.delayed_flag = 1
    ) AS delayed_shipments,
    ROUND(
        COUNT(*) FILTER (
            WHERE s.delayed_flag = 1
        )::NUMERIC /
        NULLIF(COUNT(*), 0) * 100,
        2
    ) AS delayed_rate
FROM ecommerce.shipments s
GROUP BY s.shipping_method
ORDER BY delayed_rate DESC;


-- ============================================================
-- 7. WAREHOUSE PERFORMANCE
-- ============================================================

SELECT
    s.warehouse_city,
    COUNT(*) AS total_shipments,
    ROUND(AVG(s.delivery_days), 2) AS average_delivery_days,
    COUNT(*) FILTER (
        WHERE s.delayed_flag = 1
    ) AS delayed_shipments,
    ROUND(
        COUNT(*) FILTER (
            WHERE s.delayed_flag = 1
        )::NUMERIC /
        NULLIF(COUNT(*), 0) * 100,
        2
    ) AS delayed_rate
FROM ecommerce.shipments s
GROUP BY s.warehouse_city
ORDER BY delayed_rate DESC;


-- ============================================================
-- 8. CUSTOMER VALUE ANALYSIS
-- ============================================================

SELECT
    c.customer_segment,
    COUNT(DISTINCT c.customer_id) AS customers,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(o.final_amount), 2) AS revenue,
    ROUND(
        SUM(o.final_amount) /
        NULLIF(COUNT(DISTINCT c.customer_id), 0),
        2
    ) AS revenue_per_customer,
    ROUND(
        COUNT(DISTINCT o.order_id)::NUMERIC /
        NULLIF(COUNT(DISTINCT c.customer_id), 0),
        2
    ) AS orders_per_customer
FROM ecommerce.customers c
JOIN ecommerce.orders o
    ON c.customer_id = o.customer_id
GROUP BY c.customer_segment
ORDER BY revenue_per_customer DESC;


-- ============================================================
-- 9. LOYALTY TIER PERFORMANCE
-- ============================================================

SELECT
    c.loyalty_tier,
    COUNT(DISTINCT c.customer_id) AS customers,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(o.final_amount), 2) AS revenue,
    ROUND(
        SUM(o.final_amount) /
        NULLIF(COUNT(DISTINCT c.customer_id), 0),
        2
    ) AS revenue_per_customer,
    ROUND(
        SUM(o.final_amount) /
        NULLIF(COUNT(DISTINCT o.order_id), 0),
        2
    ) AS average_order_value
FROM ecommerce.customers c
LEFT JOIN ecommerce.orders o
    ON c.customer_id = o.customer_id
GROUP BY c.loyalty_tier
ORDER BY revenue DESC;


-- ============================================================
-- 10. MARKETING CAMPAIGN PERFORMANCE
-- ============================================================

SELECT
    mc.campaign_id,
    mc.campaign_name,
    COUNT(DISTINCT o.order_id) AS total_orders,
    COUNT(DISTINCT o.customer_id) AS customers,
    ROUND(COALESCE(SUM(o.final_amount), 0), 2) AS revenue,
    ROUND(
        COALESCE(SUM(o.final_amount), 0) /
        NULLIF(COUNT(DISTINCT o.order_id), 0),
        2
    ) AS average_order_value
FROM ecommerce.marketing_campaigns mc
LEFT JOIN ecommerce.orders o
    ON mc.campaign_id = o.campaign_id
GROUP BY
    mc.campaign_id,
    mc.campaign_name
ORDER BY revenue DESC;


-- ============================================================
-- 11. PAYMENT METHOD ANALYSIS
-- ============================================================

SELECT
    p.payment_method,
    COUNT(*) AS payment_count,
    ROUND(SUM(p.amount_paid), 2) AS total_payment_value,
    ROUND(AVG(p.amount_paid), 2) AS average_payment_value,
    ROUND(
        COUNT(*) FILTER (WHERE p.payment_status = 'Success')::NUMERIC
        / NULLIF(COUNT(*), 0) * 100,
        2
    ) AS success_rate,
    ROUND(SUM(p.transaction_fee), 2) AS total_transaction_fees,
    ROUND(SUM(p.refund_amount), 2) AS total_refunds
FROM ecommerce.payments p
GROUP BY p.payment_method
ORDER BY total_payment_value DESC;
-- ============================================================
-- 12. LOSS-MAKING PRODUCTS
-- ============================================================

SELECT
    p.product_id,
    p.product_name,
    p.category,
    SUM(oi.quantity) AS units_sold,
    ROUND(SUM(oi.item_revenue), 2) AS revenue,
    ROUND(SUM(oi.profit), 2) AS profit,
    ROUND(
        SUM(oi.profit) /
        NULLIF(SUM(oi.item_revenue), 0) * 100,
        2
    ) AS profit_margin
FROM ecommerce.products p
JOIN ecommerce.order_items oi
    ON p.product_id = oi.product_id
GROUP BY
    p.product_id,
    p.product_name,
    p.category
HAVING SUM(oi.profit) < 0
ORDER BY profit ASC;


-- ============================================================
-- 13. HIGH REVENUE / LOW MARGIN PRODUCTS
-- ============================================================

SELECT
    p.product_id,
    p.product_name,
    p.category,
    ROUND(SUM(oi.item_revenue), 2) AS revenue,
    ROUND(SUM(oi.profit), 2) AS profit,
    ROUND(
        SUM(oi.profit) /
        NULLIF(SUM(oi.item_revenue), 0) * 100,
        2
    ) AS profit_margin
FROM ecommerce.products p
JOIN ecommerce.order_items oi
    ON p.product_id = oi.product_id
GROUP BY
    p.product_id,
    p.product_name,
    p.category
HAVING SUM(oi.item_revenue) >= 10000000
ORDER BY profit_margin ASC;


-- ============================================================
-- 14. CUSTOMER RETENTION OPPORTUNITY
-- ============================================================

SELECT
    c.customer_status,
    c.customer_segment,
    c.loyalty_tier,
    COUNT(DISTINCT c.customer_id) AS customers,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(COALESCE(SUM(o.final_amount), 0), 2) AS historical_revenue,
    ROUND(
        COALESCE(SUM(o.final_amount), 0) /
        NULLIF(COUNT(DISTINCT c.customer_id), 0),
        2
    ) AS revenue_per_customer
FROM ecommerce.customers c
LEFT JOIN ecommerce.orders o
    ON c.customer_id = o.customer_id
WHERE c.customer_status IN ('At Risk', 'Churned')
GROUP BY
    c.customer_status,
    c.customer_segment,
    c.loyalty_tier
ORDER BY historical_revenue DESC;


-- ============================================================
-- 15. EXECUTIVE BUSINESS SUMMARY
-- ============================================================

WITH order_metrics AS (
    SELECT
        COUNT(DISTINCT order_id) AS total_orders,
        COUNT(DISTINCT customer_id) AS total_customers,
        COALESCE(SUM(final_amount), 0) AS total_revenue,
        COALESCE(AVG(final_amount), 0) AS average_order_value
    FROM ecommerce.orders
),
profit_metrics AS (
    SELECT
        COALESCE(SUM(profit), 0) AS total_profit
    FROM ecommerce.order_items
),
return_metrics AS (
    SELECT
        COUNT(DISTINCT return_id) AS total_returns
    FROM ecommerce.returns
),
shipping_metrics AS (
    SELECT
        COALESCE(AVG(delivery_days), 0) AS average_delivery_days,
        COALESCE(
            COUNT(*) FILTER (WHERE delayed_flag = 1)::NUMERIC
            / NULLIF(COUNT(*), 0),
            0
        ) AS delayed_shipment_rate
    FROM ecommerce.shipments
)
SELECT
    om.total_orders,
    om.total_customers,
    ROUND(om.total_revenue, 2) AS total_revenue,
    ROUND(pm.total_profit, 2) AS total_profit,
    ROUND(om.average_order_value, 2) AS average_order_value,
    ROUND(
        rm.total_returns::NUMERIC
        / NULLIF(om.total_orders, 0) * 100,
        2
    ) AS return_rate_percent,
    ROUND(sm.average_delivery_days, 2) AS average_delivery_days,
    ROUND(sm.delayed_shipment_rate * 100, 2) AS delayed_shipment_rate_percent,
    CASE
        WHEN sm.delayed_shipment_rate >= 0.30
            THEN 'ATTENTION REQUIRED'
        WHEN rm.total_returns::NUMERIC
             / NULLIF(om.total_orders, 0) >= 0.15
            THEN 'ATTENTION REQUIRED'
        ELSE 'HEALTHY'
    END AS business_status
FROM order_metrics om
CROSS JOIN profit_metrics pm
CROSS JOIN return_metrics rm
CROSS JOIN shipping_metrics sm;