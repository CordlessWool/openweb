#!/bin/bash

set -e

ACTION=$1
PARAMS=("${@:2}")

SNOWDIR=$RUNDIR/snowflake/
PROXYDIR=$SNOWDIR/proxy
LOG_TO=$LOGDIR/openweb.log

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
    exit 1
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
  echo $PROXYDIR
  nohup ./proxy $@ > $LOG_TO 2>&1 &
  
}

add_auto_start() {
  # Check if already added to cronjob
  if crontab -l | grep -q "snowflake"; then
    echo "Tor Snowflake is already added to cronjob"
    return
  fi
  # Add to cronjob
  echo "Add Tor Snowflake to cronjob"
  crontab -l | { cat; echo "@reboot $OPENWEB_EXEC snowflake play $@"; } | crontab -
}

remove_auto_start() {
  # Check if already added to cronjob
  if ! crontab -l | grep -q "snowflake"; then
    echo "Tor Snowflake is not added to cronjob"
    return
  fi
  # Remove from cronjob
  crontab -l | grep -v "snowflake" | crontab -
}

stop_proxy() {
  set +e
  kill -9 $(pidof proxy)
  set -e
}

case $ACTION in
  "setup")
    setup
    ;;
  "auto")
    stop_proxy
    setup
    start_proxy "${PARAMS[@]}"
    add_auto_start "${PARAMS[@]}"
    ;;
  "play")
    stop_proxy
    setup
    start_proxy "${PARAMS[@]}"
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
esac

