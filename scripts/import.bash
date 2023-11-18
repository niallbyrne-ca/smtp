#!/bin/bash

import() {
  # $1 - path to scripts
  # $2 - description of import
  for SCRIPT in "${1}"/*.bash; do
    echo "CONTAINER > Import ${2}: ${SCRIPT}"
    # shellcheck disable=SC1090
    source "${SCRIPT}"
  done
}
