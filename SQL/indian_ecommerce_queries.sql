-- Create a dedicated schema for the e-commerce project
CREATE SCHEMA IF NOT EXISTS ecommerce;

-- =========================================================
-- 1. CUSTOMERS
-- =========================================================

CREATE TABLE ecommerce.customers (
    customer_id VARCHAR(30) PRIMARY KEY,
    customer_signup_date DATE,
    gender VARCHAR(20),
    age SMALLINT,
    age_group VARCHAR(30),
    state VARCHAR(100),
    city VARCHAR(100),
    pincode_prefix INTEGER,
    customer_segment VARCHAR(50),
    preferred_device VARCHAR(30),
    preferred_payment_method VARCHAR(50),
    acquisition_channel VARCHAR(50),
    total_orders INTEGER,
    total_spend NUMERIC(14,2),
    last_order_date DATE,
    average_order_value NUMERIC(14,2),
    customer_status VARCHAR(30),
    loyalty_tier VARCHAR(30)
);


-- =========================================================
-- 2. PRODUCTS
-- =========================================================

CREATE TABLE ecommerce.products (
    product_id VARCHAR(30) PRIMARY KEY,
    product_name VARCHAR(255),
    category VARCHAR(100),
    subcategory VARCHAR(100),
    brand VARCHAR(100),
    price NUMERIC(12,2),
    cost_price NUMERIC(12,2),
    discount_range VARCHAR(50),
    rating_average NUMERIC(4,2),
    rating_count INTEGER,
    stock_quantity INTEGER,
    product_launch_date DATE,
    product_type VARCHAR(100),
    return_rate_baseline NUMERIC(6,4)
);


-- =========================================================
-- 3. MARKETING CAMPAIGNS
-- =========================================================

CREATE TABLE ecommerce.marketing_campaigns (
    campaign_id VARCHAR(30) PRIMARY KEY,
    campaign_name VARCHAR(255),
    channel VARCHAR(100),
    campaign_start_date DATE,
    campaign_end_date DATE,
    campaign_type VARCHAR(100),
    target_segment VARCHAR(50),
    discount_percentage NUMERIC(5,2),
    conversions INTEGER,
    revenue_generated NUMERIC(14,2),
    impressions INTEGER,
    clicks INTEGER,
    campaign_cost NUMERIC(14,2),
    roi NUMERIC(10,4)
);


-- =========================================================
-- 4. ORDERS
-- =========================================================

CREATE TABLE ecommerce.orders (
    order_id VARCHAR(30) PRIMARY KEY,
    customer_id VARCHAR(30) NOT NULL,
    order_date DATE,
    order_time TIME,
    order_status VARCHAR(30),
    shipping_method VARCHAR(50),
    delivery_city VARCHAR(100),
    delivery_state VARCHAR(100),
    coupon_code VARCHAR(100),
    discount_percentage NUMERIC(5,2),
    marketing_channel VARCHAR(100),
    subtotal NUMERIC(14,2),
    shipping_fee NUMERIC(12,2),
    tax_amount NUMERIC(12,2),
    final_amount NUMERIC(14,2),
    campaign_id VARCHAR(30),

    CONSTRAINT fk_orders_customer
        FOREIGN KEY (customer_id)
        REFERENCES ecommerce.customers(customer_id),

    CONSTRAINT fk_orders_campaign
        FOREIGN KEY (campaign_id)
        REFERENCES ecommerce.marketing_campaigns(campaign_id)
);


-- =========================================================
-- 5. ORDER ITEMS
-- =========================================================

CREATE TABLE ecommerce.order_items (
    order_item_id VARCHAR(30) PRIMARY KEY,
    order_id VARCHAR(30) NOT NULL,
    product_id VARCHAR(30) NOT NULL,
    quantity INTEGER,
    unit_price NUMERIC(12,2),
    discount_percentage NUMERIC(5,2),
    item_revenue NUMERIC(14,2),
    item_cost NUMERIC(14,2),
    profit NUMERIC(14,2),

    CONSTRAINT fk_order_items_order
        FOREIGN KEY (order_id)
        REFERENCES ecommerce.orders(order_id),

    CONSTRAINT fk_order_items_product
        FOREIGN KEY (product_id)
        REFERENCES ecommerce.products(product_id)
);


