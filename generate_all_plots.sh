#!/bin/bash

DB_NAME="stock_tracker"
DB_USER="root"
COINS_TABLE="coins"

run_query() {
    mysql -u "$DB_USER" --skip-password --silent --skip-column-names -D "$DB_NAME" -e "$1"
}

SYMBOLS=$(run_query "SELECT symbol FROM $COINS_TABLE;")

echo "--- Starting Batch Plot Generation ---"

echo "$SYMBOLS" | while read -r symbol; do
    if [ -n "$symbol" ]; then
    echo "Processing plot for: $symbol..."

    ./plotter.sh "$symbol"
    sleep 1
    fi
done

echo "--- Batch Plot Generation Complete! ---"
echo "Check your directory for PNG files."