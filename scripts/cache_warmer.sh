#! /bin/bash
# Warms both the UK and US Varnish caches
# Makes changes to /etc/hosts to access US Varnish proxy
# Need to change IP adress to reflect US Varnish proxy if it changes
# Depends on /root/website_core_urls, /root/website_blog_urls and <webroot>/clear.php
# 2015-02-12 - First version - www.mysysadmin.co.uk
# 2015-05-26 - Adapated for VPC - www.mysysadmin.co.uk

# Full, core or blog cache warming?
case "$1" in
  full)
    warm_cache="warm_full_cache"
    ;;
  core)
    warm_cache="warm_core_cache"
    ;;
  blog)
    warm_cache="warm_blog_cache"
    ;;
  *)
    /bin/echo $"Usage: $0 {full|core|blog} {live|staging}"
    exit 2
esac

case "$2" in
  live)
    host="www"
    ;;
  staging)
    host="www-stg"
    ;;
  *)
    /bin/echo $"Usage: $0 {full|core|blog} {live|staging}"
    exit 2
esac

#STACK=`echo $2|awk '{print toupper($0)}'`
ROLE=`echo $2|awk '{print toupper($0)}'`

# Get Varnish instance IPs
REGION='eu-central-1'
#IDS=(`aws autoscaling describe-auto-scaling-groups --region $REGION \
#	--auto-scaling-group-names AS-$STACK-VARNISH| \
#	grep InstanceId|cut -d '"' -f 4`)
#IPS=(`for id in ${IDS[@]};do aws ec2 describe-instances --region $REGION \
#	--instance-ids $id|grep '"PrivateIpAddress"'| \
#	cut -d '"' -f 4|sort|uniq;done`)

# Functions

function warm_full_cache {
  /usr/bin/wget -q https://www.brightpearl.com/sitemap.xml --no-check-certificate -O - |\
  sed "s/www/$host/g" | /bin/egrep -o "https://$host\.brightpearl\.com[^<]+" |\
  while read line; do
    /usr/bin/curl -A "$REGION Full Cache Warmer for $ROLE" -k -s -S -L $line > /dev/null 2>&1
    /bin/echo $line
  done
  /bin/echo
}

function warm_core_cache {
  sed "s/www/$host/g" ./website_core_urls |\
    while read line; do
      /usr/bin/curl -A "$REGION Core Cache Warmer for $ROLE" -k -s -S -L $line > /dev/null 2>&1
      /bin/echo $line
    done
  /bin/echo
}

function warm_blog_cache {
  /usr/bin/wget -q https://www.brightpearl.com/sitemap.xml --no-check-certificate -O - |\
  /bin/egrep -o "https://www\.brightpearl\.com/resources/blog[^<]+" | sed "s/www/$host/g" |\
  while read line; do
    /usr/bin/curl -A "$REGION Blog Cache Warmer for $ROLE" -k -s -S -L $line > /dev/null 2>&1
    /bin/echo $line
  done
  /bin/echo
}

function change_hosts_file {
  /bin/echo "**** Changing /etc/hosts to force use of each Varnish proxy in turn *****"
  /bin/echo "$IP www.brightpearl.com" >> /etc/hosts
  /bin/echo "**** /etc/hosts has the following for www.brightpearl.com ****"
  /bin/grep www\.brightpearl\.com /etc/hosts
  /bin/echo
}

function revert_hosts_file {
  /bin/echo "**** Making sure /etc/hosts is normal for www.brightpearl.com ****"
  sed -i "/www\.brightpearl\.com/d" /etc/hosts
  /bin/echo "**** /etc/hosts has the following for www.brightpearl.com ****"
  /bin/grep www\.brightpearl\.com /etc/hosts
  /bin/echo
}

function timestamp {
  /bin/date +%F_%T
  /bin/echo
}

/bin/echo
/bin/echo "Starting at: "; timestamp

# Make sure the hosts file is normal
#revert_hosts_file

# Warm each Varnish instance's cache in turn
#for IP in ${IPS[@]}; do
  /bin/echo "**** Warming $REGION $ROLE "$1" cache ****"
#  change_hosts_file
  warm_$1_cache
#  revert_hosts_file
#done

# Ensure /etc/hosts is reverted if the script exits
#trap '{ revert_hosts_file ; /bin/echo "**** Forced exit - cleaning up ****" ; exit 2 }' SIGINT SIGTERM

# Change hosts file to force use of US Varnish proxy
#change_hosts_file

# Warm US Varnish cache
#/bin/echo "**** Warming US Varnish "$1" cache ****"
#region="US"
#warm_$1_cache

# Undo hosts file changes
#revert_hosts_file

/bin/echo "Ending at: "; timestamp
