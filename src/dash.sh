#!/usr/bin/env sh
DEBUG=${DEBUG:-false}
[ "$DEBUG" = true ] && set -x

DIR="$(dirname "$0")"
DASH_PNG="$DIR/dash.png"
FETCH_DASHBOARD_CMD="$DIR/local/fetch-dashboard.sh"
LOW_BATTERY_CMD="$DIR/local/low-battery.sh"

WIFI_TEST_IP=${WIFI_TEST_IP:-192.168.0.31}

REFRESH_SCHEDULE=${REFRESH_SCHEDULE:-"* 5 9-23 * *"}
TIMEZONE=${TIMEZONE:-"Europe/Berlin"}

# By default, partial screen updates are used to update the screen,
# to prevent the screen from flashing. After a few partial updates,
# the screen will start to look a bit distorted (due to e-ink ghosting).
# This number determines when a full refresh is triggered. By default it's
# triggered after 4 partial updates.
FULL_DISPLAY_REFRESH_RATE=4

# When the time until the next wakeup is greater or equal to this number,
# the dashboard will not be refreshed anymore, but instead show a
# 'kindle is sleeping' screen. This can be useful if your schedule only runs
# during the day, for example.
# Only if more than 24 hours
#export SLEEP_SCREEN_INTERVAL=86400

LOW_BATTERY_REPORTING=${LOW_BATTERY_REPORTING:-true}
LOW_BATTERY_THRESHOLD_PERCENT=15

num_refresh=0

hide_status_bar() {
  lipc-set-prop com.lab126.pillow disableEnablePillow disable
}

init() {
  hide_status_bar
  initctl stop framework
  initctl stop webreader >/dev/null 2>&1
  echo powersave >/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor # by default "ondemand"
  lipc-set-prop com.lab126.powerd preventScreenSaver 1
}

# prepare_sleep() {
#   echo "Preparing sleep"

#   eips -f -g "$DIR/sleeping.png"

#   # Give screen time to refresh
#   sleep 2

#   # Ensure a full screen refresh is triggered after wake from sleep
#   num_refresh=$FULL_DISPLAY_REFRESH_RATE
# }

draw() {
  eips "$@"
  sleep 2
}

refresh_dashboard() {
  echo "Refreshing dashboard"
  "$DIR/wait-for-wifi.sh" "$WIFI_TEST_IP"

  "$FETCH_DASHBOARD_CMD" "$DASH_PNG"
  fetch_status=$?

  if [ "$fetch_status" -ne 0 ]; then
    echo "Not updating screen, fetch-dashboard returned $fetch_status"
    draw 0 0 "ERROR: Fetch at $(date +%H:%M)"
    return 1 # TODO: Is this an issue?
  fi

  if [ "$num_refresh" -eq "$FULL_DISPLAY_REFRESH_RATE" ]; then
    num_refresh=0

    # trigger a full refresh once in every 4 refreshes, to keep the screen clean
    echo "Full screen refresh"
    draw -f -g "$DASH_PNG"
  else
    echo "Partial screen refresh"
    draw -g "$DASH_PNG"
  fi

#  sleep 2 # Wait for screen to update

  num_refresh=$((num_refresh + 1))
}

log_battery_stats() {
  battery_level=$(gasgauge-info -c)
  echo "$(date) Battery level: $battery_level."

  if [ "$LOW_BATTERY_REPORTING" = true ]; then
    battery_level_numeric=${battery_level%?}
    if [ "$battery_level_numeric" -le "$LOW_BATTERY_THRESHOLD_PERCENT" ]; then
      "$LOW_BATTERY_CMD" "$battery_level_numeric"
    fi
  fi
}

rtc_sleep() {
  RTC=/sys/devices/platform/mxc_rtc.0/wakeup_enable
  duration=$1

  if [ "$DEBUG" = true ]; then
    sleep "$duration"
  else
    # shellcheck disable=SC2039
    [ "$(cat "$RTC")" -eq 0 ] && echo -n "$duration" >"$RTC"
    echo "mem" >/sys/power/state
  fi
}

main_loop() {
  while true; do
    log_battery_stats

    next_wakeup_secs=$("$DIR/next-wakeup" --schedule="$REFRESH_SCHEDULE" --timezone="$TIMEZONE")

    # take a bit of time before going to sleep, so this process can be aborted
    # sleep 10

    echo "Going to suspend, next wakeup in ${next_wakeup_secs}s"

    rtc_sleep "$next_wakeup_secs"
  done
}
init
main_loop
