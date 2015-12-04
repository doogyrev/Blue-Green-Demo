#!/bin/bash

SUCCESS=0
FAILURE=1

function usage {
    echo "USAGE: `basename $0` (blue|green|mgmt)"
}

if [ -z "$1" ]                # No argument passed?
then
  usage
  exit $FAILURE
fi

ROLE="DRUPAL"
STACK=`echo $1|awk '{print toupper($0)}'`
INSTANCE_CLASS="db.t2.micro"
SECURITY_GROUPS="sg-16c0617f"
REGION="eu-central-1"

    aws rds create-db-instance \
    --db-instance-identifier RDS-$STACK-$ROLE \
    --region $REGION \
    --multi-az \
    --db-subnet-group-name $1_persist \
    --vpc-security-group-ids $SECURITY_GROUPS \
    --db-instance-class $INSTANCE_CLASS \
    --allocated-storage 5 \
    --engine mysql \
    --master-username master \
    --master-user-password testtest \
    --tags Key=Name,Value=RDS-$STACK-$ROLE
