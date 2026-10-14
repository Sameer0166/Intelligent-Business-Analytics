-- =====================================================
-- DATA QUALITY VALIDATION
-- Intelligent Business Analytics Platform
-- =====================================================

-- 1. Check row counts
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


-- 2. Check duplicate customer IDs
SELECT customer_id, COUNT(*) AS duplicate_count
FROM ecommerce.customers
GROUP BY customer_id
HAVING COUNT(*) > 1;


-- 3. Check duplicate product IDs
SELECT product_id, COUNT(*) AS duplicate_count
FROM ecommerce.products
GROUP BY product_id
HAVING COUNT(*) > 1;


-- 4. Check orders without a valid customer
SELECT COUNT(*) AS invalid_orders
FROM ecommerce.orders o
LEFT JOIN ecommerce.customers c
    ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;


-- 5. Check order items without a valid order
SELECT COUNT(*) AS invalid_order_items
FROM ecommerce.order_items oi
LEFT JOIN ecommerce.orders o
    ON oi.order_id = o.order_id
WHERE o.order_id IS NULL;


-- 6. Check order items without a valid product
SELECT COUNT(*) AS invalid_product_references
FROM ecommerce.order_items oi
LEFT JOIN ecommerce.products p
    ON oi.product_id = p.product_id
WHERE p.product_id IS NULL;


-- 7. Check payments without a valid order
SELECT COUNT(*) AS invalid_payments
FROM ecommerce.payments p
LEFT JOIN ecommerce.orders o
    ON p.order_id = o.order_id
WHERE o.order_id IS NULL;


-- 8. Check shipments without a valid order
SELECT COUNT(*) AS invalid_shipments
FROM ecommerce.shipments s
LEFT JOIN ecommerce.orders o
    ON s.order_id = o.order_id
WHERE o.order_id IS NULL;


-- 9. Check returns without a valid order
SELECT COUNT(*) AS invalid_returns
FROM ecommerce.returns r
LEFT JOIN ecommerce.orders o
    ON r.order_id = o.order_id
WHERE o.order_id IS NULL;


-- 10. Check reviews without a valid order
SELECT COUNT(*) AS invalid_reviews
FROM ecommerce.customer_reviews cr
LEFT JOIN ecommerce.orders o
    ON cr.order_id = o.order_id
WHERE o.order_id IS NULL;


-- 11. Check negative order amounts
SELECT COUNT(*) AS invalid_order_amounts
FROM ecommerce.orders
WHERE subtotal < 0
   OR shipping_fee < 0
   OR tax_amount < 0
   OR final_amount < 0;


-- 12. Check negative product prices
SELECT COUNT(*) AS invalid_product_prices
FROM ecommerce.products
WHERE price < 0
   OR cost_price < 0;


-- 13. Check invalid quantities
SELECT COUNT(*) AS invalid_quantities
FROM ecommerce.order_items
WHERE quantity <= 0;


-- 14. Check invalid ratings
SELECT COUNT(*) AS invalid_ratings
FROM ecommerce.customer_reviews
WHERE rating < 1
   OR rating > 5;


-- 15. Check shipment date consistency
SELECT COUNT(*) AS invalid_shipments
FROM ecommerce.shipments
WHERE actual_delivery_date IS NOT NULL
  AND dispatch_date IS NOT NULL
  AND actual_delivery_date < dispatch_date;


-- 16. Check order date against customer signup date
SELECT COUNT(*) AS invalid_order_dates
FROM ecommerce.orders o
JOIN ecommerce.customers c
    ON o.customer_id = c.customer_id
WHERE o.order_date < c.customer_signup_date;