-- =========================================================
-- 6. PAYMENTS
-- =========================================================

CREATE TABLE ecommerce.payments (
    payment_id VARCHAR(30) PRIMARY KEY,
    order_id VARCHAR(30) NOT NULL,
    payment_date DATE,
    payment_method VARCHAR(50),
    payment_status VARCHAR(30),
    amount_paid NUMERIC(14,2),
    transaction_fee NUMERIC(12,2),
    refund_amount NUMERIC(14,2),

    CONSTRAINT fk_payments_order
        FOREIGN KEY (order_id)
        REFERENCES ecommerce.orders(order_id)
);


-- =========================================================
-- 7. SHIPMENTS
-- =========================================================

CREATE TABLE ecommerce.shipments (
    shipment_id VARCHAR(30) PRIMARY KEY,
    order_id VARCHAR(30) NOT NULL,
    warehouse_city VARCHAR(100),
    delivery_city VARCHAR(100),
    shipping_method VARCHAR(50),
    dispatch_date DATE,
    expected_delivery_date DATE,
    actual_delivery_date DATE,
    delivery_days NUMERIC(8,2),
    delivery_status VARCHAR(30),
    delayed_flag INTEGER,

    CONSTRAINT fk_shipments_order
        FOREIGN KEY (order_id)
        REFERENCES ecommerce.orders(order_id)
);


-- =========================================================
-- 8. RETURNS
-- =========================================================

CREATE TABLE ecommerce.returns (
    return_id VARCHAR(30) PRIMARY KEY,
    order_id VARCHAR(30) NOT NULL,
    customer_id VARCHAR(30) NOT NULL,
    product_id VARCHAR(30) NOT NULL,
    return_date DATE,
    return_reason VARCHAR(255),
    refund_amount NUMERIC(14,2),
    return_status VARCHAR(30),

    CONSTRAINT fk_returns_order
        FOREIGN KEY (order_id)
        REFERENCES ecommerce.orders(order_id),

    CONSTRAINT fk_returns_customer
        FOREIGN KEY (customer_id)
        REFERENCES ecommerce.customers(customer_id),

    CONSTRAINT fk_returns_product
        FOREIGN KEY (product_id)
        REFERENCES ecommerce.products(product_id)
);


-- =========================================================
-- 9. CUSTOMER REVIEWS
-- =========================================================

CREATE TABLE ecommerce.customer_reviews (
    review_id VARCHAR(30) PRIMARY KEY,
    order_id VARCHAR(30) NOT NULL,
    customer_id VARCHAR(30) NOT NULL,
    product_id VARCHAR(30) NOT NULL,
    review_date DATE,
    rating SMALLINT,
    review_sentiment VARCHAR(30),
    verified_purchase BOOLEAN,

    CONSTRAINT fk_reviews_order
        FOREIGN KEY (order_id)
        REFERENCES ecommerce.orders(order_id),

    CONSTRAINT fk_reviews_customer
        FOREIGN KEY (customer_id)
        REFERENCES ecommerce.customers(customer_id),

    CONSTRAINT fk_reviews_product
        FOREIGN KEY (product_id)
        REFERENCES ecommerce.products(product_id)
);



-- Orders
CREATE INDEX idx_orders_customer_id
ON ecommerce.orders(customer_id);

CREATE INDEX idx_orders_order_date
ON ecommerce.orders(order_date);

CREATE INDEX idx_orders_campaign_id
ON ecommerce.orders(campaign_id);


-- Order Items
CREATE INDEX idx_order_items_order_id
ON ecommerce.order_items(order_id);

CREATE INDEX idx_order_items_product_id
ON ecommerce.order_items(product_id);


-- Payments
CREATE INDEX idx_payments_order_id
ON ecommerce.payments(order_id);

