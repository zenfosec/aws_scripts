#!/bin/bash

# AWS configuration
AWS_PROFILE=default
AWS_REGION=us-west-2
POLICY_ARN=arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore
DEFAULT_PROFILE=default-ssm-instance-profile
DRY_RUN=false

INSTANCE_IDS=$(aws ec2 describe-instances --region $AWS_REGION --filters Name=instance-state-name,Values=running --query "Reservations[].Instances[].InstanceId" --output text --profile $AWS_PROFILE)

for INSTANCE_ID in $INSTANCE_IDS
do
  INSTANCE_PROFILE=$(aws ec2 describe-iam-instance-profile-associations --region $AWS_REGION --filters Name=instance-id,Values=$INSTANCE_ID --query "IamInstanceProfileAssociations[].IamInstanceProfile.Arn" --output text --profile $AWS_PROFILE)

  INSTANCE_PROFILE_NAME=$(echo $INSTANCE_PROFILE | awk -F'/' '{print $2}')

  if [ -z "$INSTANCE_PROFILE_NAME" ]
  then

    echo "No IAM Instance Profile attached to instance $INSTANCE_ID"
    if [ "$DRY_RUN" = true ] ; then
        echo "[Dry Run] Would attach default IAM instance profile to instance $INSTANCE_ID"

    else

        aws ec2 associate-iam-instance-profile --region $AWS_REGION --instance-id $INSTANCE_ID --iam-instance-profile Name=$DEFAULT_PROFILE --profile $AWS_PROFILE
        echo "Attached default IAM instance profile to instance $INSTANCE_ID"
    fi

  else

    ROLE_NAME=$(aws iam get-instance-profile --region $AWS_REGION --instance-profile-name $INSTANCE_PROFILE_NAME --query 'InstanceProfile.Roles[].RoleName' --output text --profile $AWS_PROFILE)

    ATTACHED_POLICIES=$(aws iam list-attached-role-policies --region $AWS_REGION --role-name $ROLE_NAME --query 'AttachedPolicies[].PolicyArn' --output text --profile $AWS_PROFILE)

    if echo "$ATTACHED_POLICIES" | grep -q "$POLICY_ARN"; then
      echo "Policy already attached to IAM Role $ROLE_NAME of instance $INSTANCE_ID"

    else

      if [ "$DRY_RUN" = true ] ; then
        echo "[Dry Run] Would attach policy $POLICY_ARN to IAM Role $ROLE_NAME of instance $INSTANCE_ID"

      else
        aws iam attach-role-policy --region $AWS_REGION --role-name $ROLE_NAME --policy-arn $POLICY_ARN --profile $AWS_PROFILE
        echo "Policy attached to IAM Role $ROLE_NAME of instance $INSTANCE_ID"

      fi
    fi
  fi
done

