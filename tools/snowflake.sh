#!/bin/bash

set -e

ACTION=$1
PARAMS=("${@:2}")

SNOWDIR=$RUNDIR/snowflake
PROXYDIR=$SNOWDIR/proxy
LOG_TO=$LOGDIR/openweb.log

help() {
  echo "Usage: $OPENWEB_EXEC snowflake <action> [options]"
  echo
  echo "Actions:"
  echo "  setup         Install Tor Snowflake"
  echo "  auto          Install and start Tor Snowflake on boot"
  echo "  play          Start Tor Snowflake"
  echo "  restart       Restart Tor Snowflake"
  echo "  stop          Stop Tor Snowflake"
  echo "  rm            Remove Tor Snowflake"
  echo "  log           Show Tor Snowflake log"
  echo "  update        Update Tor Snowflake"
  echo
  echo "Options:"
  echo "  -h, --help    Show this help message"
  echo
}



check_go_version() {
  # Check if go is installed and install if not and exit on wrong version
  if ! command -v go &> /dev/null
  then
    echo "Go could not be found"
    return 1
  fi
  GOVERSION=$(go version | awk '{print $3}' | cut -c 3-)
  if [[ $(echo "$GOVERSION 1.21" | tr " " "\n" | sort -V | head -n 1) != "1.21" ]]; then
    echo "Go version 1.21 or higher is required"
    exit 2
  fi
  return
}

install_go() {
  # Check if go is installed and install if not and exit on wrong version
  set +e
  check_go_version
  VERSION=$?
  set -e
  if [[ $VERSION -eq 1 ]]; then
    $OPENWEB_EXEC golang setup
  elif [[ $VERSION -eq 2 ]]; then
    $OPENWEB_EXEC golang update
  fi
}

load() {
  echo "Loading Tor Snowflake"
  mkdir -p $RUNDIR
  cd $RUNDIR
  git clone https://gitlab.torproject.org/tpo/anti-censorship/pluggable-transports/snowflake.git
  cd ..
}

build() {
  # Check if go is installed
  echo "Building Tor Snowflake"
  install_go
  cd $PROXYDIR
  go build
}

remove() {
  echo "Removing Tor Snowflake"
  rm -rf $SNOWDIR
}

update_source() {
  echo "Updating Tor Snowflake"
  cd $SNOWDIR
  git pull
}

setup() {
  # Check if already installed
  if [ -d "$SNOWDIR" ]; then
    return
  fi
  echo "Setting up Tor Snowflake"
  install_go
  load
  build
}

start_proxy() {
  cd $PROXYDIR
  # Check if option h or help is used
  if [[ " ${PARAMS[@]} " =~ " -h " ]] || [[ " ${PARAMS[@]} " =~ " --help " ]]; then
    ./proxy $@
    return
  fi
  # Check if already running
  if is_running; then
    echo "Tor Snowflake is already running"
    return
  fi
  echo "Starting Tor Snowflake"
  nohup ./proxy $@ > $LOG_TO 2>&1 &
}

is_running() {
  if pidof proxy >/dev/null; then
    return 0
  else
    return 1
  fi
}

add_auto_start() {
  # Check if already added to cronjob
  if crontab -l | grep -q "snowflake" > /dev/null; then
    remove_auto_start
  fi
  # Add to cronjob
  echo "Add Tor Snowflake to cronjob"
  crontab -l | { cat; echo "@reboot $OPENWEB_EXEC snowflake play $@"; } | crontab -
}

remove_auto_start() {
  # Check if already added to cronjob
  if ! crontab -l | grep -q "snowflake" > /dev/null; then
    echo "Tor Snowflake is not added to cronjob"
    return
  fi
  # Remove from cronjob
  crontab -l | grep -v "snowflake" | crontab -
}

stop_proxy() {
  # Check if already running
  if ! is_running; then
    echo "Tor Snowflake is not running"
    return
  fi
  set +e
  kill -9 $(pidof proxy) > /dev/null 2>&1
  set -e
  echo "Tor Snowflake is stopped"
}

case $ACTION in
  "setup")
    setup
    ;;
  "auto")
    setup
    start_proxy "${PARAMS[@]}"
    add_auto_start "${PARAMS[@]}"
    ;;
  "play")
    setup
    start_proxy "${PARAMS[@]}"
    ;;
  "restart")
    stop_proxy
    start_proxy "${PARAMS[@]}"
    ;;
  "stop")
    stop_proxy
    ;;
  "rm")
    remove_auto_start
    remove
    ;;
  "log")
    tail ${PARAMS[@]} $LOG_TO
    ;;
  "stop")
    stop_proxy
    ;;
  "update")
    update_source
    build
    ;;
  *)
    help
    ;;
esac

