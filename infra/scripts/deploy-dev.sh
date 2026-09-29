#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

cd "$SCRIPT_DIR/../environments/dev"

echo "Applying infrastructure with ECS service scaled to 0..."

terraform apply \
  -auto-approve \
  -var='ecs_desired_count=0'

"$SCRIPT_DIR/ecs-migrate.sh"

echo "Starting ECS application service..."

terraform apply \
  -auto-approve \
  -var='ecs_desired_count=1'

ECS_CLUSTER=$(terraform output -raw ecs_cluster_name)
ECS_SERVICE=$(terraform output -raw ecs_service_name)

echo "Waiting for ECS service to become stable..."

aws ecs wait services-stable \
  --cluster "$ECS_CLUSTER" \
  --services "$ECS_SERVICE"

BASE_URL=$(terraform output -raw base_url)
HEALTH_URL="${BASE_URL%/}/_health"

echo "Checking application health..."

curl --fail --silent --show-error \
  --max-time 10 \
  "$HEALTH_URL"

echo
echo "Deployment completed successfully."
