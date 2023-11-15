#!/bin/bash

function create() {
  echo "CONTAINER > 'create' function has been called."
  if [[ ! -e "/etc/letsencrypt/live/${PRIMARY_DOMAIN}" ]]; then
    pushd "certbot" > /dev/null || exit 127
      echo "CONTAINER > Attempting to create certificates ..."
      provider_create
    popd > /dev/null || exit 127
  fi
  install_certificates
}

