#!/bin/bash
FILE_CURRENT_IPS='/tmp/tmp_current_ips'
FILE_OLD_IPS='/tmp/tmp_old_ips'
TMP_BACKEND_VCL='/tmp/tmp_backends.vcl'
TMP_ACCESS_VCL='/tmp/tmp_access.vcl'
BACKEND_VCL='/etc/varnish/backends.vcl'
ACCESS_VCL='/etc/varnish/access.vcl'
REGION='eu-central-1'
STACK=`cat /etc/chef_environment|awk '{print toupper($0)}'`
MASTER_ID=`aws autoscaling describe-auto-scaling-groups --region $REGION \
	--auto-scaling-group-names AS-$STACK-DRUPAL-MASTER|grep InstanceId| \
	cut -d '"' -f 4|sort|uniq`
MASTER_IP=`aws ec2 describe-instances --region $REGION \
	--instance-ids $MASTER_ID|grep '"PrivateIpAddress"'| \
	cut -d '"' -f 4|sort|uniq`
SLAVE_IDS=`aws autoscaling describe-auto-scaling-groups --region $REGION \
	--auto-scaling-group-names AS-$STACK-DRUPAL-SLAVE|grep InstanceId| \
	cut -d '"' -f 4|sort|uniq`
SLAVE_IPS=`for id in $SLAVE_IDS;do aws ec2 describe-instances --region $REGION \
	--instance-ids $id|grep '"PrivateIpAddress"'| \
	cut -d '"' -f 4|sort|uniq;done`

IPS=`echo $MASTER_IP $SLAVE_IPS`
# Master is always the first IP

if [ ! -f $FILE_OLD_IPS ]; then
    touch $FILE_OLD_IPS
fi

echo ${IPS[@]} > $FILE_CURRENT_IPS

DIFF=`diff $FILE_CURRENT_IPS $FILE_OLD_IPS | wc -l`

cat /dev/null > $TMP_BACKEND_VCL

if [ $DIFF -gt 0 ]; then

# Update tmp access.vcl

    cat <<EOF > $TMP_ACCESS_VCL
acl trusted {
  "localhost";
  "127.0.0.1";
EOF

    for i in ${IPS[@]}; do
        IP=$i
        echo "  \"$IP\";"  >> $TMP_ACCESS_VCL
    done
    echo '}' >> $TMP_ACCESS_VCL

# Update tmp backends.vcl

    COUNT=0

    for i in ${IPS[@]}; do
        let COUNT++
        IP=$i
        cat <<EOF >> $TMP_BACKEND_VCL
backend app_$COUNT {
    .host = "$IP";
    .port = "80";
    .connect_timeout = 60s;
    .first_byte_timeout = 60s;
    .between_bytes_timeout = 60s;
    #  .probe = {
    #    .url = "/user";
    #    .interval = 10s;
    #    .timeout = 6s;
    #    .window = 5;
    #    .threshold = 3;
    #  }
}

EOF
    done

    COUNT=0

    echo 'director default_director round-robin {' >> $TMP_BACKEND_VCL

    for i in ${IPS[@]}; do
        let COUNT++
        cat <<EOF >> $TMP_BACKEND_VCL
    { .backend = app_$COUNT; }
EOF
    done

    echo '}' >> $TMP_BACKEND_VCL

    echo 'NEW BACKENDS'

    mv -f $TMP_BACKEND_VCL $BACKEND_VCL
    mv -f $TMP_ACCESS_VCL $ACCESS_VCL

    # Start Varnish if necessary, else reload
    VARNISH_STATUS=`/etc/init.d/varnish status|grep running|wc -l`
    if [ $VARNISH_STATUS -eq 0 ]; then
        /etc/init.d/varnish start; else
            ORIG_CONFIG=$( varnishadm vcl.list | awk ' /^active/ { print $3 } ' )
	    /etc/init.d/varnish reload
            # Remove old config
            . /etc/sysconfig/varnish # Get Varnish variables for use below
            varnishadm -T \
	        $VARNISH_ADMIN_LISTEN_ADDRESS:$VARNISH_ADMIN_LISTEN_PORT \
		-S $VARNISH_SECRET_FILE vcl.discard $ORIG_CONFIG
    fi

mv $FILE_CURRENT_IPS $FILE_OLD_IPS
fi
