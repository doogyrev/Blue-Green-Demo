#!/bin/bash

SUCCESS=0
FAILURE=1

function usage {
    echo "USAGE: `basename $0` (blue|green)"
}

if [ -z "$1" ]                # No argument passed?
then
  usage
  exit $FAILURE
fi

case "$1" in
  "blue")          SUBNETS="subnet-411e8028,subnet-4d0fb336"
		   ELB_NAME="stack1"
		   ;;
  "green")       SUBNETS="subnet-4d1e8024,subnet-4b0fb330"
                 ELB_NAME="stack2"
		   ;;
  *) usage; exit $FAILURE
esac

ROLE="varnish"
STACK=`echo $1|awk '{print toupper($0)}'`
MIN_SIZE=1
MAX_SIZE=2
IAM_ROLE="$1"
INSTANCE_TYPE="t2.micro"
USERDATA=$(./userdata/make_user_data.sh $1 $ROLE)
IMAGE_ID="ami-a8221fb5"
SECURITY_GROUPS="sg-e8611e81 sg-15611e7c sg-ea611e83 sg-13611e7a"
KEY_NAME="ec2-user"
ELB_SUBNETS="subnet-481e8021 subnet-540fb32f"
ELB_SG="sg-e9611e80 sg-17611e7e"
ROLE=`echo $ROLE|awk '{print toupper($0)}'`

    aws elb create-load-balancer \
    --load-balancer-name $ELB_NAME \
    --listeners Protocol=HTTP,LoadBalancerPort=80,InstanceProtocol=HTTP,InstancePort=80 \
    --subnets $ELB_SUBNETS \
    --security-groups $ELB_SG

    aws elb modify-load-balancer-attributes \
    --load-balancer-name $ELB_NAME \
    --load-balancer-attributes "{\"CrossZoneLoadBalancing\":{\"Enabled\":true},\"ConnectionDraining\":{\"Enabled\":true,\"Timeout\":300}}"

    aws autoscaling create-launch-configuration \
    --launch-configuration-name LC-$STACK-$ROLE \
    --instance-type $INSTANCE_TYPE \
    --image-id $IMAGE_ID \
    --security-groups $SECURITY_GROUPS \
    --iam-instance-profile $IAM_ROLE \
    --key-name $KEY_NAME \
    --user-data $USERDATA

    aws autoscaling create-auto-scaling-group \
    --auto-scaling-group-name AS-$STACK-$ROLE \
    --launch-configuration-name LC-$STACK-$ROLE \
    --min-size $MIN_SIZE --max-size $MAX_SIZE \
    --desired-capacity $MIN_SIZE \
    --default-cooldown 300 \
    --vpc-zone-identifier $SUBNETS \
    --load-balancer-names $ELB_NAME \
    --tags "[{\"Key\":\"Name\",\"Value\":\"$STACK-$ROLE\",\"PropagateAtLaunch\":true}]"

    aws autoscaling put-scaling-policy \
    --auto-scaling-group-name AS-$STACK-$ROLE \
    --policy-name SP-$STACK-$ROLE \
    --scaling-adjustment 1 \
    --adjustment-type ChangeInCapacity

    aws sns create-topic \
    --name Scaling_alarms

    aws sns subscribe \
    --topic-arn `aws sns list-topics|grep Scaling_alarms|awk -F\" '{print $4}'` \
    --protocol email \
    --notification-endpoint aws@mysysadmin.co.uk

    aws cloudwatch put-metric-alarm \
    --alarm-name AL-$STACK-$ROLE \
    --metric-name CPUUtilization \
    --namespace AWS/EC2 \
    --statistic Average \
    --period 300 \
    --evaluation-periods 1 \
    --threshold 75 \
    --comparison-operator GreaterThanOrEqualToThreshold \
    --alarm-actions \
      `aws autoscaling describe-policies --auto-scaling-group-name AS-$STACK-$ROLE|grep PolicyARN| awk -F\" '{print $4}'` \
      `aws sns list-topics|grep Scaling_alarms|awk -F\" '{print $4}'`
