# DNS Providers

DNS providers should provide a script file named in the following format:

```text
[PROVIDER].bash
```

The script itself should define 4 functions:

```bash
provider_create() {
  # Call certbot to create the certificates from scratch.
}

provider_dependencies() {
  # Commands to install the provider's dependencies.
}

provider_dkim() {
  # Extract the dkim TXT record settings from: /etc/opendkim/keys/${PRIMARY_DOMAIN}/mail.txt
  # Update the "mail._domainkey.${PRIMARY_DOMAIN}" TXT record with the extracted content.
}

provider_renew() {
  # Call certbot to renew existing certificates.
}

```