CREATE INDEX idx_payments_payment_date
ON ecommerce.payments(payment_date);


-- Shipments
CREATE INDEX idx_shipments_order_id
ON ecommerce.shipments(order_id);

CREATE INDEX idx_shipments_dispatch_date
ON ecommerce.shipments(dispatch_date);


-- Returns
CREATE INDEX idx_returns_order_id
ON ecommerce.returns(order_id);

CREATE INDEX idx_returns_customer_id
ON ecommerce.returns(customer_id);

CREATE INDEX idx_returns_product_id
ON ecommerce.returns(product_id);


-- Reviews
CREATE INDEX idx_reviews_order_id
ON ecommerce.customer_reviews(order_id);

CREATE INDEX idx_reviews_customer_id
ON ecommerce.customer_reviews(customer_id);

CREATE INDEX idx_reviews_product_id
ON ecommerce.customer_reviews(product_id);

CREATE INDEX idx_reviews_date
ON ecommerce.customer_reviews(review_date);


select *from ecommerce.customers where customer_id='CUST103868'

select count(*) as customer_count from ecommerce.customer

truncate table ecommerce.customers;

SELECT COUNT(*) AS customer_count
FROM ecommerce.customers;

SELECT COUNT(*) AS order_count
FROM ecommerce.orders;


ALTER TABLE ecommerce.customers
ALTER COLUMN age TYPE NUMERIC(5,2)
USING age::NUMERIC(5,2);
SELECT COUNT(*) AS customer_count
FROM ecommerce.customers;

SELECT column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'ecommerce'
  AND table_name = 'customers'
  AND column_name = 'age';

  SELECT COUNT(*) AS customer_count
FROM ecommerce.customers;

SELECT COUNT(*) AS review_count
FROM ecommerce.customer_reviews;



-- ============================================
-- 1. ROW COUNT VALIDATION
-- ============================================

SELECT 'customers' AS table_name, COUNT(*) AS row_count
FROM ecommerce.customers

UNION ALL
SELECT 'products', COUNT(*)
FROM ecommerce.products

UNION ALL
SELECT 'marketing_campaigns', COUNT(*)
FROM ecommerce.marketing_campaigns

UNION ALL
SELECT 'orders', COUNT(*)
FROM ecommerce.orders

UNION ALL
SELECT 'order_items', COUNT(*)
FROM ecommerce.order_items

UNION ALL
SELECT 'payments', COUNT(*)
FROM ecommerce.payments

UNION ALL
SELECT 'shipments', COUNT(*)
FROM ecommerce.shipments

UNION ALL
SELECT 'returns', COUNT(*)
FROM ecommerce.returns

UNION ALL
SELECT 'customer_reviews', COUNT(*)
FROM ecommerce.customer_reviews

ORDER BY table_name;




SELECT
    'orders → customers' AS relationship,
    COUNT(*) AS orphan_rows
FROM ecommerce.orders o
LEFT JOIN ecommerce.customers c
    ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL

UNION ALL

SELECT
    'orders → campaigns',
    COUNT(*)
FROM ecommerce.orders o
LEFT JOIN ecommerce.marketing_campaigns m
    ON o.campaign_id = m.campaign_id
WHERE o.campaign_id IS NOT NULL
  AND m.campaign_id IS NULL

UNION ALL

SELECT
    'order_items → orders',
    COUNT(*)
FROM ecommerce.order_items oi
LEFT JOIN ecommerce.orders o
    ON oi.order_id = o.order_id
WHERE o.order_id IS NULL

UNION ALL

SELECT
    'order_items → products',
    COUNT(*)
FROM ecommerce.order_items oi
LEFT JOIN ecommerce.products p
    ON oi.product_id = p.product_id
WHERE p.product_id IS NULL

UNION ALL

SELECT
    'payments → orders',
    COUNT(*)
FROM ecommerce.payments p
LEFT JOIN ecommerce.orders o
    ON p.order_id = o.order_id
WHERE o.order_id IS NULL

UNION ALL

