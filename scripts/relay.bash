#!/bin/bash

SASL_PASSWORD_FILE="/etc/postfix/sasl/sasl_passwd"

function _fn_relay() {
  echo "CONTAINER > 'relay' function has been called."
  if [[ ! -e "${SASL_PASSWORD_FILE}" ]] && [[ -n "${RELAY_SERVER}" ]]; then
    echo "CONTAINER > 'relay' is waiting ${CONFIG_DELAY} seconds to update the postfix configuration ..."
    sleep "${CONFIG_DELAY}"
    echo "CONTAINER > 'relay' is waiting for postfix to finish setup ..."
    echo "CONTAINER > 'relay' is creating SASL credentials for SMTP relay ..."
    mkdir -p /etc/postfix/sasl
    echo -e "[${RELAY_SERVER}]:${RELAY_SERVER_PORT}\t${RELAY_SERVER_CREDENTIALS}" > "${SASL_PASSWORD_FILE}"
    postmap "${SASL_PASSWORD_FILE}"
    echo "CONTAINER > 'relay' is patching postfix configuration ..."

    echo "  CONFIG > enable SMTP relay authentication ..."
    echo "smtp_sasl_security_options = noanonymous" >> /etc/postfix/main.cf
    echo "smtp_sasl_auth_enable = yes" >> /etc/postfix/main.cf

    echo "  CONFIG > use SASL password map ..."
    echo "smtp_sasl_password_maps = hash:/etc/postfix/sasl/sasl_passwd" >> /etc/postfix/main.cf

    echo "  CONFIG > add relay server ..."
    sed -i '/relayhost =/d' /etc/postfix/main.cf || /bin/true
    echo "relayhost = [${RELAY_SERVER}]:${RELAY_SERVER_PORT}" >> /etc/postfix/main.cf

    echo "CONTAINER > 'relay' has finished updating the configuration!"
    postfix reload
  fi
}
