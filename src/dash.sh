#!/usr/bin/env sh
DEBUG=${DEBUG:-false}
[ "$DEBUG" = true ] && set -x

DIR="$(dirname "$0")"
DASH_PNG="$DIR/dash.png"
FETCH_DASHBOARD_CMD="$DIR/local/fetch-dashboard.sh"
LOW_BATTERY_CMD="$DIR/local/low-battery.sh"

WIFI_TEST_IP=${WIFI_TEST_IP:-192.168.178.31}

REFRESH_SCHEDULE=${REFRESH_SCHEDULE:-"40,50 8 * * *"}
TIMEZONE=${TIMEZONE:-"Europe/Berlin"}

# By default, partial screen updates are used to update the screen,
# to prevent the screen from flashing. After a few partial updates,
# the screen will start to look a bit distorted (due to e-ink ghosting).
# This number determines when a full refresh is triggered. By default it's
# triggered after 4 partial updates.
FULL_DISPLAY_REFRESH_RATE=4

# Multiple refresh mode: When the device is woken up by a button press, it will refresh the dashboard
# this many times, with a delay of BUTTON_REFRESH_INTERVAL seconds between each refresh.
BUTTON_REFRESH_COUNT=5
BUTTON_REFRESH_INTERVAL=60
RTC_WAKE_TOLERANCE=90

# When the time until the next wakeup is greater or equal to this number,
# the dashboard will not be refreshed anymore, but instead show a
# 'kindle is sleeping' screen. This can be useful if your schedule only runs
# during the day, for example.
# Only if more than 24 hours
#export SLEEP_SCREEN_INTERVAL=86400

LOW_BATTERY_REPORTING=${LOW_BATTERY_REPORTING:-true}
LOW_BATTERY_THRESHOLD_PERCENT=15

# The number of refreshes since the last full refresh. When this reaches FULL_DISPLAY_REFRESH_RATE, a full refresh is triggered.
num_refresh=0
# The expected wakeup epoch is used to determine if the device woke up from an RTC alarm or a button press.
expected_wakeup_epoch=0

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
  /usr/sbin/eips "$@"
  sleep 2
}

refresh_dashboard() {
  echo "Refreshing dashboard"
  "$DIR/wait-for-wifi.sh" "$WIFI_TEST_IP"

  "$FETCH_DASHBOARD_CMD" "$DASH_PNG"
  fetch_status=$?

  if [ "$fetch_status" -ne 0 ]; then
    echo "Not updating screen, fetch-dashboard returned $fetch_status"
    draw 0 0 "ERROR: Can't Fetch at $(date +%H:%M)"
  else
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
  fi
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

detect_wake_source() {
  current_time=$(date +%s)
  diff=$((expected_wakeup_epoch - current_time))
  if [ "$diff" -ge "-$RTC_WAKE_TOLERANCE" ] && [ "$diff" -le "$RTC_WAKE_TOLERANCE" ]; then
    return 0
  else
    return 1
  fi
}

handle_rtc_wakeup() {
  echo "Woke from RTC alarm"
  refresh_dashboard
  log_battery_stats
}

handle_button_wakeup() {
  echo "Woke from button press! Entering continuous refresh mode."

  i=1
  while [ "$i" -le "$BUTTON_REFRESH_COUNT" ]; do
    refresh_dashboard
    log_battery_stats

    if [ "$i" -lt "$BUTTON_REFRESH_COUNT" ]; then
      echo "Button refresh ${i}/${BUTTON_REFRESH_COUNT}, next in ${BUTTON_REFRESH_INTERVAL}s"
      sleep "$BUTTON_REFRESH_INTERVAL"
    fi
    i=$((i + 1))
  done

  echo "Button refresh window ended. Returning to normal operation."
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
  # Init Draw
  refresh_dashboard
  log_battery_stats

  while true; do
    next_wakeup_secs=$("$DIR/next-wakeup" --schedule="$REFRESH_SCHEDULE" --timezone="$TIMEZONE")
    expected_wakeup_epoch=$(($(date +%s) + next_wakeup_secs))

    echo "Going to suspend, next wakeup in ${next_wakeup_secs}s"
    rtc_sleep "$next_wakeup_secs"

    if detect_wake_source; then
      handle_rtc_wakeup
    else
      handle_button_wakeup
    fi
  done
}
init
main_loop
