# Liquidity Request Service

Description.

## Local build

To build the container use:

1. `bundle package --all`
2. `rm -rf vendor/bundle`
3. `docker build -t liquidity-request-service .`

To run the app in the container use:

`docker run -p 3510:3000 liquidity-request-service:latest`

## Dependencies

In order to reasonably run this container you need a working API that you are able to connect to.

To run use:

`bundle exec rails s -p 3510 -b 0.0.0.0`

## Deployment

Deployment is done by a CI/CD pipeline. Merge or push to either staging or production branches automatically triggers a deployment to staging and production environment respectively.
