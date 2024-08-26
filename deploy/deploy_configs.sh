#!/bin/bash
set -e

if [ $# -ne 1 ]; then
  echo 1>&2 "Please pass the environment you are deploying to staging/production"
  exit 3
fi

environment=$1

if [ "$environment" = "staging" ] || [ "$environment" = "production" ] || [ "$environment" = "sandbox" ] || [ "$environment" = "dr" ]; then
  echo "Updating $environment environment with variables defined in deploy/configs/$environment.env.template"
  echo "As usual and as is good practice please commit your changes to the upstream if they are needed..Next will default to defined values"
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

echo "Deploying configs to liquidity-request-service $environment environment"
echo "============================================"

kubectl create configmap liquidity-request-service-configs --from-env-file configs/liquidity-request-service-$environment -o yaml --dry-run | kubectl apply --namespace liquidity-request-service -f -
rm -rf configs/liquidity-request-service-$environment

echo "Your environment has been updated"
echo "============================================"
