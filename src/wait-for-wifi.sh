#!/usr/bin/env sh
test_ip=$1

if [ -z "$test_ip" ]; then
  echo "No test ip specified"
  exit 1
fi

wait_for_wifi() {
  max_retry=60
  counter=0

  ping -c 1 "$test_ip" >/dev/null 2>&1

  # shellcheck disable=SC2181
  while [ $? -ne 0 ]; do
    [ $counter -eq $max_retry ] && echo "Couldnt connect to Wi-Fi" && /usr/sbin/eips "Couldnt connect to Wifi" && sleep 2 && exit 1
    counter=$((counter + 1))

    sleep 1
    ping -c 1 "$test_ip" >/dev/null 2>&1
  done
}

wait_for_wifi
echo "Wi-Fi connected"
