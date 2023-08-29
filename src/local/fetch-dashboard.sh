#!/usr/bin/env sh
# Fetch a new dashboard image, make sure to output it to "$1".

url="http://192.168.0.31:8000"
max_retries=10
retry_delay=2

i=0
while [ $i -le $max_retries ]; do

    # shellcheck disable=SC2046
    if [ $(wget -O "$1" "$url") -eq 0 ]; then
        break
    else
        echo "Fetch attempt $i failed. Retrying in $retry_delay seconds..."
        sleep $retry_delay
    fi
    i=$(( i+1 ))
done

