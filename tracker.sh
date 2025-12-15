#!/bin/bash

DB_NAME="stock_tracker"
DB_USER="root"

COINS_TABLE="coins"
HISTORY_TABLE="data_history"
RUNS_TABLE="collection_runs"

# Function to run MySQL commands with error checking
run_sql() {
    local query="$1"
    local output
    output=$(mysql -u "$DB_USER" --skip-password -D "$DB_NAME" -s -e "$query" 2>/dev/null)
    local status=$?

    if [ $status -ne 0 ]; then
        echo "[DB ERROR] Query failed (Status $status). Logged to db_errors.log."
        local error_output=$(mysql -u "$DB_USER" --skip-password -D "$DB_NAME" -s -e "$query" 2>&1)
        {
            echo "Query: $query"
            echo "Output: $error_output"
            echo "Time: $(date)"
            echo "---"
        } >> db_errors.log
    fi
    echo "$output"
}

echo "---------------------------------"
echo "Starting Crypto Tracker (CoinGecko): $(date)"
echo "---------------------------------"

COIN_MAPPING=$(run_sql "SELECT coin_id, symbol, coingecko_id FROM $COINS_TABLE;")

if [[ -z "$COIN_MAPPING" ]]; then
    echo "[FATAL ERROR] Coin metadata not found. Have you run 'insert_coins.sql'?"
    exit 1
fi

START_TIME=$(date +"%Y-%m-%d %H:%M:%S")
run_sql "INSERT INTO $RUNS_TABLE (start_time, total_records_inserted) VALUES ('$START_TIME', 0);"
RUN_ID=$(run_sql "SELECT LAST_INSERT_ID();")
RECORDS_INSERTED=0

# 1. API Call
COIN_IDS=$(echo "$COIN_MAPPING" | awk '{printf "%s%s", $3, (NR==1?"":",")}')
url="https://api.coingecko.com/api/v3/simple/price?ids=$COIN_IDS&vs_currencies=usd&include_24hr_change=true"

json_data=$(curl -s "$url")
echo "--- RAW JSON DATA START ---"
echo "$json_data"
echo "--- RAW JSON DATA END ---"

# Check for failure
if [[ -z "$json_data" || "$json_data" == "null" ]]; then
    echo "[FATAL ERROR] Failed to retrieve data from CoinGecko. Check network or API status."
    exit 1
fi

# 2. Loop through symbols for parsing and insertion
echo "$COIN_MAPPING" | while read -r coin_id symbol coingecko_id; do

    if [[ -z "$coin_id" ]]; then
        continue
    fi

    price=$(echo "$json_data" | jq -r --arg coin_id "$coingecko_id" '.[$coin_id].usd')
    change_percent=$(echo "$json_data" | jq -r --arg coin_id "$coingecko_id" '.[$coin_id].usd_24h_change')

    # 3. Validate & Insert
    if [[ "$price" == "null" || -z "$price" || "$change_percent" == "null" ]]; then
        echo "[ERROR] Failed to parse data for $symbol (ID: $coingecko_id). Skipping."
        continue
    fi

    # Clean data
    clean_price=$(echo "$price" | sed 's/[^0-9.]//g')
    clean_change=$(printf "%.2f" "$change_percent")

    # Calculate Moving Average (5 periods)
    last_prices=$(run_sql "SELECT price FROM $HISTORY_TABLE WHERE coin_id = '$coin_id' ORDER BY date_recorded DESC LIMIT 4;" 2>/dev/null)

    total_sum="$clean_price"
    count=1

    while read -r p; do
        if [[ -n "$p" ]]; then
            total_sum=$(echo "$total_sum + $p" | bc)
            count=$((count + 1))
        fi
    done <<< "$last_prices"

    if [ "$count" -gt 1 ]; then
        MA=$(echo "scale=6; $total_sum / $count" | bc)
    else
        MA="NULL"
    fi

    if [ "$MA" == "NULL" ]; then
        insert_query="INSERT INTO $HISTORY_TABLE (coin_id, price, change_percent, moving_average) VALUES ('$coin_id', $clean_price, $clean_change, NULL);"
        echo "Found $symbol: Price \$$clean_price | Change $clean_change% | MA: NULL (Count: $count)"
    else
        insert_query="INSERT INTO $HISTORY_TABLE (coin_id, price, change_percent, moving_average) VALUES ('$coin_id', $clean_price, $clean_change, $MA);"
        echo "Found $symbol: Price \$$clean_price | Change $clean_change% | MA: $MA (Count: $count)"
    fi
    
    run_sql "$insert_query"

done

FINAL_COUNT=$(run_sql "SELECT COUNT(entry_id) FROM $HISTORY_TABLE WHERE date_recorded >= '$START_TIME';")
run_sql "UPDATE $RUNS_TABLE SET total_records_inserted = '$FINAL_COUNT' WHERE run_id = '$RUN_ID';"

echo "---------------------------------"
echo "Batch finished. (Only one API call was made.)"
echo "---------------------------------"