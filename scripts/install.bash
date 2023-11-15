#!/bin/bash

function install_certificates() {
  echo "CONTAINER > 'install_certificates' function has been called."
  echo "CONTAINER > Attempting to install certificates ..."
  cp -v /etc/letsencrypt/live/"${PRIMARY_DOMAIN}"/fullchain.pem /run/secrets/fullchain.pem
  cp -v /etc/letsencrypt/live/"${PRIMARY_DOMAIN}"/privkey.pem   /run/secrets/privkey.pem
}
