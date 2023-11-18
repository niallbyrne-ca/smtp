#!/bin/bash

# shellcheck disable=SC1091
source /usr/local/share/certs/scripts/import.bash

main() {
  echo "CONTAINER > 'deploy' hook has been called."
  _fn_import /usr/local/share/certs/scripts "Script Library"
  _fn_install_certificates
  echo "CONTAINER > Reloading dovecot and postfix ..."
  dovecot reload
  postfix reload
}

main "$@"
