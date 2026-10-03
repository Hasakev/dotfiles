#!/usr/bin/env bash

dunstify \
  -a "weather" \
  -h string:x-dunst-stack-tag:weather-popup \
  "Weather" \
  "$(curl -s 'wttr.in/Brisbane?format=%l:+%c+%t+Feels+%f+Wind+%w')"
