#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

DEV_DIR="$SCRIPT_DIR/../environments/dev"

get_aws_region() {
  terraform -chdir="$SCRIPT_DIR/../bootstrap-state" \
    output -raw aws_region
}

get_state_bucket() {
  terraform -chdir="$SCRIPT_DIR/../bootstrap-state" \
    output -raw state_bucket_name
}

bootstrap_dev_environment() {
  local state_bucket="$1"
  local aws_region="$2"

  info "Initialising dev environment..."
  terraform -chdir="$DEV_DIR" init \
    -reconfigure \
    -backend-config="bucket=$state_bucket" \
    -backend-config="region=$aws_region"

  info "Applying dev infrastructure..."
  terraform -chdir="$DEV_DIR" apply
}

run_migration() {
  info "Running database migration..."
  "$SCRIPT_DIR/ecs-migrate.sh"
  success "Database migration completed."
}

main() {
  info "Fider fresh-account bootstrap"
  echo

  info "Bootstrapping shared infrastructure..."
  "$SCRIPT_DIR/bootstrap-infra.sh"

  echo
  info "Bootstrapping initial application image..."
  "$SCRIPT_DIR/bootstrap-image.sh"

  local state_bucket
  local aws_region

  state_bucket="$(get_state_bucket)"
  aws_region="$(get_aws_region)"

  echo
  bootstrap_dev_environment "$state_bucket" "$aws_region"

  echo
  run_migration

  echo
  success "Bootstrap prerequisites complete."
}

main "$@"
