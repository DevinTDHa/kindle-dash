#!/usr/bin/env sh
# Fetch a new dashboard image, make sure to output it to "$1".
wget -O "$1" http://192.168.0.31:8000
