#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

DEV_DIR="$SCRIPT_DIR/../environments/dev"

load_infrastructure() {
  info "Reading ECS configuration from Terraform..."

  PRIVATE_SUBNETS="$(
    terraform -chdir="$DEV_DIR" output -json private_subnet_ids |
      jq -r 'join(",")'
  )"

  ECS_SG="$(
    terraform -chdir="$DEV_DIR" output -raw ecs_security_group_id
  )"

  ECS_CLUSTER="$(
    terraform -chdir="$DEV_DIR" output -raw ecs_cluster_name
  )"

  TASK_FAMILY="$(
    terraform -chdir="$DEV_DIR" output -raw ecs_task_definition_family
  )"

  success "ECS configuration loaded."
}

run_migration_task() {
  info "Starting migration task..."

  TASK_ARN="$(
    aws ecs run-task \
      --cluster "$ECS_CLUSTER" \
      --launch-type FARGATE \
      --task-definition "$TASK_FAMILY" \
      --network-configuration \
        "awsvpcConfiguration={subnets=[$PRIVATE_SUBNETS],securityGroups=[$ECS_SG],assignPublicIp=DISABLED}" \
      --overrides '{
        "containerOverrides": [
          {
            "name": "fider-dev",
            "command": ["migrate"]
          }
        ]
      }' \
      --query 'tasks[0].taskArn' \
      --output text
  )"

  if [[ -z "$TASK_ARN" || "$TASK_ARN" == "None" ]]; then
    error "ECS did not return a migration task ARN."
    exit 1
  fi

  success "Migration task started:"
  echo "$TASK_ARN"
}

wait_for_migration() {
  info "Waiting for migration task to finish..."

  aws ecs wait tasks-stopped \
    --cluster "$ECS_CLUSTER" \
    --tasks "$TASK_ARN"
}

check_migration_result() {
  info "Checking migration result..."

  local task_result
  local exit_code
  local stopped_reason
  local container_reason

  task_result="$(
    aws ecs describe-tasks \
      --cluster "$ECS_CLUSTER" \
      --tasks "$TASK_ARN" \
      --query 'tasks[0].[containers[0].exitCode,stoppedReason,containers[0].reason]' \
      --output json
  )"

  exit_code="$(jq -r '.[0] // "unknown"' <<<"$task_result")"
  stopped_reason="$(jq -r '.[1] // "none"' <<<"$task_result")"
  container_reason="$(jq -r '.[2] // "none"' <<<"$task_result")"

  if [[ "$exit_code" != "0" ]]; then
    error "Migration failed."
    echo "Exit code:       $exit_code"
    echo "Stopped reason:  $stopped_reason"
    echo "Container reason: $container_reason"
    exit 1
  fi

  success "Migration completed successfully."
}

main() {
  info "Fider database migration"
  echo

  require_commands aws terraform jq
  check_aws_identity
  echo

  load_infrastructure
  echo

  run_migration_task
  echo

  wait_for_migration
  check_migration_result
}

main "$@"
