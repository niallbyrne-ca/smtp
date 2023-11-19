#!/bin/bash

set +x

function _fn_config() {

  local NEEDS_RELOAD
  local POSTFIX_CONFIG_FILE
  local SASL_PASSWORD_FILE
  local SASL_CLIENT_DOMAIN_WHITELIST_FILE

  POSTFIX_CONFIG_FILE="/etc/postfix/main.cf"
  SASL_PASSWORD_FILE="/etc/postfix/sasl/sasl_passwd"
  SASL_CLIENT_DOMAIN_WHITELIST_FILE="/etc/postfix/sasl/sasl_client_whitelist"

  echo "CONTAINER > 'config' function has been called."
  echo "CONTAINER > 'config' is waiting ${CONFIG_DELAY} seconds to update the postfix configuration ..."
  sleep "${CONFIG_DELAY}"

  _fn_postfix_config
  _fn_sasl_config

  if [[ -n "${NEEDS_RELOAD}" ]]; then
    echo "CONTAINER > 'config' has finished updating the configuration, reloading postfix..."
    postfix reload
  else
    echo "CONTAINER > 'config' had no changes to make to the postfix configuration."
  fi
}

function _fn_sasl_config() {

  local WHITELISTED_DOMAIN

  echo "CONTAINER > 'sasl_config' function has been called."

  mkdir -p /etc/postfix/sasl

  if [[ ! -e "${SASL_PASSWORD_FILE}" ]] && [[ -n "${RELAY_SERVER}" ]]; then
    echo "CONTAINER > 'sasl_config' is creating SASL credentials for SMTP relay ..."
    echo -e "[${RELAY_SERVER}]:${RELAY_SERVER_PORT}\t${RELAY_SERVER_CREDENTIALS}" > "${SASL_PASSWORD_FILE}"
    echo "  SASL > '${RELAY_SERVER}:${RELAY_SERVER_PORT}' has been added ..."
    postmap "${SASL_PASSWORD_FILE}"
    NEEDS_RELOAD=1
  fi

  if [[ ! -e "${SASL_CLIENT_DOMAIN_WHITELIST_FILE}" ]] && [[ -n "${CLIENT_DOMAIN_WHITELIST}" ]]; then
    echo "CONTAINER > 'sasl_config' is creating SASL domain whitelist for SMTP clients ..."
    IFS=" " read -ra WHITELISTED_DOMAINS <<< "${CLIENT_DOMAIN_WHITELIST}"
    for WHITELISTED_DOMAIN in "${WHITELISTED_DOMAINS[@]}"; do
      echo -e "${WHITELISTED_DOMAIN}\tOK" >> "${SASL_CLIENT_DOMAIN_WHITELIST_FILE}"
      echo "  SASL > '${WHITELISTED_DOMAIN}' has been whitelisted ..."
    done
    postmap "${SASL_CLIENT_DOMAIN_WHITELIST_FILE}"
    NEEDS_RELOAD=1
  fi
}

function _fn_postfix_config() {

  local NEEDS_RELOAD

  echo "CONTAINER > 'postfix_config' function has been called."
  echo "CONTAINER > 'postfix_config' is patching postfix configuration ..."

  if [[ ! -e "${SASL_PASSWORD_FILE}" ]] && [[ -n "${RELAY_SERVER}" ]]; then
    echo "  CONFIG > enable SMTP relay authentication ..."
    echo "smtp_sasl_security_options = noanonymous" >> "${POSTFIX_CONFIG_FILE}"
    echo "smtp_sasl_auth_enable = yes" >> "${POSTFIX_CONFIG_FILE}"

    echo "  CONFIG > use SASL password map ..."
    echo "smtp_sasl_password_maps = hash:${SASL_PASSWORD_FILE}" >> "${POSTFIX_CONFIG_FILE}"

    echo "  CONFIG > add relay server ..."
    sed -i '/relayhost =/d' "${POSTFIX_CONFIG_FILE}" || /bin/true
    echo "relayhost = [${RELAY_SERVER}]:${RELAY_SERVER_PORT}" >> "${POSTFIX_CONFIG_FILE}"
    NEEDS_RELOAD=1
  fi

  if [[ ! -e "${SASL_CLIENT_DOMAIN_WHITELIST_FILE}" ]] && [[ -n "${CLIENT_DOMAIN_WHITELIST}" ]]; then
    echo "  CONFIG > use SASL domain whitelist map ..."
    echo "smtpd_client_restrictions = permit_mynetworks, check_client_access hash:${SASL_CLIENT_DOMAIN_WHITELIST_FILE}, reject" >> "${POSTFIX_CONFIG_FILE}"
    NEEDS_RELOAD=1
  fi
}
