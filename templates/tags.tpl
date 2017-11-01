#!/bin/bash
#the following two blocks will tag itself
aws ec2 create-tags \
  --region=us-west-2 \
  --resources ${spot_instance_id} \
  --tags \
    Key=Owner,Value=user \
    Key=Environment,Value=production \
    Key=petname,Value="${pet_id}" \
    Key=Name,Value="${product}_${stack_name}"
