#!/bin/bash

provider_create() {
  _fn_write_credential_file
  certbot certonly "${TEST_MODE}" --dns-cloudflare --dns-cloudflare-credentials /tmp/cloudflare --dns-cloudflare-propagation-seconds "${DNS_PROPAGATION_DELAY}" -d "*.${PRIMARY_DOMAIN}" -m "${CONTACT_EMAIL}" --agree-tos --no-eff-email
}

provider_dependencies() {
  apt-get install -y --no-install-recommends \
    curl=7.88.* \
    libcurl4=7.88.* \
    python3-certbot-dns-cloudflare=1.*
}

provider_dkim() {

  local DKIM_CONTENT
  local METHOD
  local PARSED_NAME
  local PARSED_ID
  local PAYLOAD
  local RESPONSE

  _fn_dkim_create() {
    local CURL_RESPONSE

    CURL_RESPONSE="$(
      curl -X POST \
        --fail \
        -H "Authorization: Bearer ${CLOUDFLARE_API_TOKEN}" \
        -H "Content-Type: application/json" \
        -d "${PAYLOAD}" \
        -sL \
        "https://api.cloudflare.com/client/v4/zones/${CLOUDFLARE_ZONE_ID}/dns_records"
    )"
    echo "${CURL_RESPONSE}"
  }

  _fn_dkim_get() {
    local CURL_RESPONSE

    CURL_RESPONSE="$(
      curl -X GET \
        --fail \
        -H "Authorization: Bearer ${CLOUDFLARE_API_TOKEN}" \
        -H "Content-Type: application/json" \
        -d "${PAYLOAD}" \
        -sL \
        "https://api.cloudflare.com/client/v4/zones/${CLOUDFLARE_ZONE_ID}/dns_records?type=TXT&match=all"
    )"
    echo "${CURL_RESPONSE}"
  }

  _fn_dkim_update() {
    # $1: Record ID

    local CURL_RESPONSE

    CURL_RESPONSE="$(
      curl -X PUT \
        --fail \
        -H "Authorization: Bearer ${CLOUDFLARE_API_TOKEN}" \
        -H "Content-Type: application/json" \
        -d "${PAYLOAD}" \
        -sL \
        "https://api.cloudflare.com/client/v4/zones/${CLOUDFLARE_ZONE_ID}/dns_records/${1}"
    )"
    echo "${CURL_RESPONSE}"
  }

  _fn_dkim_select_method() {
    METHOD="_fn_dkim_create"
    while read -r LINE; do
      # shellcheck disable=SC2001
      PARSED_NAME=$(sed "s/^\([^\t]*\)\t\(.*\)$/\1/" <<< "${LINE}")
      # shellcheck disable=SC2001
      PARSED_ID=$(sed "s/^\([^\t]*\)\t\(.*\)$/\2/" <<< "${LINE}")
      if [[ "${PARSED_NAME}" == "mail._domainkey.${PRIMARY_DOMAIN}" ]]; then
        METHOD="_fn_dkim_update"
        break
      fi
    done < <(jq -r '.result[] | .name + "\t" + .id' <<< "$(_fn_dkim_get)")
  }

  DKIM_CONTENT="$(cut -d"(" -f2 "/etc/opendkim/keys/${PRIMARY_DOMAIN}/mail.txt" | cut -d")" -f1 | tr -d ' "\n\t')"
  PAYLOAD=$(jq -r ".name = \"mail._domainkey.${PRIMARY_DOMAIN}\" | .content = \"${DKIM_CONTENT}\" | .type = \"TXT\"" <<< '{}')

  _fn_dkim_select_method

  RESPONSE="$(eval "${METHOD}" "${PARSED_ID}")"

  echo "${RESPONSE}" | jq
  if [[ $(jq -r '.success' <<< "${RESPONSE}") != "true" ]]; then
    return 1
  fi
  return 0
}

provider_renew() {
  _fn_write_credential_file
  certbot renew "${TEST_MODE}" --dns_cloudflare --dns-cloudflare-credentials /tmp/cloudflare --dns-cloudflare-propagation-seconds "${DNS_PROPAGATION_DELAY}" --deploy-hook=/usr/local/share/certs/hooks/deploy.bash
}

_fn_write_credential_file() {
  echo "dns_cloudflare_api_token = ${CLOUDFLARE_API_TOKEN}" >> /tmp/cloudflare
  chmod 600 /tmp/cloudflare
}
