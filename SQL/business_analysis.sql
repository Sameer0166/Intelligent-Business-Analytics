-- ============================================================
-- BUSINESS ANALYTICS
-- Intelligent Business Analytics Platform
-- Indian E-Commerce Dataset
-- ============================================================


-- ============================================================
-- 1. EXECUTIVE KPIs
-- ============================================================
-- 1. EXECUTIVE KPIs
-- ============================================================

-- 1.1 Order status distribution
SELECT
    order_status,
    COUNT(*) AS order_count
FROM ecommerce.orders
GROUP BY order_status
ORDER BY order_count DESC;
-- ============================================================
-- 1.2 Overall Sales Performance
-- ============================================================

SELECT
    COUNT(DISTINCT order_id) AS total_orders,
    SUM(subtotal) AS total_subtotal,
    SUM(shipping_fee) AS total_shipping_fee,
    SUM(tax_amount) AS total_tax,
    SUM(discount_percentage) AS total_discount_percentage,
    SUM(final_amount) AS total_revenue,
    ROUND(AVG(final_amount), 2) AS average_order_value
FROM ecommerce.orders;
-- ============================================================
-- 1.3 Revenue by Order Status
-- ============================================================

SELECT
    order_status,
    COUNT(*) AS order_count,
    ROUND(SUM(final_amount), 2) AS total_revenue,
    ROUND(AVG(final_amount), 2) AS average_order_value
FROM ecommerce.orders
GROUP BY order_status
ORDER BY total_revenue DESC;
-- ============================================================


-- ============================================================
-- 2. SALES ANALYSIS
-- ============================================================
-- 2.1 Monthly Sales Trend
-- ============================================================

SELECT
    DATE_TRUNC('month', order_date)::DATE AS sales_month,
    COUNT(*) AS total_orders,
    ROUND(SUM(final_amount), 2) AS total_revenue,
    ROUND(AVG(final_amount), 2) AS average_order_value
FROM ecommerce.orders
GROUP BY DATE_TRUNC('month', order_date)
ORDER BY sales_month;
-- ============================================================
-- 2.2 Sales by Order Status
-- ============================================================

SELECT
    order_status,
    COUNT(*) AS total_orders,
    ROUND(SUM(final_amount), 2) AS total_revenue,
    ROUND(AVG(final_amount), 2) AS average_order_value
FROM ecommerce.orders
GROUP BY order_status
ORDER BY total_revenue DESC;
-- ============================================================
-- 2.3 Revenue by Order Status
-- ============================================================

SELECT
    order_status,
    COUNT(*) AS order_count,
    ROUND(SUM(final_amount), 2) AS total_revenue,
    ROUND(AVG(final_amount), 2) AS average_order_value
FROM ecommerce.orders
GROUP BY order_status
ORDER BY total_revenue DESC;
-- ============================================================
-- 2.4 Sales by Shipping Method
-- ============================================================

SELECT
    shipping_method,
    COUNT(*) AS total_orders,
    ROUND(SUM(final_amount), 2) AS total_revenue,
    ROUND(AVG(final_amount), 2) AS average_order_value
FROM ecommerce.orders
GROUP BY shipping_method
ORDER BY total_revenue DESC;
-- ============================================================
-- 2.5 Daily Sales Performance
-- ============================================================

SELECT
    order_date,
    COUNT(*) AS total_orders,
    ROUND(SUM(final_amount), 2) AS total_revenue,
    ROUND(AVG(final_amount), 2) AS average_order_value
FROM ecommerce.orders
GROUP BY order_date
ORDER BY order_date;
-- ============================================================
-- 2.6 Average Order Value Trend
-- ============================================================

SELECT
    DATE_TRUNC('month', order_date)::DATE AS sales_month,
    COUNT(DISTINCT order_id) AS total_orders,
    ROUND(SUM(final_amount), 2) AS total_revenue,
    ROUND(AVG(final_amount), 2) AS average_order_value
FROM ecommerce.orders
GROUP BY DATE_TRUNC('month', order_date)
ORDER BY sales_month;
-- ============================================================


-- ============================================================
-- 3. PRODUCT ANALYSIS
-- ============================================================
-- 3.1 Product Performance
-- ============================================================