SELECT
    'shipments → orders',
    COUNT(*)
FROM ecommerce.shipments s
LEFT JOIN ecommerce.orders o
    ON s.order_id = o.order_id
WHERE o.order_id IS NULL

UNION ALL

SELECT
    'returns → orders',
    COUNT(*)
FROM ecommerce.returns r
LEFT JOIN ecommerce.orders o
    ON r.order_id = o.order_id
WHERE o.order_id IS NULL

UNION ALL

SELECT
    'returns → customers',
    COUNT(*)
FROM ecommerce.returns r
LEFT JOIN ecommerce.customers c
    ON r.customer_id = c.customer_id
WHERE c.customer_id IS NULL

UNION ALL

SELECT
    'returns → products',
    COUNT(*)
FROM ecommerce.returns r
LEFT JOIN ecommerce.products p
    ON r.product_id = p.product_id
WHERE p.product_id IS NULL

UNION ALL

SELECT
    'reviews → orders',
    COUNT(*)
FROM ecommerce.customer_reviews cr
LEFT JOIN ecommerce.orders o
    ON cr.order_id = o.order_id
WHERE o.order_id IS NULL

UNION ALL

SELECT
    'reviews → customers',
    COUNT(*)
FROM ecommerce.customer_reviews cr
LEFT JOIN ecommerce.customers c
    ON cr.customer_id = c.customer_id
WHERE c.customer_id IS NULL

UNION ALL

SELECT
    'reviews → products',
    COUNT(*)
FROM ecommerce.customer_reviews cr
LEFT JOIN ecommerce.products p
    ON cr.product_id = p.product_id
WHERE p.product_id IS NULL;



SELECT
    COUNT(*) AS total_customers,
    COUNT(*) FILTER (WHERE customer_id IS NULL) AS missing_customer_id,
    COUNT(*) FILTER (WHERE customer_signup_date IS NULL) AS missing_signup_date,
    COUNT(*) FILTER (WHERE gender IS NULL) AS missing_gender,
    COUNT(*) FILTER (WHERE age IS NULL) AS missing_age,
    COUNT(*) FILTER (WHERE state IS NULL) AS missing_state,
    COUNT(*) FILTER (WHERE city IS NULL) AS missing_city,
    COUNT(*) FILTER (WHERE customer_segment IS NULL) AS missing_segment,
    COUNT(*) FILTER (WHERE preferred_device IS NULL) AS missing_device,
    COUNT(*) FILTER (WHERE preferred_payment_method IS NULL) AS missing_payment,
    COUNT(*) FILTER (WHERE acquisition_channel IS NULL) AS missing_acquisition_channel,
    COUNT(*) FILTER (WHERE total_orders IS NULL) AS missing_total_orders,
    COUNT(*) FILTER (WHERE total_spend IS NULL) AS missing_total_spend,
    COUNT(*) FILTER (WHERE last_order_date IS NULL) AS missing_last_order_date,
    COUNT(*) FILTER (WHERE average_order_value IS NULL) AS missing_aov,
    COUNT(*) FILTER (WHERE customer_status IS NULL) AS missing_status,
    COUNT(*) FILTER (WHERE loyalty_tier IS NULL) AS missing_loyalty_tier
FROM ecommerce.customers;

SELECT
    COUNT(*) AS missing_age_customers,
    COUNT(*) FILTER (WHERE total_orders = 0) AS no_order_customers,
    COUNT(*) FILTER (WHERE total_orders > 0) AS ordered_customers
FROM ecommerce.customers
WHERE age IS NULL;

SELECT
    COUNT(*) AS missing_age_customers,
    COUNT(*) FILTER (
        WHERE customer_status = 'Active'
    ) AS active_customers,
    COUNT(*) FILTER (
        WHERE customer_status = 'Inactive'
    ) AS inactive_customers,
    COUNT(*) FILTER (
        WHERE total_spend > 0
    ) AS customers_with_spend
FROM ecommerce.customers
WHERE age IS NULL;


