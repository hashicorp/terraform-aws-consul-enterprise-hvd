#!/usr/bin/env bash
export SHELLOPTS
set -euo pipefail

GOARCH=$(uname -m)
if [ "$GOARCH" == "x86_64" ]
then
  DLARCH="amd64"
elif [ "$GOARCH" == "aarch64" ]
then
  DLARCH="arm64"
else
  DLARCH=$GOARCH
fi

curl -Lo consul.zip https://releases.hashicorp.com/consul/${consul_version}/consul_${consul_version}_linux_$DLARCH.zip

unzip consul.zip
sudo install consul /usr/local/bin/

rm -f consul.zip consul