SELECT
    p.product_id,
    p.product_name,
    p.category,
    p.brand,
    COUNT(DISTINCT oi.order_id) AS total_orders,
    SUM(oi.quantity) AS units_sold,
    ROUND(SUM(oi.item_revenue), 2) AS total_revenue,
    ROUND(SUM(oi.profit), 2) AS total_profit,
    ROUND(AVG(oi.unit_price), 2) AS average_unit_price
FROM ecommerce.products p
JOIN ecommerce.order_items oi
    ON p.product_id = oi.product_id
GROUP BY
    p.product_id,
    p.product_name,
    p.category,
    p.brand
ORDER BY total_revenue DESC;
-- ============================================================
-- 3.2 Product Category Performance
-- ============================================================

SELECT
    p.category,
    COUNT(DISTINCT oi.order_id) AS total_orders,
    SUM(oi.quantity) AS units_sold,
    ROUND(SUM(oi.item_revenue), 2) AS total_revenue,
    ROUND(SUM(oi.profit), 2) AS total_profit,
    ROUND(AVG(p.rating_average), 2) AS average_rating
FROM ecommerce.products p
JOIN ecommerce.order_items oi
    ON p.product_id = oi.product_id
GROUP BY p.category
ORDER BY total_revenue DESC;
-- ============================================================
-- 3.3 Product Profitability Analysis
-- ============================================================

SELECT
    p.product_id,
    p.product_name,
    p.category,
    p.brand,
    COUNT(DISTINCT oi.order_id) AS total_orders,
    SUM(oi.quantity) AS units_sold,
    ROUND(SUM(oi.item_revenue), 2) AS total_revenue,
    ROUND(SUM(oi.item_cost), 2) AS total_cost,
    ROUND(SUM(oi.profit), 2) AS total_profit,
    ROUND(
        (SUM(oi.profit) / NULLIF(SUM(oi.item_revenue), 0)) * 100,
        2
    ) AS profit_margin_percentage
FROM ecommerce.products p
JOIN ecommerce.order_items oi
    ON p.product_id = oi.product_id
GROUP BY
    p.product_id,
    p.product_name,
    p.category,
    p.brand
HAVING SUM(oi.item_revenue) > 0
ORDER BY total_profit DESC;
-- ============================================================
-- 3.4 Top Products by Revenue
-- ============================================================

SELECT
    p.product_id,
    p.product_name,
    p.category,
    p.brand,
    SUM(oi.quantity) AS units_sold,
    ROUND(SUM(oi.item_revenue), 2) AS total_revenue,
    ROUND(SUM(oi.profit), 2) AS total_profit
FROM ecommerce.products p
JOIN ecommerce.order_items oi
    ON p.product_id = oi.product_id
GROUP BY
    p.product_id,
    p.product_name,
    p.category,
    p.brand
ORDER BY total_revenue DESC
LIMIT 20;
-- ============================================================
-- 3.5 Top Products by Profit
-- ============================================================

SELECT
    p.product_id,
    p.product_name,
    p.category,
    p.brand,
    SUM(oi.quantity) AS units_sold,
    ROUND(SUM(oi.item_revenue), 2) AS total_revenue,
    ROUND(SUM(oi.profit), 2) AS total_profit,
    ROUND(
        (SUM(oi.profit) / NULLIF(SUM(oi.item_revenue), 0)) * 100,
        2
    ) AS profit_margin_percentage
FROM ecommerce.products p
JOIN ecommerce.order_items oi
    ON p.product_id = oi.product_id
GROUP BY
    p.product_id,
    p.product_name,
    p.category,
    p.brand
HAVING SUM(oi.item_revenue) > 0
ORDER BY total_profit DESC
LIMIT 20;
-- ============================================================


-- ============================================================
-- 4. CUSTOMER ANALYSIS
-- ============================================================
-- 4.1 Customer Performance
-- ============================================================

SELECT
    c.customer_id,
    c.customer_segment,
    c.state,
    c.city,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(o.final_amount), 2) AS total_spend,
    ROUND(AVG(o.final_amount), 2) AS average_order_value,
    MAX(o.order_date) AS last_order_date
