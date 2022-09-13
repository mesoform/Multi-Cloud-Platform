#!/usr/bin/env bash
set +x
set -e

MAX_COUNT=100
INSTANCEID=$1
SNAPSHOTID=$2
AZ=$3
DEVICENAME="\"$4\""

REGION=$(echo $AZ | sed 's/.$//')

if [[ -z $INSTANCEID || -z $SNAPSHOTID || -z $AZ || -z $DEVICENAME ]]; then 
  echo "To execute the script, you need to specify four parameters:"
  echo "./restore.sh <instance id> <snapshot id> <availability-zone> <device name>"
  echo "Please specify requirement parameters"
  exit 1
fi

NEWVOLUMEID=$(aws ec2 create-volume --size 8 --region $REGION --availability-zone $AZ --volume-type gp2 --snapshot-id $SNAPSHOTID --tag-specifications 'ResourceType=volume, Tags=[{Key=name, Value=restored}]'| jq '.VolumeId' | sed -e 's/^"//' -e 's/"$//')
echo "New volume from snapshot:" $NEWVOLUMEID

#OLDVOLUMEID=$(aws ec2 describe-instances --filters Name=instance-id,Values=$INSTANCEID | jq  ".Reservations[].Instances[].BlockDeviceMappings[] | {DeviceName: .DeviceName, VolumeId: .Ebs.VolumeId}" | jq '. | select(.DeviceName=="/dev/sdf") | .VolumeId' | sed -e 's/^"//' -e 's/"$//') 
OLDVOLUMEID=$(aws ec2 describe-instances --filters Name=instance-id,Values=$INSTANCEID | jq  ".Reservations[].Instances[].BlockDeviceMappings[] | {DeviceName: .DeviceName, VolumeId: .Ebs.VolumeId}" | jq ". | select(.DeviceName==$DEVICENAME) | .VolumeId" | sed -e 's/^"//' -e 's/"$//') 
if [[ -z $OLDVOLUMEID ]]; then 
  echo "No device in "$DEVICENAME" at instance "$INSTANCEID
  exit 1
fi
echo "Old volume:" $OLDVOLUMEID


RESULT=$(aws ec2 stop-instances --instance-ids $INSTANCEID)
echo "Stopping instance "$INSTANCEID"..."
CYCLES_COUNT=0
while [[ $STATUS != "stopped" && $CYCLES_COUNT -lt $MAX_COUNT ]];
do 
    STATUS=$(aws ec2 describe-instances --filters Name=instance-id,Values=$INSTANCEID | jq ".Reservations[].Instances[].State.Name" | sed -e 's/^"//' -e 's/"$//')
    CYCLES_COUNT=$((CYCLES_COUNT+1))
done

if [[ $CYCLES_COUNT -ge $MAX_COUNT ]]; then
    echo "Failed to stop the instance. Instance status is "$STATUS
    exit 1
else
    echo "Instance "$INSTANCEID" is stopped"
fi

RESULT=$(aws ec2 detach-volume --device /dev/sdf --instance-id $INSTANCEID --volume-id $OLDVOLUMEID)
echo $RESULT

RESULT=$(aws ec2 attach-volume --device /dev/sdf --instance-id $INSTANCEID --volume-id $NEWVOLUMEID)
echo $RESULT

RESULT=$(aws ec2 start-instances --instance-ids $INSTANCEID)
echo "Starting instance "$INSTANCEID"..."
CYCLES_COUNT=0
while [[ $STATUS != "running" && $CYCLES_COUNT -lt $MAX_COUNT ]];
do 
    STATUS=$(aws ec2 describe-instances --filters Name=instance-id,Values=$INSTANCEID | jq ".Reservations[].Instances[].State.Name" | sed -e 's/^"//' -e 's/"$//')
    CYCLES_COUNT=$((CYCLES_COUNT+1))
done

if [[ $CYCLES_COUNT -ge $MAX_COUNT ]]; then
    echo "Failed to start the instance. Instance status is "$STATUS
    exit 1
else
    echo "Instance "$INSTANCEID" is running"
fi

