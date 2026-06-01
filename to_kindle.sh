#!/usr/bin/env bash
#ssh kindle "mkdir -p /mnt/us/dashboard/"
rsync -r "src/" kindle-door:/mnt/us/dashboard/
