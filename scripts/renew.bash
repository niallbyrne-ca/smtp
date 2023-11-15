#!/bin/bash

function renew() {
  echo "CONTAINER > 'renew' function has been called."
  while true; do
    echo "CONTAINER > 'renew' is waiting ${RENEW_INTERVAL_IN_DAYS} days before attempting the next certificate renewal ..."
    sleep $((3600 * 24 * RENEW_INTERVAL_IN_DAYS))
    echo "CONTAINER > Attempting to renew certificates ..."
    pushd "certbot" || exit 127
      if provider_renew; then
        install_certificates
      fi
    popd || exit 127

    echo "CONTAINER > Reloading dovecot and postfix ..."
    dovecot reload
    postfix reload
  done
}
