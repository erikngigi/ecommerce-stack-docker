#!/usr/bin/env bash

# print text with the color red
print_red() {
  echo -e "\033[0;31m$1\033[0m"
  sleep 5
}

# print text with the color green
print_green() {
  echo -e "\033[0;32m$1\033[0m"
  sleep 5
}

# print text with the color yellow
print_yellow() {
  echo -e "\033[0;33m$1\033[0m"
  sleep 5
}

# print text with the color blue
print_blue() {
  echo -e "\033[0;34m$1\033[0m"
  sleep 5
}

# print text with the color magenta
print_magenta() {
  echo -e "\033[0;35m$1\033[0m"
  sleep 5
}

# print text with the color cyan
print_cyan() {
  echo -e "\033[0;36m$1\033[0m"
  sleep 5
}
