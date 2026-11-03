#!/usr/bin/env bash
# Deploy the dashboard client to a Kindle.
# Usage: bash to_kindle.sh <iot-kindle-ha|iot-kindle-door> <dashboard-url>
set -euo pipefail

usage() {
  echo "Usage: bash to_kindle.sh <iot-kindle-ha|iot-kindle-door> <dashboard-url>"
  exit 1
}

[ $# -eq 2 ] || usage
kindle="$1"
url="$2"

# Photo frame: one new photo per button press, always a full screen refresh.
# Vierwald: a burst of refreshes per button press, a full refresh every 4th time.
case "$kindle" in
  iot-kindle-ha) button_refresh_count=1 full_display_refresh_rate=0 ;;
  iot-kindle-door) button_refresh_count=5 full_display_refresh_rate=4 ;;
  *) usage ;;
esac

echo "Checking $url ..."
result=$(curl -s -o /dev/null -w "%{http_code} %{content_type}" --max-time 120 \
  -H "Content-Type: application/json" -d '{"battery_level":100}' "$url" || true)
if [ "$result" != "200 image/png" ]; then
  echo "Endpoint check failed: expected '200 image/png', got '$result'. Nothing copied."
  exit 1
fi

cd "$(dirname "$0")"
rsync -r src/ "$kindle":/mnt/us/dashboard/
ssh "$kindle" "cat > /mnt/us/dashboard/local/env.sh" <<ENV
export DASHBOARD_URL="$url"
export BUTTON_REFRESH_COUNT=$button_refresh_count
export FULL_DISPLAY_REFRESH_RATE=$full_display_refresh_rate
ENV
echo "Deployed to $kindle with DASHBOARD_URL=$url, BUTTON_REFRESH_COUNT=$button_refresh_count, FULL_DISPLAY_REFRESH_RATE=$full_display_refresh_rate"
