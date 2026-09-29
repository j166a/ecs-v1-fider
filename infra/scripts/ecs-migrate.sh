#!/usr/bin/env bash

set -euo pipefail

cd "$(dirname "$0")/../environments/dev"

PRIVATE_SUBNETS=$(terraform output -json private_subnet_ids | jq -r 'join(",")')
ECS_SG=$(terraform output -raw ecs_security_group_id)
ECS_CLUSTER=$(terraform output -raw ecs_cluster_name)
TASK_FAMILY=$(terraform output -raw ecs_task_definition_family)

TASK_ARN=$(aws ecs run-task \
  --cluster "$ECS_CLUSTER" \
  --launch-type FARGATE \
  --task-definition "$TASK_FAMILY" \
  --network-configuration "awsvpcConfiguration={subnets=[$PRIVATE_SUBNETS],securityGroups=[$ECS_SG],assignPublicIp=DISABLED}" \
  --overrides '{
    "containerOverrides": [
      {
        "name": "fider-dev",
        "command": ["migrate"]
      }
    ]
  }' \
  --query 'tasks[0].taskArn' \
  --output text)

echo "Started migration task:"
echo "$TASK_ARN"

aws ecs wait tasks-stopped \
  --cluster "$ECS_CLUSTER" \
  --tasks "$TASK_ARN"

EXIT_CODE=$(aws ecs describe-tasks \
  --cluster "$ECS_CLUSTER" \
  --tasks "$TASK_ARN" \
  --query 'tasks[0].containers[0].exitCode' \
  --output text)

STOPPED_REASON=$(aws ecs describe-tasks \
  --cluster "$ECS_CLUSTER" \
  --tasks "$TASK_ARN" \
  --query 'tasks[0].stoppedReason' \
  --output text)

CONTAINER_REASON=$(aws ecs describe-tasks \
  --cluster "$ECS_CLUSTER" \
  --tasks "$TASK_ARN" \
  --query 'tasks[0].containers[0].reason' \
  --output text)

if [[ "$EXIT_CODE" != "0" ]]; then
  echo "Migration failed."
  echo "Exit code: $EXIT_CODE"
  echo "Stopped reason: $STOPPED_REASON"
  echo "Container reason: $CONTAINER_REASON"
  exit 1
fi

echo "Migration completed successfully."
