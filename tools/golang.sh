#!/bin/bash
set -e

ACTION=$1

last_version(){
  ARCH=$(lscpu | grep Architecture | awk {'print $2'})
        case $(echo $ARCH) in
    "aarch64")
            echo "$(curl -s https://go.dev/dl/ | awk -F[\>\<] '/linux-armv64/ && !/beta/ {print $5;exit}')"
      ;;
    "armv6l")
            echo "$(curl -s https://go.dev/dl/ | awk -F[\>\<] '/linux-armv6l/ && !/beta/ {print $5;exit}')"
      ;;
                *)
                        echo "Architecture $ARCH is currently not supported";
                        exit 1;
  esac
}

install() {
  GOLANG=$(last_version)
  wget https://golang.org/dl/$GOLANG
  sudo tar -C /usr/local -xzf $GOLANG
  rm $GOLANG
  unset GOLANG
}

remove() {
  sudo rm -r /usr/local/go
}

update() {
  remove
  install
}

case $ACTION in
  "install")
    echo Will install $(last_version)
    install
    ;;
  "remove")
    remove
    ;;
  "update")
    echo Will update to $(last_version)
    update
    ;;