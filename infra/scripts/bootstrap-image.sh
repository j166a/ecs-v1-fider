#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

BOOTSTRAP_DIR="$SCRIPT_DIR/../bootstrap"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

get_aws_region() {
  AWS_REGION="$(
    terraform -chdir="$BOOTSTRAP_DIR" output -raw aws_region
  )"

  if [[ -z "$AWS_REGION" ]]; then
    error "Terraform did not return an AWS region."
    exit 1
  fi
}

get_ecr_repository() {
  ECR_REPO_URL="$(
    terraform -chdir="$BOOTSTRAP_DIR" output -raw ecr_repository_url
  )"

  if [[ -z "$ECR_REPO_URL" ]]; then
    error "Terraform did not return an ECR repository URL."
    exit 1
  fi

  ECR_REGISTRY="${ECR_REPO_URL%/*}"
  ECR_REPO_NAME="${ECR_REPO_URL##*/}"
}

get_image_details() {
  GIT_SHA="$(git -C "$REPO_ROOT" rev-parse HEAD)"
  IMAGE_URI="${ECR_REPO_URL}:${GIT_SHA}"

  info "Image tag: $GIT_SHA"
  info "Image URI: $IMAGE_URI"
}

check_image_exists() {
  if aws ecr describe-images \
    --repository-name "$ECR_REPO_NAME" \
    --image-ids imageTag="$GIT_SHA" \
    --region "$AWS_REGION" \
    >/dev/null 2>&1; then

    warning "Image $GIT_SHA already exists in ECR. Nothing to do."
    exit 0
  fi
}

build_image() {
  info "Building image..."

  docker build \
    --platform linux/amd64 \
    -t "$IMAGE_URI" \
    "$REPO_ROOT"
}

generate_sbom() {
  info "Generating SBOM..."

  syft "$IMAGE_URI" \
    -o spdx-json=sbom.spdx.json
}

scan_image() {
  info "Scanning image for vulnerabilities..."

  grype "$IMAGE_URI" \
    --fail-on critical

  success "Vulnerability scan passed."
}

login_to_ecr() {
  info "Logging in to ECR..."

  aws ecr get-login-password \
    --region "$AWS_REGION" |
    docker login \
      --username AWS \
      --password-stdin "$ECR_REGISTRY"
}

push_image() {
  info "Pushing image..."

  docker push "$IMAGE_URI"

  success "Bootstrap image pushed successfully:"
  echo "$IMAGE_URI"
}

main() {
  info "Fider initial image bootstrap"
  echo

  require_commands aws docker git syft grype terraform
  check_aws_identity
  echo

  get_aws_region
  get_ecr_repository
  get_image_details
  echo

  check_image_exists

  build_image
  echo

  generate_sbom
  echo

  scan_image
  echo

  login_to_ecr
  echo

  push_image
}

main "$@"
