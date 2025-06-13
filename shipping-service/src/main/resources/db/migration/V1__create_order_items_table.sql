CREATE TABLE order_items (
    product_id INT(11) NOT NULL,
    order_id INT(11) NOT NULL,
    ordered_quantity INT(11),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (product_id, order_id)
);