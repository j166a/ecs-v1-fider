#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

DEV_DIR="$SCRIPT_DIR/../environments/dev"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

get_aws_region() {
  terraform -chdir="$SCRIPT_DIR/../bootstrap-state" \
    output -raw aws_region
}

get_state_bucket() {
  terraform -chdir="$SCRIPT_DIR/../bootstrap-state" \
    output -raw state_bucket_name
}

get_image_tag() {
  git -C "$REPO_ROOT" rev-parse HEAD
}

bootstrap_dev_environment() {
  local state_bucket="$1"
  local aws_region="$2"
  local image_tag="$3"

  info "Initialising dev environment..."
  terraform -chdir="$DEV_DIR" init \
    -reconfigure \
    -backend-config="bucket=$state_bucket" \
    -backend-config="region=$aws_region"

  ensure_fresh_dev_state

  info "Applying dev infrastructure..."
  terraform -chdir="$DEV_DIR" apply \
    -var="image_tag=$image_tag"
}

run_migration() {
  info "Running database migration..."
  "$SCRIPT_DIR/ecs-migrate.sh"
  success "Database migration completed."
}

load_ecs_service() {
  ECS_CLUSTER="$(
    terraform -chdir="$DEV_DIR" output -raw ecs_cluster_name
  )"

  ECS_SERVICE="$(
    terraform -chdir="$DEV_DIR" output -raw ecs_service_name
  )"
}

ensure_fresh_dev_state() {
  local resources

  resources="$(
    terraform -chdir="$DEV_DIR" state list 2>/dev/null || true
  )"

  if [[ -n "$resources" ]]; then
    error "Dev Terraform state already contains managed resources."
    error "Fresh-account bootstrap aborted."
    error "Use the normal deployment workflow for an existing environment."
    exit 1
  fi

  success "Dev Terraform state is empty."
}

ensure_clean_worktree() {
  if [[ -n "$(git -C "$REPO_ROOT" status --porcelain)" ]]; then
    error "Git working tree is not clean."
    error "Commit or stash changes before running the fresh-account bootstrap."
    exit 1
  fi
}

start_ecs_service() {
  info "Starting ECS service..."

  aws ecs update-service \
    --cluster "$ECS_CLUSTER" \
    --service "$ECS_SERVICE" \
    --desired-count 1 \
    >/dev/null

  success "ECS service desired count set to 1."
}

wait_for_ecs_service() {
  info "Waiting for ECS service to become stable..."

  aws ecs wait services-stable \
    --cluster "$ECS_CLUSTER" \
    --services "$ECS_SERVICE"

  success "ECS service is stable."
}

check_application_health() {
  local base_url

  base_url="$(
    terraform -chdir="$DEV_DIR" output -raw base_url
  )"

  info "Checking application health..."

  curl --fail --silent --show-error \
    "$base_url/_health"

  echo
  success "Application health check passed."
}

main() {
  info "Fider fresh-account bootstrap"
  echo

  require_commands aws terraform curl git
  ensure_clean_worktree

  info "Bootstrapping shared infrastructure..."
  "$SCRIPT_DIR/bootstrap-infra.sh"

  echo
  info "Bootstrapping initial application image..."
  "$SCRIPT_DIR/bootstrap-image.sh"

  local state_bucket
  local aws_region
  local image_tag

  state_bucket="$(get_state_bucket)"
  aws_region="$(get_aws_region)"
  image_tag="$(get_image_tag)"

  echo
  bootstrap_dev_environment \
    "$state_bucket" \
    "$aws_region" \
    "$image_tag"

  load_ecs_service

  echo
  run_migration

  echo
  start_ecs_service

  echo
  wait_for_ecs_service

  echo
  check_application_health

  echo
  success "Bootstrap prerequisites complete."
}

main "$@"
