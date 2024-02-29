#!/bin/bash

# List of profiles from `~/.aws/credentials`
profiles=$(grep '\[' ~/.aws/credentials | sed 's/\[\|\]//g' | sed 's/\]//g' | sed 's/\[//g')

for profile in $profiles; do
    echo "Checking account: $profile"
    
    # List all instances in the current profile/account
    aws ec2 describe-instances --query 'Reservations[*].Instances[*].[InstanceId, Tags]' --output text --profile $profile | while read instance_id tags; do
        if [[ $tags != *"Service"* ]]; then
            echo "Instance $instance_id in profile $profile does not have a 'Service' tag."
        fi
    done
done
