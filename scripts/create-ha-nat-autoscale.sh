#!/bin/bash

MIN_SIZE=2
MAX_SIZE=2
IAM_ROLE="ha-nat"
INSTANCE_TYPE="t2.micro"
USERDATA=$(./userdata/make_ha_nat_user_data.sh)
IMAGE_ID="ami-bc5b48d0"
SECURITY_GROUPS="sg-14611e7d sg-13611e7a"
KEY_NAME="ec2-user"
SUBNET_1A="subnet-481e8021"
SUBNET_1B="subnet-540fb32f"
REGION=eu-central-1

aws autoscaling create-launch-configuration \
  --launch-configuration-name LC-HA-NAT \
  --instance-type $INSTANCE_TYPE \
  --image-id $IMAGE_ID \
  --security-groups $SECURITY_GROUPS \
  --iam-instance-profile $IAM_ROLE \
  --associate-public-ip-address \
  --key-name $KEY_NAME \
  --user-data $USERDATA

aws autoscaling create-auto-scaling-group \
  --auto-scaling-group-name AS-HA-NAT \
  --launch-configuration-name LC-HA-NAT \
  --min-size $MIN_SIZE --max-size $MAX_SIZE \
  --desired-capacity $MIN_SIZE \
  --health-check-grace-period 30 \
  --default-cooldown 300 \
  --vpc-zone-identifier $SUBNET_1A,$SUBNET_1B \
  --tags "[{\"Key\":\"Name\",\"Value\":\"HA-NAT\",\"PropagateAtLaunch\":true}]"