FROM ecommerce.customers c
JOIN ecommerce.orders o
    ON c.customer_id = o.customer_id
GROUP BY
    c.customer_id,
    c.customer_segment,
    c.state,
    c.city
ORDER BY total_spend DESC;
-- ============================================================
-- 4.2 Customer Segment Analysis
-- ============================================================

SELECT
    c.customer_segment,
    COUNT(DISTINCT c.customer_id) AS total_customers,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(o.final_amount), 2) AS total_revenue,
    ROUND(AVG(o.final_amount), 2) AS average_order_value
FROM ecommerce.customers c
JOIN ecommerce.orders o
    ON c.customer_id = o.customer_id
GROUP BY c.customer_segment
ORDER BY total_revenue DESC;
-- ============================================================
-- 4.3 Customer Purchase Frequency
-- ============================================================

SELECT
    c.customer_id,
    c.customer_segment,
    COUNT(DISTINCT o.order_id) AS total_orders,
    MIN(o.order_date) AS first_order_date,
    MAX(o.order_date) AS last_order_date,
    ROUND(
        COUNT(DISTINCT o.order_id)::NUMERIC /
        NULLIF(
            (MAX(o.order_date) - MIN(o.order_date)) / 30.0,
            0
        ),
        2
    ) AS orders_per_month
FROM ecommerce.customers c
JOIN ecommerce.orders o
    ON c.customer_id = o.customer_id
GROUP BY
    c.customer_id,
    c.customer_segment
HAVING COUNT(DISTINCT o.order_id) > 1
ORDER BY orders_per_month DESC;
-- ============================================================
-- 4.4 Customer Lifetime Value
-- ============================================================

SELECT
    c.customer_id,
    c.customer_segment,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(o.final_amount), 2) AS lifetime_value,
    ROUND(AVG(o.final_amount), 2) AS average_order_value,
    MIN(o.order_date) AS first_order_date,
    MAX(o.order_date) AS last_order_date
FROM ecommerce.customers c
JOIN ecommerce.orders o
    ON c.customer_id = o.customer_id
GROUP BY
    c.customer_id,
    c.customer_segment
ORDER BY lifetime_value DESC
LIMIT 100;


-- ============================================================


-- ============================================================
-- 5. REGIONAL ANALYSIS
-- ============================================================
-- 5.1 REGIONAL SALES PERFORMANCE
-- ============================================================

SELECT
    delivery_state,
    COUNT(DISTINCT order_id) AS total_orders,
    COUNT(DISTINCT customer_id) AS total_customers,
    ROUND(SUM(final_amount), 2) AS total_revenue,
    ROUND(AVG(final_amount), 2) AS average_order_value
FROM ecommerce.orders
WHERE delivery_state IS NOT NULL
GROUP BY delivery_state
ORDER BY total_revenue DESC;
-- ============================================================
-- 5.2 REGIONAL PROFITABILITY
-- ============================================================

SELECT
    o.delivery_state,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(oi.item_revenue), 2) AS total_revenue,
    ROUND(SUM(oi.profit), 2) AS total_profit,
    ROUND(
        (SUM(oi.profit) / NULLIF(SUM(oi.item_revenue), 0)) * 100,
        2
    ) AS profit_margin_percentage
FROM ecommerce.orders o
JOIN ecommerce.order_items oi
    ON o.order_id = oi.order_id
WHERE o.delivery_state IS NOT NULL
GROUP BY o.delivery_state
ORDER BY total_profit DESC;
-- ============================================================
-- 5.3 REGIONAL CUSTOMER PERFORMANCE
-- ============================================================

SELECT
    c.state,
    COUNT(DISTINCT c.customer_id) AS total_customers,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(o.final_amount), 2) AS total_revenue,
    ROUND(AVG(o.final_amount), 2) AS average_order_value
FROM ecommerce.customers c
JOIN ecommerce.orders o
    ON c.customer_id = o.customer_id
WHERE c.state IS NOT NULL
GROUP BY c.state
ORDER BY total_revenue DESC;

-- ============================================================


-- ============================================================
-- 6. RETURNS ANALYSIS
-- 6.1 RETURN OVERVIEW
-- ============================================================

