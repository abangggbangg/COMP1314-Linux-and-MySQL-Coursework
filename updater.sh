#!/bin/bash

PROJECT_DIR="/Users/abangggbangg/Data-Management-Coursework"

# 1. Change to the project directory
cd "$PROJECT_DIR" || exit

# 2. Run the tracker script to insert new data
echo "--- $(date): Starting Tracker for data insertion ---"
./tracker.sh

# 3. Run the plot generator to update all charts
echo "--- $(date): Starting Plot Generation ---"
./generate_all_plots.sh

echo "--- $(date): Hourly Update Complete ---"