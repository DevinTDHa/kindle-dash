#!/usr/bin/env sh
# Fetch a new dashboard image, make sure to output it to "$1".
# Optional args: $2 = current_refresh, $3 = total_refreshes

url="http://192.168.178.31:8000/vierwald"
max_retries=10
retry_delay=2

current="${2:-}"
total="${3:-}"

if [ -n "$current" ] && [ -n "$total" ]; then
    post_data="{\"current_refresh\":$current,\"total_refreshes\":$total}"
    wget_args="--post-data=$post_data --header=Content-Type:application/json"
else
    wget_args=""
fi

i=0
while [ $i -le $max_retries ]; do

    # shellcheck disable=SC2086
    if wget -O "$1" $wget_args "$url"; then
        break
    else
        echo "Fetch attempt $i failed. Retrying in $retry_delay seconds..."
        sleep $retry_delay
    fi
    i=$(( i+1 ))
done