SELECT
    COUNT(*) AS total_customers,
    COUNT(*) FILTER (WHERE total_orders < 0) AS negative_orders,
    COUNT(*) FILTER (WHERE total_spend < 0) AS negative_spend,
    COUNT(*) FILTER (WHERE average_order_value < 0) AS negative_aov,
    COUNT(*) FILTER (WHERE total_orders = 0 AND total_spend > 0) AS zero_orders_with_spend,
    COUNT(*) FILTER (WHERE total_orders > 0 AND total_spend = 0) AS orders_without_spend
FROM ecommerce.customers;

SELECT
    COUNT(*) AS total_products,
    COUNT(*) FILTER (WHERE price < 0) AS negative_price,
    COUNT(*) FILTER (WHERE cost_price < 0) AS negative_cost,
    COUNT(*) FILTER (WHERE stock_quantity < 0) AS negative_stock,
    COUNT(*) FILTER (WHERE rating_average < 0 OR rating_average > 5) AS invalid_rating,
    COUNT(*) FILTER (WHERE rating_count < 0) AS negative_rating_count,
    COUNT(*) FILTER (WHERE product_launch_date IS NULL) AS missing_launch_date
FROM ecommerce.products;


SELECT
    COUNT(*) AS total_orders,

    COUNT(*) FILTER (
        WHERE customer_id IS NULL
    ) AS missing_customer_id,

    COUNT(*) FILTER (
        WHERE order_date IS NULL
    ) AS missing_order_date,

    COUNT(*) FILTER (
        WHERE final_amount IS NULL
    ) AS missing_final_amount,

    COUNT(*) FILTER (
        WHERE subtotal < 0
    ) AS negative_subtotal,

    COUNT(*) FILTER (
        WHERE shipping_fee < 0
    ) AS negative_shipping_fee,

    COUNT(*) FILTER (
        WHERE tax_amount < 0
    ) AS negative_tax,

    COUNT(*) FILTER (
        WHERE final_amount < 0
    ) AS negative_final_amount,

    COUNT(*) FILTER (
        WHERE discount_percentage < 0
        OR discount_percentage > 100
    ) AS invalid_discount,

    COUNT(*) FILTER (
        WHERE final_amount <> 
              ROUND(
                  subtotal
                  + shipping_fee
                  + tax_amount
                  - (subtotal * discount_percentage / 100),
                  2
              )
    ) AS amount_mismatch

FROM ecommerce.orders;


SELECT
    order_id,
    subtotal,
    shipping_fee,
    tax_amount,
    discount_percentage,
    final_amount,

    ROUND(
        subtotal
        + shipping_fee
        + tax_amount
        - (subtotal * discount_percentage / 100),
        2
    ) AS calculated_amount,

    ROUND(
        final_amount -
        (
            subtotal
            + shipping_fee
            + tax_amount
            - (subtotal * discount_percentage / 100)
        ),
        2
    ) AS difference

FROM ecommerce.orders

WHERE final_amount <>
      ROUND(
          subtotal
          + shipping_fee
          + tax_amount
          - (subtotal * discount_percentage / 100),
          2
      )

LIMIT 10;



SELECT
    COUNT(*) AS total_orders,

    COUNT(*) FILTER (
        WHERE customer_id IS NULL
    ) AS missing_customer_id,

    COUNT(*) FILTER (
        WHERE order_date IS NULL
    ) AS missing_order_date,

    COUNT(*) FILTER (
        WHERE final_amount IS NULL
    ) AS missing_final_amount,

    COUNT(*) FILTER (
        WHERE subtotal < 0
    ) AS negative_subtotal,

    COUNT(*) FILTER (
        WHERE shipping_fee < 0
    ) AS negative_shipping_fee,

    COUNT(*) FILTER (
        WHERE tax_amount < 0
    ) AS negative_tax,

    COUNT(*) FILTER (
        WHERE final_amount < 0
    ) AS negative_final_amount,

    COUNT(*) FILTER (
        WHERE discount_percentage < 0
        OR discount_percentage > 100
    ) AS invalid_discount,

    COUNT(*) FILTER (
        WHERE final_amount <>
              ROUND(
                  subtotal
                  + shipping_fee
                  + tax_amount,
                  2
              )
    ) AS amount_mismatch

