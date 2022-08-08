#!/usr/bin/env bash
set -e

command -v kind >/dev/null 2>/dev/null
if [ $? -ne 0 ]; then 
  echo "You need to download KIND from https://github.com/kubernetes-sigs/kind/releases" 
  exit 1
fi
version=$(kind version)
if [ "x$version" != "xv0.5.1" ]; then
  echo "You need version 0.5.1 of Kind"
  exit 1
fi

function load_image() {                                                                 
  IMAGE=$1                                  
  kind load docker-image "$IMAGE" --name vault
}  

load_image $1
