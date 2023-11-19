#!/bin/bash

set -eo pipefail

trap _fn_terminate SIGINT SIGTERM ERR EXIT

# shellcheck disable=SC1091
source /usr/local/share/certs/scripts/import.bash

_fn_env_file() {
  if [[ -n "${ENV_FILE}" ]]; then
    set -a
    # shellcheck disable=SC1090
    source "${ENV_FILE}"
    set +a
  fi
}

_fn_terminate() {
  ERROR_CODE="$?"
  echo "CONTAINER > ERROR CODE: ${ERROR_CODE}"
  exit "${ERROR_CODE}"
}

main() {
  _fn_env_file

  _fn_import /usr/local/share/certs/providers "DNS Provider"
  _fn_import /usr/local/share/certs/scripts "Script Library"

  # shellcheck disable=SC2034
  if [[ "${TEST_MODE}" == "1" ]]; then
    TEST_MODE="--test-cert"
  else
    TEST_MODE="-q"
  fi

  _fn_create   # Create initial certificates
  _fn_users    # Configure users and passwords
  _fn_renew &  # Start certificate renewal process
  _fn_config & # Start deferred configuration update
  _fn_dkim &   # Start deferred dkim update process

  echo "CONTAINER > Starting postfix ..."
  ./docker-entrypoint.sh "$@"
}

main "$@"
