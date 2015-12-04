#!/bin/bash

set -o errexit ; set -o nounset

DIR=$(dirname $0)

./write-mime-multipart --output=/tmp/ha-nat_userdata.tmp \
    $DIR/ha-nat.sh:text/x-shellscript \
    $DIR/cloud-config.txt

if [ $(uname) == 'Darwin' ]; then
  base64 -i /tmp/ha-nat_userdata.tmp
else
  base64 -i /tmp/ha-nat_userdata.tmp -w0
fi

rm /tmp/ha-nat_userdata.tmp