SELECT
    COUNT(DISTINCT r.return_id) AS total_returns,
    COUNT(DISTINCT r.order_id) AS returned_orders,
    COUNT(DISTINCT r.customer_id) AS customers_with_returns,
    ROUND(SUM(r.refund_amount), 2) AS total_refund_amount,
    ROUND(AVG(r.refund_amount), 2) AS average_refund_amount
FROM ecommerce.returns r;
-- ============================================================
-- 6.2 RETURN REASONS ANALYSIS
-- ============================================================

SELECT
    r.return_reason,
    COUNT(*) AS total_returns,
    ROUND(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (),
        2
    ) AS return_percentage,
    ROUND(SUM(r.refund_amount), 2) AS total_refund_amount,
    ROUND(AVG(r.refund_amount), 2) AS average_refund_amount
FROM ecommerce.returns r
GROUP BY r.return_reason
ORDER BY total_returns DESC;
-- ============================================================
-- 6.3 RETURN STATUS ANALYSIS
-- ============================================================

SELECT
    return_status,
    COUNT(*) AS total_returns,
    ROUND(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (),
        2
    ) AS return_percentage,
    ROUND(SUM(refund_amount), 2) AS total_refund_amount,
    ROUND(AVG(refund_amount), 2) AS average_refund_amount
FROM ecommerce.returns
GROUP BY return_status
ORDER BY total_returns DESC;
-- ============================================================
-- 6.4 RETURN PRODUCT ANALYSIS
-- ============================================================

SELECT
    p.product_id,
    p.product_name,
    p.category,
    COUNT(*) AS total_returns,
    ROUND(SUM(r.refund_amount), 2) AS total_refund_amount,
    ROUND(AVG(r.refund_amount), 2) AS average_refund_amount
FROM ecommerce.returns r
JOIN ecommerce.products p
    ON r.product_id = p.product_id
GROUP BY
    p.product_id,
    p.product_name,
    p.category
ORDER BY
    total_returns DESC
LIMIT 20;
-- ============================================================
-- 6.5 RETURN CUSTOMER ANALYSIS
-- ============================================================

SELECT
    r.customer_id,
    c.customer_segment,
    COUNT(*) AS total_returns,
    ROUND(SUM(r.refund_amount), 2) AS total_refund_amount,
    ROUND(AVG(r.refund_amount), 2) AS average_refund_amount
FROM ecommerce.returns r
JOIN ecommerce.customers c
    ON r.customer_id = c.customer_id
GROUP BY
    r.customer_id,
    c.customer_segment
ORDER BY
    total_returns DESC
LIMIT 20;
-- ============================================================
-- 6.6 RETURN CATEGORY ANALYSIS
-- ============================================================

SELECT
    p.category,
    COUNT(*) AS total_returns,
    ROUND(SUM(r.refund_amount), 2) AS total_refund_amount,
    ROUND(AVG(r.refund_amount), 2) AS average_refund_amount
FROM ecommerce.returns r
JOIN ecommerce.products p
    ON r.product_id = p.product_id
GROUP BY
    p.category
ORDER BY
    total_returns DESC;
