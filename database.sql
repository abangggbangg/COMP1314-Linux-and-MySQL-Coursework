CREATE DATABASE IF NOT EXISTS stock_tracker;

USE stock_tracker;

DROP TABLE IF EXISTS data_history;
DROP TABLE IF EXISTS coins;
DROP TABLE IF EXISTS collection_runs;

CREATE TABLE coins (
    coin_id INT AUTO_INCREMENT PRIMARY KEY,
    symbol VARCHAR(10) NOT NULL UNIQUE,
    coingecko_id VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE collection_runs (
    run_id INT AUTO_INCREMENT PRIMARY KEY,
    start_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    total_records_inserted INT NOT NULL
);

CREATE TABLE data_history (
    entry_id INT AUTO_INCREMENT PRIMARY KEY,
    coin_id INT NOT NULL,
    price DECIMAL(15,6) NOT NULL,
    change_percent DECIMAL(8,2) NOT NULL,
    moving_average DECIMAL(15,6),
    date_recorded DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (coin_id) REFERENCES coins(coin_id),

    UNIQUE KEY unique_entry (coin_id, date_recorded)
);