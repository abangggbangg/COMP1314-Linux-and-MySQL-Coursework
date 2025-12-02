#!/bin/bash

SYMBOLS=("BTC" "ETH" "USDT" "XRP" "BNB" "USDC" "SOL" "TRX" "DOGE" "ADA")

echo "--- Starting Batch Plot Generation ---"

for symbol in "${SYMBOLS[@]}"; do
    echo "Processing plot for: $symbol..."

    ./plotter.sh "$symbol"
    sleep 1
done

echo "--- Batch Plot Generation Complete! ---"
echo "Check your directory for PNG files."