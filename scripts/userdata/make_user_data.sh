#!/bin/bash

set -o errexit ; set -o nounset

DIR=$(dirname $0)
ROLE="$DIR/roles/$2"

if [ ! -f $ROLE ]
then
   echo "Role not found: $2" >&2
   exit 1
fi

sed "s/%%CHEF_ENVIRONMENT%%/$1/" $DIR/user-script.txt > /tmp/$1-$2.tmp

if [[ -n ${5+x} ]]; then
  cat $DIR/roles/$5 >> /tmp/$1-$2.tmp
  echo "  echo $5 > /etc/chef_role" >> /tmp/$1-$2.tmp
else
  cat $DIR/roles/$2 >> /tmp/$1-$2.tmp
fi

if [[ -n ${3+x} ]]; then
  echo "  echo $3 > /root/.my.pw" >> /tmp/$1-$2.tmp
fi
if [[ -n ${4+x} ]]; then
  echo "  echo $4 > /root/.dp.pw" >> /tmp/$1-$2.tmp
fi
echo "  /usr/bin/chef-client -l info -j /etc/chef/first-boot.json -E $1" >> /tmp/$1-$2.tmp
echo "  touch /var/lock/subsys/chef-registration" >> /tmp/$1-$2.tmp
echo "fi" >> /tmp/$1-$2.tmp

./write-mime-multipart --output=/tmp/combined-$1-$2.tmp \
    /tmp/$1-$2.tmp:text/x-shellscript \
    $DIR/cloud-config.txt

if [ $(uname) == 'Darwin' ]; then
  base64 -i /tmp/combined-$1-$2.tmp
else
  base64 -i /tmp/combined-$1-$2.tmp -w0
fi

rm /tmp/$1-$2.tmp
rm /tmp/combined-$1-$2.tmp
