#!/bin/bash

DB_NAME="stock_tracker"
DB_USER="root"
TABLE="stock_data"

# Check if a cryptocurrency symbol was passed as an argument
if [ -z "$1" ]; then
    SYMBOL_TO_PLOT="BTC"
    echo "No symbol provided. Defaulting to BTC."
else
    SYMBOL_TO_PLOT=$(echo "$1" | tr '[:lower:]' '[:upper:]')
fi

OUTPUT_FILE="crypto_${SYMBOL_TO_PLOT}_price_chart.png"
DATA_FILE="temp_plot_data.dat"

echo "---------------------------------"
echo "Starting Plotter for $SYMBOL_TO_PLOT: $(date)"
echo "---------------------------------"

# Run a MySQL query
run_query() {
    mysql -u "$DB_USER" --skip-password --silent --skip-column-names -D "$DB_NAME" -e "$1"
}

# 1. Database Query: Extract historical data
echo "Querying historical data for $SYMBOL_TO_PLOT..."
QUERY="
    SELECT 
        UNIX_TIMESTAMP(date_recorded), 
        price,
        moving_average
    FROM $TABLE 
    WHERE symbol = '$SYMBOL_TO_PLOT' 
    ORDER BY date_recorded ASC;
"

run_query "$QUERY" | tr -d '\r' > "$DATA_FILE"

# 2. Validation
if [ ! -s "$DATA_FILE" ] || [ $(wc -l < "$DATA_FILE") -lt 2 ]; then
    echo "[ERROR] Data file for $SYMBOL_TO_PLOT is empty or contains too few entries. Check the database or run tracker.sh again."
    rm -f "$DATA_FILE" 2>/dev/null
    exit 1
fi

# 3. Gnuplot Execution (fixed syntax)
echo "Generating plot image: $OUTPUT_FILE"
gnuplot << EOL
    set terminal pngcairo size 1024, 768
    set output "$OUTPUT_FILE"

    set title "Historical Price of $SYMBOL_TO_PLOT (USD)" font "arial,16"
    set xlabel "Time (Date/Hour)"
    set ylabel "Price (USD)"
    set grid

    set xdata time
    set timefmt "%s"
    set format x "%m/%d\n%H:%M"
    set autoscale x
    set autoscale y

    # Fixed: both plots use the actual file (not "")
    plot "$DATA_FILE" using 1:2 with linespoints linewidth 2 title "$SYMBOL_TO_PLOT Price", \
         "$DATA_FILE" using 1:3 with lines linewidth 2 title "5-Period MA"
EOL

# 4. Cleanup and Output
rm -f "$DATA_FILE"
echo "Plot finished. Image saved as $OUTPUT_FILE"
echo "---------------------------------"
