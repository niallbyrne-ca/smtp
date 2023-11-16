#!/bin/bash

set -e

# shellcheck disable=SC2046
docker kill $(docker ps -q) || true

docker build --no-cache --build-arg=PROVIDER=aws -t test .

docker run \
  -v "$(pwd)"/certs:/etc/letsencrypt \
  -v "$(pwd)"/aws.env:/mnt/aws.env \
  -e ENV_FILE=/mnt/aws.env \
  -p 587:587 \
  test
