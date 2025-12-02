CREATE DATABASE IF NOT EXISTS stock_tracker;

USE stock_tracker;

DROP TABLE IF EXISTS stock_data;

CREATE TABLE stock_data (
    id INT AUTO_INCREMENT PRIMARY KEY,
    symbol VARCHAR(10) NOT NULL,
    price DECIMAL(15, 6) NOT NULL,
    change_percent DECIMAL(8, 2) NOT NULL,
    moving_average DECIMAL(15, 6),
    date_recorded DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY unique_entry (symbol, date_recorded)
);