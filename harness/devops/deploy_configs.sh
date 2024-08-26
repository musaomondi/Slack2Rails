#!/bin/bash
set -e

if [ $# -ne 1 ]; then
  echo 1>&2 "Please pass the environment you are deploying to staging/sandbox"
  exit 3
fi

environment=$1

if [ "$environment" = "staging" ] || [ "$environment" = "sandbox" ]; then
  echo "Updating $environment environment with variables defined in devops/configs/$environment.env.template"
  echo "As usual and as is good practise please commit your changes to the upstream if they are needed..Next deploy will default to defined values"
else
  exit 3
fi

read -p "Continue updating $environment environment variables (y/n)? " choice
case "$choice" in
  y | Y) echo "proceeding" ;;
  n | N) exit 3 ;;
  *) exit 3 ;;
esac

pushd $PWD

pushd $PWD/configs
echo "Generating configmap from environment variables"
echo "============================================"
gem install dotenv # Install if needed
ruby parse_configs.rb $environment
popd

echo "Deploying configs to harness-liquidity-request-service service $environment environment"
echo "============================================"

kubectl create configmap harness-liquidity-request-service-configs --from-env-file configs/harness-liquidity-request-service-$environment -o yaml --dry-run | kubectl apply --namespace harness -f -
rm -rf configs/harness-liquidity-request-service-$environment

echo "Your environment has been updated"
echo "============================================"
