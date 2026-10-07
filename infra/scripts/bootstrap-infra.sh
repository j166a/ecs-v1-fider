#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

BOOTSTRAP_STATE_DIR="infra/bootstrap-state"
BOOTSTRAP_DIR="infra/bootstrap"

bootstrap_state_bucket() {
  info "Initialising Terraform state bootstrap..."
  terraform -chdir="$BOOTSTRAP_STATE_DIR" init

  info "Applying Terraform state infrastructure..."
  terraform -chdir="$BOOTSTRAP_STATE_DIR" apply
}

get_state_bucket() {
  terraform -chdir="$BOOTSTRAP_STATE_DIR" output -raw state_bucket_name
}

bootstrap_main_infrastructure() {
  local state_bucket="$1"

  info "Initialising main bootstrap..."
  terraform -chdir="$BOOTSTRAP_DIR" init \
    -reconfigure \
    -backend-config="bucket=$state_bucket"

  info "Applying main bootstrap infrastructure..."
  terraform -chdir="$BOOTSTRAP_DIR" apply \
    -var="state_bucket_name=$state_bucket"
}

main() {
  info "Fider infrastructure bootstrap"
  echo

  require_commands aws terraform
  check_aws_identity
  echo

  bootstrap_state_bucket
  echo

  local state_bucket
  state_bucket="$(get_state_bucket)"

  if [[ -z "$state_bucket" ]]; then
    error "Terraform did not return a state bucket name."
    exit 1
  fi

  success "State bucket ready: $state_bucket"
  echo

  bootstrap_main_infrastructure "$state_bucket"
  echo

  success "Infrastructure bootstrap complete."
}

main "$@"
