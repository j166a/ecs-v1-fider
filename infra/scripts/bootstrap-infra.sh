#!/usr/bin/env bash

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

BOOTSTRAP_STATE_DIR="infra/bootstrap-state"
BOOTSTRAP_DIR="infra/bootstrap"

info() {
  echo -e "${BLUE}$1${NC}"
}

success() {
  echo -e "${GREEN}$1${NC}"
}

error() {
  echo -e "${RED}$1${NC}" >&2
}

check_prerequisites() {
  for command in aws terraform; do
    if ! command -v "$command" >/dev/null 2>&1; then
      error "Required command '$command' is not installed."
      exit 1
    fi
  done

  info "Checking AWS identity..."
  aws sts get-caller-identity >/dev/null

  success "Prerequisites passed."
}

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

  check_prerequisites
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
