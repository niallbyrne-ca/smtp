#!/bin/bash

set -eo pipefail

trap terminate SIGINT SIGTERM ERR EXIT

env_file() {
  if [[ -n "${ENV_FILE}" ]]; then
    set -a
    # shellcheck disable=SC1090
    source "${ENV_FILE}"
    set +a
  fi
}

import() {
  # $1 - path to scripts
  # $2 - description of import
  for SCRIPT in "${1}"/*.bash; do
    echo "CONTAINER > Import ${2}: ${SCRIPT}"
    # shellcheck disable=SC1090
    source "${SCRIPT}"
  done
}

terminate() {
  ERROR_CODE="$?"
  echo "CONTAINER > ERROR CODE: ${ERROR_CODE}"
  exit "${ERROR_CODE}"
}

main() {

  env_file

  import /usr/local/share/certs/providers "DNS Provider"
  import /usr/local/share/certs/scripts "Script Library"

  # shellcheck disable=SC2034
  if [[ "${TEST_MODE}" == "1" ]]; then
    TEST_MODE="--test-cert"
  else
    TEST_MODE="-q"
  fi

  create  # Create initial certificates
  users   # Configure users and passwords
  renew & # Start certificate renewal process
  relay & # Start deferred relay server configuration
  dkim &  # Start deferred dkim update process

  echo "CONTAINER > Starting postfix ..."
  ./docker-entrypoint.sh "$@"
}

main "$@"
