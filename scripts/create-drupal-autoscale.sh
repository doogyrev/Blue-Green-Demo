#!/bin/bash

ROLE="drupal"

SUCCESS=0
FAILURE=1

function usage {
  echo "USAGE: `basename $0` (blue|green live|staging)"
}

if [ -z "$1" ]                # No argument passed?
then
  usage
  exit $FAILURE
fi

case "$1" in
  "blue")        SUBNETS="subnet-411e8028,subnet-4d0fb336";;
  "green")       SUBNETS="subnet-4d1e8024,subnet-4b0fb330";;
  *) usage; exit $FAILURE
esac

case "$2" in
  "live");;
  "staging") CHEF_ROLE=$2;;
  *) usage; exit $FAILURE
esac

function get_password {
  PASSWORD="passwd"
  PASSWORD2="passwd2"
  while [ "${PASSWORD}" != "${PASSWORD2}" ]; do
    while [[ ${#PASSWORD} -le 7 || \
      "$PASSWORD" =~ [^a-zA-Z0-9] || \
      "$PASSWORD" != *[A-Z]* || \
      "$PASSWORD" != *[a-z]* || \
      "$PASSWORD" != *[0-9]* ]]; do
      read -s -p "${PASS_TYPE} password (>= 8 chars, >= 1 upper, lower & number, NO special chars): " PASSWORD
      echo
    done
    read -s -p "Re-enter ${PASS_TYPE} password: " PASSWORD2
    echo
    if [ "${PASSWORD}" != "${PASSWORD2}" ]; then
      echo "Passwords do not match..."
      PASSWORD="passwd"
      echo
    fi
  done
}

# Get MySQL master password
PASS_TYPE="MySQL master"
get_password
MySQL_PW="${PASSWORD}"

# Get Drupal password
PASS_TYPE="Drupal DB"
get_password
DRUPAL_PW="${PASSWORD}"

STACK=`echo $1|awk '{print toupper($0)}'`
MASTER_MIN_SIZE=1
MASTER_MAX_SIZE=1
SLAVE_MIN_SIZE=1
SLAVE_MAX_SIZE=2
IAM_ROLE="$1"
INSTANCE_TYPE="t2.micro"
MASTER_USERDATA=$(./userdata/make_user_data.sh $1 $ROLE-master $MySQL_PW $DRUPAL_PW $CHEF_ROLE)
SLAVE_USERDATA=$(./userdata/make_user_data.sh $1 $ROLE-slave)
IMAGE_ID="ami-a8221fb5"
SECURITY_GROUPS="sg-e8611e81 sg-15611e7c sg-ea611e83 sg-13611e7a"
KEY_NAME="ec2-user"
#EC_SUBNETS=`echo $SUBNETS|sed 's/,/ /'`
#EC_TYPE="cache.t2.micro"
#EC_SG="sg-eb611e82"
ROLE=`echo $ROLE|awk '{print toupper($0)}'`
REGION=eu-central-1
RDS_INSTANCE_CLASS="db.t2.micro"
RDS_SECURITY_GROUPS="sg-10611e79"
MULTI_AZ="true"

aws rds create-db-instance \
  --db-instance-identifier RDS-$STACK-$ROLE \
  --region $REGION \
  --multi-az \
  --db-subnet-group-name $1_persist \
  --vpc-security-group-ids $RDS_SECURITY_GROUPS \
  --db-instance-class $RDS_INSTANCE_CLASS \
  --db-parameter-group-name PG-DRUPAL \
  --allocated-storage 5 \
  --engine mysql \
  --master-username master \
  --master-user-password $MySQL_PW \
  --tags Key=Name,Value=RDS-$STACK-$ROLE \
  > /dev/null

while [ -z "$RDS_DB" ]; do
  echo "Waiting for RDS endpoint - takes at least 5 mins..."
  RDS_DB=`aws rds describe-db-instances --region $REGION|grep -i RDS-$STACK-$ROLE.*rds.amazonaws.com|cut -d '"' -f 4`
  echo $RDS_DB
  sleep 10
done

#aws elasticache create-cache-subnet-group \
#  --cache-subnet-group-name SNG-$STACK-$ROLE \
#  --cache-subnet-group-description $STACK-$ROLE-Memcached \
#  --subnet-ids $EC_SUBNETS

#aws elasticache create-cache-cluster \
#  --cache-cluster-id EC-$STACK-$ROLE \
#  --cache-subnet-group-name SNG-$STACK-$ROLE \
#  --engine memcached \
#  --security-group-id $EC_SG \
#  --cache-node-type $EC_TYPE \
#  --num-cache-nodes 2 \
#  --az-mode cross-az

#while [ -z "$EC_CLUSTER" ]; do
#  echo "Waiting for Elasticache endpoint..."
#  EC_CLUSTER=`aws elasticache describe-cache-clusters --region $REGION| \
#    grep -i EC-$STACK-$ROLE.*cache.amazonaws.com|cut -d '"' -f 4`
#  echo $EC_CLUSTER
#  sleep 10
#done

# Master
aws autoscaling create-launch-configuration \
  --launch-configuration-name LC-$STACK-$ROLE-MASTER \
  --instance-type $INSTANCE_TYPE \
  --image-id $IMAGE_ID \
  --security-groups $SECURITY_GROUPS \
  --iam-instance-profile $IAM_ROLE \
  --key-name $KEY_NAME \
  --user-data $MASTER_USERDATA

aws autoscaling create-auto-scaling-group \
  --auto-scaling-group-name AS-$STACK-$ROLE-MASTER \
  --launch-configuration-name LC-$STACK-$ROLE-MASTER \
  --min-size $MASTER_MIN_SIZE --max-size $MASTER_MAX_SIZE \
  --desired-capacity $MASTER_MIN_SIZE \
  --default-cooldown 300 \
  --vpc-zone-identifier $SUBNETS \
  --tags "[{\"Key\":\"Name\",\"Value\":\"$STACK-$ROLE-MASTER\",\"PropagateAtLaunch\":true},{\"Key\":\"RDS_DB\",\"Value\":\"$RDS_DB\",\"PropagateAtLaunch\":true},{\"Key\":\"EC_CLUSTER\",\"Value\":\"$EC_CLUSTER\",\"PropagateAtLaunch\":true}]"

# Slave
aws autoscaling create-launch-configuration \
  --launch-configuration-name LC-$STACK-$ROLE-SLAVE \
  --instance-type $INSTANCE_TYPE \
  --image-id $IMAGE_ID \
  --security-groups $SECURITY_GROUPS \
  --iam-instance-profile $IAM_ROLE \
  --key-name $KEY_NAME \
  --user-data $SLAVE_USERDATA

aws autoscaling create-auto-scaling-group \
  --auto-scaling-group-name AS-$STACK-$ROLE-SLAVE \
  --launch-configuration-name LC-$STACK-$ROLE-SLAVE \
  --min-size $SLAVE_MIN_SIZE --max-size $SLAVE_MAX_SIZE \
  --desired-capacity $SLAVE_MIN_SIZE \
  --default-cooldown 300 \
  --vpc-zone-identifier $SUBNETS \
  --tags "[{\"Key\":\"Name\",\"Value\":\"$STACK-$ROLE-SLAVE\",\"PropagateAtLaunch\":true},{\"Key\":\"RDS_DB\",\"Value\":\"$RDS_DB\",\"PropagateAtLaunch\":true}]"

    aws autoscaling put-scaling-policy \
    --auto-scaling-group-name AS-$STACK-$ROLE-SLAVE \
    --policy-name SP-$STACK-$ROLE-SLAVE \
    --scaling-adjustment 1 \
    --adjustment-type ChangeInCapacity

    aws sns create-topic \
    --name Scaling_alarms

    aws sns subscribe \
    --topic-arn `aws sns list-topics|grep Scaling_alarms|awk -F\" '{print $4}'` \
    --protocol email \
    --notification-endpoint aws@mysysadmin.co.uk

    aws cloudwatch put-metric-alarm \
    --alarm-name AL-$STACK-$ROLE-SLAVE \
    --metric-name CPUUtilization \
    --namespace AWS/EC2 \
    --statistic Average \
    --period 300 \
    --evaluation-periods 1 \
    --threshold 75 \
    --comparison-operator GreaterThanOrEqualToThreshold \
    --alarm-actions \
      `aws autoscaling describe-policies --auto-scaling-group-name AS-$STACK-$ROLE-SLAVE|grep PolicyARN| awk -F\" '{print $4}'` \
      `aws sns list-topics|grep Scaling_alarms|awk -F\" '{print $4}'`
