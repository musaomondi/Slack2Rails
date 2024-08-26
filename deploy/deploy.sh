#!/bin/bash
set -e

echo "Deploying liquidity-request-service to the $ENVIRONMENT_NAME environment"

echo "Updating Environment configurationss"
echo "============================================"

yes | bash ./deploy_configs.sh $ENVIRONMENT_NAME

echo "Deploying new application stack"
echo "============================================"

cd helm
helm plugin install https://github.com/databus23/helm-diff
commandstr_deploy="helmfile --environment $ENVIRONMENT_NAME apply"
$commandstr_deploy
exitcd_deploy=$?

if [ $exitcd_deploy -eq 0 ]; then
  echo "Deploy success"
else
  echo "Deploy error, exit code: $exitcd_deploy"
  exit 1
fi

echo "============================================"
echo "============================================"
echo "Deployment Complete"
echo "Deployed: liquidity-request-service to the $ENVIRONMENT_NAME"
echo "Version: $TAG "
echo "============================================"
