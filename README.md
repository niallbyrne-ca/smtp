# SMTP Docker Container

Wraps [cisagov/postfix-docker](https://github.com/cisagov/postfix-docker) in automation for generating [Let's Encrypt](https://letsencrypt.org/) SSL certificates and dkim DNS records.

## Build Arguments

| Name     | Value                                         | Default |
|----------|-----------------------------------------------|---------|
| PROVIDER | "aws" or "cloudflare" to customize container. | aws     |

## Environment Variables

You may set the following environment variables to customize the container's behaviour:

| Name                   | Value                                                                                              | Default         |
|------------------------|----------------------------------------------------------------------------------------------------|-----------------|
| CONTACT_EMAIL          | Let's Encrypt Contact Email.                                                                       | No Default      |
| DKIM_DELAY             | The time to wait for opendkim to generate a dkim value.                                            | 30              |
| DNS_PROPAGATION_DELAY  | The time for Let's Encrypt to wait for DNS changes.                                                | 30              |
| PRIMARY_DOMAIN         | The domain postfix is running for.                                                                 | No Default      |
| RENEW_INTERVAL_IN_DAYS | The interval (in days) to attempt to renew the certificates.                                       | 7               |
| TEST_MODE              | Set to "0" after you have tested certificate generation.                                           | 1               |
| USER_LIST              | A newline separated list of user/password pairs:<br />"username1 password1\nusername2 password2\n" | "admin admin\n" |

### DNS Providers

Each DNS provider has its own set of additional required environment variables.

#### AWS DNS Provider

There are no defaults for provider environment variables.

| Name                  | Value                                           |
|-----------------------|-------------------------------------------------|
| AWS_ACCESS_KEY_ID     | The AWS access key to use to access Route 53.   |
| AWS_HOSTED_ZONE_ID    | The AWS ID for the zone hosted in Route 53.     |
| AWS_SECRET_ACCESS_KEY | The associated AWS secret key for that account. |

Please see the [certbot plugin documentation](https://certbot-dns-route53.readthedocs.io/en/stable/) for further details.

#### Cloudflare DNS Provider

There are no defaults for provider environment variables.

| Name                 | Value                                                                                                                       |
|----------------------|-----------------------------------------------------------------------------------------------------------------------------|
| CLOUDFLARE_API_TOKEN | The restricted Cloudflare API Token for this domain.                                                                        |
| CLOUDFLARE_ZONE_ID   | The [zone id](https://developers.cloudflare.com/fundamentals/setup/find-account-and-zone-ids/) of the domain in Cloudflare. |

Please see the [certbot plugin documentation](https://certbot-dns-cloudflare.readthedocs.io/en/stable/) for further details.

### Using an Env File

Alternatively, you can *mount* a single env file containing all required values.
This file should adhere to the standard Env File format:
```bash
ENV_NAME_1="ENV_VALUE_1"
ENV_NAME_2="ENV_VALUE_2"
ENV_NAME_3="ENV_VALUE_3"
```

Configure this environment variable to tell the container where to find the Env File:

| Name     | Value                                                  | Default    |
|----------|--------------------------------------------------------|------------|
| ENV_FILE | Mounted location of the env file inside the container. | No Default |

## Ports

To access the services inside the container be sure to expose the ports you intend to use:

| Port    | Service            |
|---------|--------------------|
| 25/TCP  | SMTP (Not secure!) |
| 587/TCP | SSL SMTP           |
| 993/TCP | SSL IMAP           |
