#!/usr/bin/env sh
test_ip=$1

if [ -z "$test_ip" ]; then
  echo "No test ip specified"
  exit 1
fi

wait_for_wifi() {
  max_retry=60
  counter=0
  dots=""

  while ! ping -c 1 "$test_ip" >/dev/null 2>&1; do
    counter=$((counter + 1))
    [ "$counter" -ge "$max_retry" ] && echo "Couldn't connect to Wi-Fi" && /usr/sbin/eips -v "Couldnt connect to Wifi" && sleep 2 && exit 1
    dots="${dots}."
    /usr/sbin/eips -v "Connecting$dots"
    sleep 2
  done
}

wait_for_wifi
echo "Wi-Fi connected"
