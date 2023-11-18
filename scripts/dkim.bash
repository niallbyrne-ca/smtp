#!/bin/bash

function _fn_dkim() {
  echo "CONTAINER > 'dkim' function has been called."
  echo "CONTAINER > 'dkim' is waiting ${DKIM_DELAY} seconds before attempting to update the dkim TXT record ..."
  sleep "${DKIM_DELAY}"
  echo "CONTAINER > Attempting to update the DNS dkim key ..."
  provider_dkim
}