-- ============================================================
-- 6.7 RETURN RATE BY CATEGORY
WITH category_orders AS (
    SELECT
        p.category,
        COUNT(DISTINCT oi.order_id) AS total_orders
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
    co.category,
    co.total_orders,
    COALESCE(cr.total_returns, 0) AS total_returns,
    ROUND(
        COALESCE(cr.total_returns, 0) * 100.0
        / NULLIF(co.total_orders, 0),
        2
    ) AS return_rate_percentage

FROM category_orders co
LEFT JOIN category_returns cr
    ON co.category = cr.category

ORDER BY return_rate_percentage DESC;
-- ============================================================


-- ============================================================
-- 7. SHIPPING ANALYSIS
-- ============================================================
-- 7.1 SHIPPING OVERVIEW
-- ============================================================

SELECT
    COUNT(*) AS total_shipments,

    COUNT(*) FILTER (
        WHERE actual_delivery_date IS NOT NULL
    ) AS completed_shipments,

    ROUND(
        AVG(delivery_days),
        2
    ) AS average_delivery_days,

    COUNT(*) FILTER (
        WHERE delayed_flag = 1
    ) AS delayed_shipments,

    ROUND(
        COUNT(*) FILTER (WHERE delayed_flag = 1) * 100.0
        / NULLIF(COUNT(*), 0),
        2
    ) AS delay_percentage

FROM ecommerce.shipments;
-- ============================================================
-- 7.2 DELIVERY PERFORMANCE BY STATUS
-- ============================================================

SELECT
    delivery_status,

    COUNT(*) AS total_shipments,

    ROUND(
        COUNT(*) * 100.0 /
        NULLIF(SUM(COUNT(*)) OVER (), 0),
        2
    ) AS shipment_percentage,

    ROUND(
        AVG(delivery_days),
        2
    ) AS average_delivery_days

FROM ecommerce.shipments

GROUP BY delivery_status

ORDER BY total_shipments DESC;
-- ============================================================
-- 7.3 DELAY RATE BY SHIPPING METHOD
-- ============================================================

SELECT
    shipping_method,

    COUNT(*) AS total_shipments,

    COUNT(*) FILTER (
        WHERE delayed_flag = 1
    ) AS delayed_shipments,

    ROUND(
        COUNT(*) FILTER (WHERE delayed_flag = 1) * 100.0
        / NULLIF(COUNT(*), 0),
        2
    ) AS delay_rate_percentage,

    ROUND(
        AVG(delivery_days),
        2
    ) AS average_delivery_days

FROM ecommerce.shipments

GROUP BY shipping_method

ORDER BY delay_rate_percentage DESC;
-- ============================================================
-- 7.4 WAREHOUSE PERFORMANCE
-- ============================================================

SELECT
    warehouse_city,

    COUNT(*) AS total_shipments,

    COUNT(*) FILTER (
        WHERE delayed_flag = 1
    ) AS delayed_shipments,

    ROUND(
        COUNT(*) FILTER (WHERE delayed_flag = 1) * 100.0
        / NULLIF(COUNT(*), 0),
        2
    ) AS delay_rate_percentage,

    ROUND(
        AVG(delivery_days),
        2
    ) AS average_delivery_days

FROM ecommerce.shipments

GROUP BY warehouse_city

ORDER BY delay_rate_percentage DESC;
-- ============================================================
-- 7.5 DELIVERY PERFORMANCE BY STATE
-- ============================================================

SELECT
    o.delivery_state,

    COUNT(s.shipment_id) AS total_shipments,

    ROUND(
        AVG(s.delivery_days),
        2
    ) AS average_delivery_days,

    COUNT(*) FILTER (
        WHERE s.delayed_flag = 1
    ) AS delayed_shipments,

    ROUND(
        COUNT(*) FILTER (WHERE s.delayed_flag = 1) * 100.0
        / NULLIF(COUNT(s.shipment_id), 0),
        2
    ) AS delay_rate_percentage

FROM ecommerce.shipments s

JOIN ecommerce.orders o
    ON s.order_id = o.order_id

GROUP BY o.delivery_state

ORDER BY average_delivery_days DESC;
-- ============================================================
-- 7.6 TOP 10 SLOWEST DELIVERY CITIES
-- ============================================================

SELECT
    delivery_city,

    COUNT(*) AS total_shipments,

    ROUND(
        AVG(delivery_days),
        2
    ) AS average_delivery_days,

    COUNT(*) FILTER (
        WHERE delayed_flag = 1
    ) AS delayed_shipments,

    ROUND(
        COUNT(*) FILTER (WHERE delayed_flag = 1) * 100.0
        / NULLIF(COUNT(*), 0),
        2
    ) AS delay_rate_percentage

FROM ecommerce.shipments

GROUP BY delivery_city

HAVING COUNT(*) >= 50

ORDER BY average_delivery_days DESC

LIMIT 10;
-- ============================================================


-- ============================================================
-- 8. MARKETING ANALYSIS
-- ============================================================
-- 8.1 MARKETING CAMPAIGN OVERVIEW
-- ============================================================

SELECT
    COUNT(*) AS total_campaigns,

    SUM(impressions) AS total_impressions,

    SUM(clicks) AS total_clicks,

    SUM(conversions) AS total_conversions,

    ROUND(SUM(campaign_cost), 2) AS total_campaign_cost,

    ROUND(SUM(revenue_generated), 2) AS total_revenue_generated,

    ROUND(
        SUM(revenue_generated) / NULLIF(SUM(campaign_cost), 0),
        2
    ) AS overall_revenue_to_cost_ratio

FROM ecommerce.marketing_campaigns;
-- ============================================================
-- 8.2 CAMPAIGN PERFORMANCE ANALYSIS
-- ============================================================

SELECT
    campaign_id,
    campaign_name,
    channel,
    campaign_type,
    target_segment,

    impressions,
    clicks,
    conversions,

    ROUND(campaign_cost, 2) AS campaign_cost,

    ROUND(revenue_generated, 2) AS revenue_generated,

    ROUND(
        revenue_generated / NULLIF(campaign_cost, 0),
        2
    ) AS revenue_to_cost_ratio

FROM ecommerce.marketing_campaigns

ORDER BY revenue_generated DESC;
-- ============================================================
-- 8.3 CAMPAIGN ROI ANALYSIS
-- ROI = (Revenue - Cost) / Cost × 100
-- ============================================================

SELECT
    campaign_id,
    campaign_name,
    channel,

    ROUND(campaign_cost, 2) AS campaign_cost,

    ROUND(revenue_generated, 2) AS revenue_generated,

    ROUND(
        (
            (revenue_generated - campaign_cost)
            / NULLIF(campaign_cost, 0)
        ) * 100,
        2
    ) AS roi_percentage

FROM ecommerce.marketing_campaigns

WHERE campaign_cost > 0

ORDER BY roi_percentage DESC;
-- ============================================================
-- 8.4 MARKETING CHANNEL PERFORMANCE
-- ============================================================

SELECT
    channel,

    COUNT(*) AS total_campaigns,

    SUM(impressions) AS total_impressions,

    SUM(clicks) AS total_clicks,

    SUM(conversions) AS total_conversions,

    ROUND(SUM(campaign_cost), 2) AS total_campaign_cost,

    ROUND(SUM(revenue_generated), 2) AS total_revenue_generated,

    ROUND(
        SUM(revenue_generated) / NULLIF(SUM(campaign_cost), 0),
        2
    ) AS revenue_to_cost_ratio

FROM ecommerce.marketing_campaigns

GROUP BY channel

ORDER BY total_revenue_generated DESC;
-- ============================================================
-- 8.5 CAMPAIGN CONVERSION ANALYSIS
-- Conversion Rate = Conversions / Clicks × 100
-- ============================================================

SELECT
    campaign_id,
    campaign_name,
    channel,

    impressions,
    clicks,
    conversions,

    ROUND(
        clicks * 100.0 /
        NULLIF(impressions, 0),
        2
    ) AS click_through_rate_percentage,

    ROUND(
        conversions * 100.0 /
        NULLIF(clicks, 0),
        2
    ) AS conversion_rate_percentage

FROM ecommerce.marketing_campaigns

ORDER BY conversion_rate_percentage DESC;
-- ============================================================
-- 8.6 CAMPAIGN TYPE & TARGET SEGMENT ANALYSIS
-- ============================================================

SELECT
    campaign_type,
    target_segment,

    COUNT(*) AS total_campaigns,

    SUM(impressions) AS total_impressions,

    SUM(clicks) AS total_clicks,

    SUM(conversions) AS total_conversions,

    ROUND(SUM(campaign_cost), 2) AS total_campaign_cost,

    ROUND(SUM(revenue_generated), 2) AS total_revenue_generated,

    ROUND(
        SUM(revenue_generated) /
        NULLIF(SUM(campaign_cost), 0),
        2
    ) AS revenue_to_cost_ratio

FROM ecommerce.marketing_campaigns

GROUP BY
    campaign_type,
    target_segment

ORDER BY total_revenue_generated DESC;
-- ============================================================


-- ============================================================
-- 9. PAYMENT ANALYSIS
-- ============================================================
-- 9.1 PAYMENT OVERVIEW
-- ============================================================

SELECT
    COUNT(*) AS total_payments,

    COUNT(DISTINCT order_id) AS unique_orders,

    ROUND(SUM(amount_paid), 2) AS total_amount_paid,

    ROUND(AVG(amount_paid), 2) AS average_payment_amount,

    ROUND(SUM(refund_amount), 2) AS total_refund_amount,

    ROUND(SUM(transaction_fee), 2) AS total_transaction_fees

FROM ecommerce.payments;
-- ============================================================
-- 9.2 PAYMENT METHOD ANALYSIS
-- ============================================================

SELECT
    payment_method,

    COUNT(*) AS total_transactions,

    COUNT(DISTINCT order_id) AS unique_orders,

    ROUND(SUM(amount_paid), 2) AS total_amount_paid,

    ROUND(AVG(amount_paid), 2) AS average_payment_amount,

    ROUND(SUM(refund_amount), 2) AS total_refund_amount,

    ROUND(SUM(transaction_fee), 2) AS total_transaction_fees

FROM ecommerce.payments

GROUP BY payment_method

ORDER BY total_amount_paid DESC;
-- ============================================================
-- 9.3 PAYMENT STATUS ANALYSIS
-- ============================================================

SELECT
    payment_status,

    COUNT(*) AS total_transactions,

    ROUND(
        COUNT(*) * 100.0 /
        NULLIF(SUM(COUNT(*)) OVER (), 0),
        2
    ) AS transaction_percentage,

    ROUND(SUM(amount_paid), 2) AS total_amount_paid,

    ROUND(AVG(amount_paid), 2) AS average_payment_amount,

    ROUND(SUM(refund_amount), 2) AS total_refund_amount

FROM ecommerce.payments

GROUP BY payment_status

ORDER BY total_transactions DESC;
-- ============================================================
-- 9.4 PAYMENT AMOUNT ANALYSIS
-- ============================================================

SELECT
    payment_method,

    COUNT(*) AS total_transactions,

    ROUND(MIN(amount_paid), 2) AS minimum_payment,

    ROUND(MAX(amount_paid), 2) AS maximum_payment,

    ROUND(AVG(amount_paid), 2) AS average_payment,

    ROUND(
        PERCENTILE_CONT(0.50)
        WITHIN GROUP (ORDER BY amount_paid)::NUMERIC,
        2
    ) AS median_payment,

    ROUND(SUM(amount_paid), 2) AS total_amount_paid

FROM ecommerce.payments

GROUP BY payment_method

ORDER BY total_amount_paid DESC;
-- ============================================================
-- 9.5 REFUND ANALYSIS
-- ============================================================

SELECT
    payment_method,

    COUNT(*) FILTER (
        WHERE refund_amount > 0
    ) AS refunded_transactions,

    ROUND(SUM(refund_amount), 2) AS total_refund_amount,

    ROUND(AVG(
        NULLIF(refund_amount, 0)
    ), 2) AS average_refund_amount,

    ROUND(
        COUNT(*) FILTER (
            WHERE refund_amount > 0
        ) * 100.0 /
        NULLIF(COUNT(*), 0),
        2
    ) AS refund_transaction_percentage

FROM ecommerce.payments

GROUP BY payment_method

ORDER BY total_refund_amount DESC;
-- ============================================================
-- 9.6 TRANSACTION FEE ANALYSIS
-- ============================================================

SELECT
    payment_method,

    COUNT(*) AS total_transactions,

    ROUND(SUM(amount_paid), 2) AS total_amount_processed,

    ROUND(SUM(transaction_fee), 2) AS total_transaction_fees,

    ROUND(AVG(transaction_fee), 2) AS average_transaction_fee,

    ROUND(
        SUM(transaction_fee) * 100.0 /
        NULLIF(SUM(amount_paid), 0),
        2
    ) AS transaction_fee_percentage

FROM ecommerce.payments

GROUP BY payment_method

ORDER BY total_transaction_fees DESC;
-- ============================================================


-- ============================================================
-- 10. ADVANCED ANALYSIS
-- ============================================================
-- 10.1 CUSTOMER VALUE ANALYSIS
-- ============================================================

SELECT
    customer_id,
    customer_segment,
    customer_status,
    loyalty_tier,

    total_orders,

    ROUND(total_spend, 2) AS total_spend,

    ROUND(average_order_value, 2) AS average_order_value,

    last_order_date

FROM ecommerce.customers

ORDER BY total_spend DESC

LIMIT 20;
-- ============================================================
-- 10.2 CUSTOMER STATUS & LOYALTY ANALYSIS
-- ============================================================

SELECT
    customer_status,
    loyalty_tier,

    COUNT(*) AS total_customers,

    ROUND(AVG(total_orders), 2) AS average_orders,

    ROUND(AVG(total_spend), 2) AS average_customer_spend,

    ROUND(AVG(average_order_value), 2) AS average_order_value

FROM ecommerce.customers

GROUP BY
    customer_status,
    loyalty_tier

ORDER BY
    average_customer_spend DESC;
-- ============================================================
-- 10.3 CUSTOMER ACQUISITION CHANNEL ANALYSIS
-- ============================================================

SELECT
    acquisition_channel,

    COUNT(*) AS total_customers,

    ROUND(AVG(total_orders), 2) AS average_orders_per_customer,

    ROUND(AVG(total_spend), 2) AS average_customer_spend,

    ROUND(SUM(total_spend), 2) AS total_customer_spend,

    ROUND(AVG(average_order_value), 2) AS average_order_value

FROM ecommerce.customers

GROUP BY acquisition_channel

ORDER BY total_customer_spend DESC;
-- ============================================================
-- 10.4 REVIEW RATING & SENTIMENT ANALYSIS
-- ============================================================

SELECT
    rating,
    review_sentiment,

    COUNT(*) AS total_reviews,

    ROUND(
        COUNT(*) * 100.0 /
        NULLIF(SUM(COUNT(*)) OVER (), 0),
        2
    ) AS review_percentage

FROM ecommerce.customer_reviews

GROUP BY
    rating,
    review_sentiment

ORDER BY
    rating DESC,
    total_reviews DESC;
-- ============================================================
-- 10.5 DISCOUNT VS PROFIT ANALYSIS
-- ============================================================

SELECT
    CASE
        WHEN discount_percentage = 0 THEN 'No Discount'
        WHEN discount_percentage <= 10 THEN '1-10%'
        WHEN discount_percentage <= 20 THEN '11-20%'
        WHEN discount_percentage <= 30 THEN '21-30%'
        ELSE 'Above 30%'
    END AS discount_range,

    COUNT(*) AS total_order_items,

    ROUND(AVG(discount_percentage), 2) AS average_discount,

    ROUND(SUM(item_revenue), 2) AS total_revenue,

    ROUND(SUM(item_cost), 2) AS total_cost,

    ROUND(SUM(profit), 2) AS total_profit,

    ROUND(AVG(profit), 2) AS average_profit

FROM ecommerce.order_items

GROUP BY
    CASE
        WHEN discount_percentage = 0 THEN 'No Discount'
        WHEN discount_percentage <= 10 THEN '1-10%'
        WHEN discount_percentage <= 20 THEN '11-20%'
        WHEN discount_percentage <= 30 THEN '21-30%'
        ELSE 'Above 30%'
    END

ORDER BY
    average_discount;
-- ============================================================
-- 10.6 BUSINESS PERFORMANCE SUMMARY
-- ============================================================

SELECT
    (SELECT COUNT(*)
     FROM ecommerce.customers) AS total_customers,

    (SELECT COUNT(*)
     FROM ecommerce.orders) AS total_orders,

    (SELECT ROUND(SUM(final_amount), 2)
     FROM ecommerce.orders) AS total_sales,

    (SELECT ROUND(SUM(profit), 2)
     FROM ecommerce.order_items) AS total_profit,

    (SELECT COUNT(*)
     FROM ecommerce.returns) AS total_returns,

    (SELECT COUNT(*)
     FROM ecommerce.shipments
     WHERE delayed_flag = 1) AS delayed_shipments,

    (SELECT ROUND(SUM(refund_amount), 2)
     FROM ecommerce.payments) AS total_refunds,

    (SELECT ROUND(SUM(campaign_cost), 2)
     FROM ecommerce.marketing_campaigns) AS total_marketing_cost,

    (SELECT ROUND(SUM(revenue_generated), 2)
     FROM ecommerce.marketing_campaigns) AS marketing_revenue;
-- ============================================================