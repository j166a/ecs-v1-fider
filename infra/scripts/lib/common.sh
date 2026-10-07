#!/usr/bin/env bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info() {
  echo -e "${BLUE}$1${NC}"
}

success() {
  echo -e "${GREEN}$1${NC}"
}

warning() {
  echo -e "${YELLOW}$1${NC}"
}

error() {
  echo -e "${RED}$1${NC}" >&2
}

require_commands() {
  for command in "$@"; do
    if ! command -v "$command" >/dev/null 2>&1; then
      error "Required command '$command' is not installed."
      exit 1
    fi
  done
}

check_aws_identity() {
  info "Checking AWS identity..."
  aws sts get-caller-identity >/dev/null
  success "AWS credentials are valid."
}
