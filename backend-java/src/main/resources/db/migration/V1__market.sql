CREATE TABLE app_users (
 id BIGINT PRIMARY KEY, password_hash VARCHAR(100) NOT NULL
) ENGINE=InnoDB;
CREATE TABLE products (
 id BIGINT PRIMARY KEY AUTO_INCREMENT,
 seller_id BIGINT NOT NULL, title VARCHAR(200) NOT NULL,
 status VARCHAR(16) NOT NULL DEFAULT 'AVAILABLE',
 FOREIGN KEY (seller_id) REFERENCES app_users(id),
 CHECK (status IN ('AVAILABLE','RESERVED','SOLD'))
) ENGINE=InnoDB;
CREATE TABLE reservations (
 id CHAR(36) PRIMARY KEY, product_id BIGINT NOT NULL, buyer_id BIGINT NOT NULL,
 status VARCHAR(16) NOT NULL DEFAULT 'ACTIVE',
 created_at TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
 active_product_id BIGINT GENERATED ALWAYS AS (CASE WHEN status='ACTIVE' THEN product_id ELSE NULL END) STORED,
 UNIQUE KEY one_active_reservation (active_product_id),
 INDEX product_history (product_id, created_at),
 FOREIGN KEY (product_id) REFERENCES products(id),
 FOREIGN KEY (buyer_id) REFERENCES app_users(id),
 CHECK (status IN ('ACTIVE','CANCELLED','COMPLETED'))
) ENGINE=InnoDB;