FROM ecommerce.orders;



SELECT
    order_id,
    subtotal,
    shipping_fee,
    tax_amount,
    discount_percentage,
    final_amount,

    ROUND(
        subtotal
        + shipping_fee
        + tax_amount,
        2
    ) AS calculated_amount,

    ROUND(
        final_amount -
        (
            subtotal
            + shipping_fee
            + tax_amount
        ),
        2
    ) AS difference

FROM ecommerce.orders

WHERE final_amount <>
      ROUND(
          subtotal
          + shipping_fee
          + tax_amount,
          2
      )

LIMIT 10;




SELECT
    COUNT(*) AS total_order_items,

    COUNT(*) FILTER (
        WHERE order_id IS NULL
    ) AS missing_order_id,

    COUNT(*) FILTER (
        WHERE product_id IS NULL
    ) AS missing_product_id,

    COUNT(*) FILTER (
        WHERE quantity IS NULL OR quantity <= 0
    ) AS invalid_quantity,

    COUNT(*) FILTER (
        WHERE unit_price IS NULL OR unit_price < 0
    ) AS invalid_unit_price,

    COUNT(*) FILTER (
        WHERE item_revenue IS NULL OR item_revenue < 0
    ) AS invalid_item_revenue,

    COUNT(*) FILTER (
        WHERE item_cost IS NULL OR item_cost < 0
    ) AS invalid_item_cost,

    COUNT(*) FILTER (
        WHERE profit IS NULL
    ) AS missing_profit,

    COUNT(*) FILTER (
        WHERE ABS(profit - (item_revenue - item_cost)) > 0.01
    ) AS profit_mismatch

FROM ecommerce.order_items;



SELECT
    COUNT(*) AS total_payments,

    COUNT(*) FILTER (
        WHERE order_id IS NULL
    ) AS missing_order_id,

    COUNT(*) FILTER (
        WHERE payment_date IS NULL
    ) AS missing_payment_date,

    COUNT(*) FILTER (
        WHERE amount_paid IS NULL OR amount_paid < 0
    ) AS invalid_amount_paid,

    COUNT(*) FILTER (
        WHERE transaction_fee IS NULL OR transaction_fee < 0
    ) AS invalid_transaction_fee,

    COUNT(*) FILTER (
        WHERE refund_amount IS NULL OR refund_amount < 0
    ) AS invalid_refund_amount,

    COUNT(*) FILTER (
        WHERE payment_status IS NULL
    ) AS missing_payment_status

FROM ecommerce.payments;



SELECT
    COUNT(*) AS total_shipments,

    COUNT(*) FILTER (
        WHERE order_id IS NULL
    ) AS missing_order_id,

    COUNT(*) FILTER (
        WHERE dispatch_date IS NULL
    ) AS missing_dispatch_date,

    COUNT(*) FILTER (
        WHERE delivery_days IS NOT NULL
          AND delivery_days < 0
    ) AS negative_delivery_days,

    COUNT(*) FILTER (
        WHERE delayed_flag NOT IN (0, 1)
    ) AS invalid_delayed_flag,

    COUNT(*) FILTER (
        WHERE actual_delivery_date IS NOT NULL
          AND dispatch_date IS NOT NULL
          AND actual_delivery_date < dispatch_date
    ) AS invalid_delivery_dates,

    COUNT(*) FILTER (
        WHERE delivery_status IS NULL
    ) AS missing_delivery_status

FROM ecommerce.shipments;



