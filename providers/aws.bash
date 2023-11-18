#!/bin/bash

provider_create() {
  certbot certonly "${TEST_MODE}" --dns-route53 --dns-route53-propagation-seconds "${DNS_PROPAGATION_DELAY}" -d "*.${PRIMARY_DOMAIN}" -m "${CONTACT_EMAIL}" --agree-tos --no-eff-email
}

provider_dependencies() {
  apt-get install -y --no-install-recommends \
    awscli=1.* \
    python3-certbot-dns-route53=1.*
}

provider_dkim() {

  local OPERATION
  local RESOURCE_RECORD

  readarray -t "DKIM_TXT_RECORD_CONTENT" < <(cut -d"(" -f2 "/etc/opendkim/keys/${PRIMARY_DOMAIN}/mail.txt" | cut -d")" -f1 | tr -d ' "\n\t' | fmt -w 255)
  RESOURCE_RECORD="$(printf "\"%s\"\n" "${DKIM_TXT_RECORD_CONTENT[@]}" | jq -R . | jq -sr 'map( { "Value": . } )')"

  OPERATION="$(jq -n --arg domain "mail._domainkey.${PRIMARY_DOMAIN}" --argjson record "${RESOURCE_RECORD}" '
    {
      "Comment": "Update the dkim TXT record.",
      "Changes": [
        {
          "Action": "UPSERT",
          "ResourceRecordSet": {
            "Name": $domain,
            "Type": "TXT",
            "TTL": 300,
            "ResourceRecords": $record
          }
        }
      ]
    }
  ')"

  aws route53 change-resource-record-sets --hosted-zone-id "${AWS_HOSTED_ZONE_ID}" --change-batch "${OPERATION}"
}

provider_renew() {
  certbot renew "${TEST_MODE}" --dns-route53 --dns-route53-propagation-seconds "${DNS_PROPAGATION_DELAY}" --deploy-hook=/usr/local/share/certs/hooks/deploy.bash
}
