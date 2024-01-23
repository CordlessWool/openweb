#!/bin/bash
set -e

ACTION=$1
PARAMS=("${@:2}")
GODIR=$RUNDIR/go

help () {
  echo "Usage: $OPENWEB_EXEC <action> [options]"
  echo
  echo "Actions:"
  echo "  setup         Install Go"
  echo "  rm            Remove Go"
  echo "  update        Update Go"
  echo "  version       Show Go version"
  echo "  build         Build Go project"
  echo
  echo "Options:"
  echo "  -h, --help    Show this help message"
  echo
}

last_version(){
  ARCH=$(lscpu | grep Architecture | awk {'print $2'})
        case $(echo $ARCH) in
    "aarch64")
      echo "$(curl -s https://go.dev/dl/ | awk -F[\>\<] '/linux-arm64/ && !/beta/ {print $5;exit}')"
      ;;
    "armv6l")
      echo "$(curl -s https://go.dev/dl/ | awk -F[\>\<] '/linux-armv6l/ && !/beta/ {print $5;exit}')"
      ;;
    "x86_64")
      echo "$(curl -s https://go.dev/dl/ | awk -F[\>\<] '/linux-amd64/ && !/beta/ {print $5;exit}')"
      ;;
    "i686")
      echo "$(curl -s https://go.dev/dl/ | awk -F[\>\<] '/linux-386/ && !/beta/ {print $5;exit}')"
      ;;
    *)
      echo "Architecture $ARCH is currently not supported";
      echo "Install go manually from https://golang.org/dl/"
      exit 1;
  esac
}

install() {
  # Check if already installed
  if [ -d "$GODIR" ]; then
    echo "Go is already installed"
    return
  fi
  GOLANG=$(last_version)
  wget https://golang.org/dl/$GOLANG
  mkdir -p $RUNDIR
  tar -C $RUNDIR -xzf $GOLANG
  rm $GOLANG
  unset GOLANG
}

remove() {
  rm -r $GODIR
  ## Remove from path
  sed -i '/export PATH=$GODIR\/bin:$PATH/d' ~/.profile
  ## Reload profile globally
  set -a
  source ~/.profile
  set +a
}

update() {
  ## Check if installed wiht this tool
  if [ ! -d "$GODIR" ]; then
    echo "Go is not installed with this tool"
    return 1
  fi
  remove
  install
}

add_to_path() {
  # Check if already added
  local EXISTS=$(cat ~/.profile | grep -c "export PATH=$GODIR/bin:\$PATH")
  if [[ $EXISTS -gt 0 ]]; then
    echo "Go is already added to path"
    return
  fi
  # Add to path
  echo "export PATH=$GODIR/bin:\$PATH" >> ~/.profile
  set -a
  source ~/.profile
  set +a
}

case $ACTION in
  "setup")
    echo Will install $(last_version)
    install
    add_to_path
    ;;
  "rm")
    remove
    ;;
  "update")
    echo Will update to $(last_version)
    update
    ;;
  "version")
    $GODIR/bin/go version
    ;;
  "build")
    $GODIR/bin/go build $PARAMS
    ;;
  *)
    help
    ;;
esac