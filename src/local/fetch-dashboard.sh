#!/usr/bin/env sh
# Fetch a new dashboard image, make sure to output it to "$1".
# Optional args: $2 = current_refresh, $3 = total_refreshes

url="http://192.168.178.31:8000/vierwald"
max_retries=10
retry_delay=2

current="${2:-}"
total="${3:-}"

battery_level=$(gasgauge-info -c 2>/dev/null || echo "0%")
battery_level_numeric=${battery_level%?}

if [ -n "$current" ] && [ -n "$total" ]; then
  post_data="{\"current_refresh\":$current,\"total_refreshes\":$total,\"battery_level\":$battery_level_numeric}"
  curl_args="-d $post_data -H Content-Type:application/json"
else
  post_data="{\"battery_level\":$battery_level_numeric}"
  curl_args="-d $post_data -H Content-Type:application/json"
fi

# shellcheck disable=SC2086
curl -s -o "$1" $curl_args \
  --retry "$max_retries" --retry-delay "$retry_delay" \
  "$url"
