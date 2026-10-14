CREATE TABLE IF NOT EXISTS ecommerce.analytics_run_history (
    run_id BIGSERIAL PRIMARY KEY,
    execution_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    total_orders INTEGER,
    total_customers INTEGER,
    total_revenue NUMERIC(18,2),
    total_profit NUMERIC(18,2),
    average_order_value NUMERIC(18,2),

    return_rate NUMERIC(8,4),
    average_delivery_days NUMERIC(8,2),
    delayed_shipment_rate NUMERIC(8,4),

    quality_issue_count INTEGER,
    data_quality_status VARCHAR(30),
    business_status VARCHAR(50),

    execution_status VARCHAR(30) DEFAULT 'SUCCESS'
);