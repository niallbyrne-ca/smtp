#!/bin/bash

# shellcheck disable=SC1091
source /usr/local/share/certs/scripts/import.bash

main() {
  echo "CONTAINER > 'deploy' hook has been called."
  import /usr/local/share/certs/scripts "Script Library"
  install_certificates
  echo "CONTAINER > Reloading dovecot and postfix ..."
  dovecot reload
  postfix reload
}

main "$@"
