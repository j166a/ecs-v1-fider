#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

DEV_DIR="$SCRIPT_DIR/../environments/dev"

apply_infrastructure() {
  info "Applying dev infrastructure..."

  terraform -chdir="$DEV_DIR" apply -auto-approve

  success "Dev infrastructure applied."
}

load_service_details() {
  info "Reading ECS service configuration from Terraform..."

  ECS_CLUSTER="$(
    terraform -chdir="$DEV_DIR" output -raw ecs_cluster_name
  )"

  ECS_SERVICE="$(
    terraform -chdir="$DEV_DIR" output -raw ecs_service_name
  )"

  BASE_URL="$(
    terraform -chdir="$DEV_DIR" output -raw base_url
  )"

  HEALTH_URL="${BASE_URL%/}/_health"

  success "ECS service configuration loaded."
}

run_migration() {
  info "Running database migration..."

  "$SCRIPT_DIR/ecs-migrate.sh"
}

start_service() {
  info "Starting ECS application service..."

  aws ecs update-service \
    --cluster "$ECS_CLUSTER" \
    --service "$ECS_SERVICE" \
    --desired-count 1 \
    >/dev/null

  success "ECS service update requested."
}

wait_for_service() {
  info "Waiting for ECS service to become stable..."

  aws ecs wait services-stable \
    --cluster "$ECS_CLUSTER" \
    --services "$ECS_SERVICE"

  success "ECS service is stable."
}

check_health() {
  info "Checking application health..."

  curl \
    --fail \
    --silent \
    --show-error \
    --max-time 10 \
    "$HEALTH_URL"

  echo
  success "Application health check passed."
}

main() {
  info "Fider dev deployment"
  echo

  require_commands aws terraform curl
  check_aws_identity
  echo

  apply_infrastructure
  echo

  run_migration
  echo

  load_service_details
  echo

  start_service
  echo

  wait_for_service
  echo

  check_health
  echo

  success "Deployment completed successfully."
}

main "$@"
