CREATE TABLE favourites (
    user_id INT NOT NULL,
    product_id INT NOT NULL,
    like_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (
        user_id,
        product_id,
        like_date
    )
);