SELECT
    COUNT(*) AS total_returns,

    COUNT(*) FILTER (
        WHERE order_id IS NULL
    ) AS missing_order_id,

    COUNT(*) FILTER (
        WHERE customer_id IS NULL
    ) AS missing_customer_id,

    COUNT(*) FILTER (
        WHERE product_id IS NULL
    ) AS missing_product_id,

    COUNT(*) FILTER (
        WHERE return_date IS NULL
    ) AS missing_return_date,

    COUNT(*) FILTER (
        WHERE refund_amount IS NULL OR refund_amount < 0
    ) AS invalid_refund_amount,

    COUNT(*) FILTER (
        WHERE return_status IS NULL
    ) AS missing_return_status

FROM ecommerce.returns;




SELECT
    COUNT(*) AS total_reviews,

    COUNT(*) FILTER (
        WHERE order_id IS NULL
    ) AS missing_order_id,

    COUNT(*) FILTER (
        WHERE customer_id IS NULL
    ) AS missing_customer_id,

    COUNT(*) FILTER (
        WHERE product_id IS NULL
    ) AS missing_product_id,

    COUNT(*) FILTER (
        WHERE review_date IS NULL
    ) AS missing_review_date,

    COUNT(*) FILTER (
        WHERE rating IS NULL
    ) AS missing_rating,

    COUNT(*) FILTER (
        WHERE rating < 1 OR rating > 5
    ) AS invalid_rating,

    COUNT(*) FILTER (
        WHERE review_sentiment IS NULL
    ) AS missing_sentiment

FROM ecommerce.customer_reviews;




SELECT 'customers' AS table_name, COUNT(*) AS row_count
FROM ecommerce.customers

UNION ALL

SELECT 'products', COUNT(*)
FROM ecommerce.products

UNION ALL

SELECT 'marketing_campaigns', COUNT(*)
FROM ecommerce.marketing_campaigns

UNION ALL

SELECT 'orders', COUNT(*)
FROM ecommerce.orders

UNION ALL

SELECT 'order_items', COUNT(*)
FROM ecommerce.order_items

UNION ALL

SELECT 'payments', COUNT(*)
FROM ecommerce.payments

UNION ALL

SELECT 'shipments', COUNT(*)
FROM ecommerce.shipments

UNION ALL

SELECT 'returns', COUNT(*)
FROM ecommerce.returns

UNION ALL

SELECT 'customer_reviews', COUNT(*)
FROM ecommerce.customer_reviews

ORDER BY table_name;


TRUNCATE TABLE ecommerce.customers CASCADE;

SELECT COUNT(*) FROM ecommerce.customers;



SELECT 'customers' AS table_name, COUNT(*) FROM ecommerce.customers
UNION ALL
SELECT 'products', COUNT(*) FROM ecommerce.products
UNION ALL
SELECT 'marketing_campaigns', COUNT(*) FROM ecommerce.marketing_campaigns
UNION ALL
SELECT 'orders', COUNT(*) FROM ecommerce.orders
UNION ALL
SELECT 'order_items', COUNT(*) FROM ecommerce.order_items
UNION ALL
SELECT 'payments', COUNT(*) FROM ecommerce.payments
UNION ALL
SELECT 'shipments', COUNT(*) FROM ecommerce.shipments
UNION ALL
SELECT 'returns', COUNT(*) FROM ecommerce.returns
UNION ALL
SELECT 'customer_reviews', COUNT(*) FROM ecommerce.customer_reviews
ORDER BY table_name;



SELECT
    table_name,
    COUNT(*) AS row_count
FROM (
    SELECT 'customers' AS table_name FROM ecommerce.customers
    UNION ALL
    SELECT 'products' FROM ecommerce.products
    UNION ALL
    SELECT 'marketing_campaigns' FROM ecommerce.marketing_campaigns
    UNION ALL
    SELECT 'orders' FROM ecommerce.orders
    UNION ALL
    SELECT 'order_items' FROM ecommerce.order_items
    UNION ALL
    SELECT 'payments' FROM ecommerce.payments
    UNION ALL
    SELECT 'shipments' FROM ecommerce.shipments
    UNION ALL
    SELECT 'returns' FROM ecommerce.returns
    UNION ALL
    SELECT 'customer_reviews' FROM ecommerce.customer_reviews
) x
GROUP BY table_name
ORDER BY table_name;