FROM docker.io/cisagov/postfix:0.1.1

ENV ENV_FILE ""
ENV DKIM_DELAY "30"
ENV DNS_PROPAGATION_DELAY "30"
ENV RENEW_INTERVAL_IN_DAYS "7"
ENV TEST_MODE "1"
ENV USER_LIST "admin admin\n"

ARG PROVIDER="aws"

LABEL org.opencontainers.image.source="https://github.com/niallbyrne-ca/smtp"
LABEL org.opencontainers.image.description="Wraps docker.io/cisagov/postfix with SSL and DKIM automation."

RUN mkdir -p certbot /usr/local/share/certs/providers /usr/local/share/certs/scripts /run/secrets
COPY providers/"${PROVIDER}".bash /usr/local/share/certs/providers
COPY scripts/*.bash /usr/local/share/certs/scripts

# Add Backports
RUN printf "deb http://httpredir.debian.org/debian bullseye-backports main\ndeb-src http://httpredir.debian.org/debian bullseye-backports main" \
              > /etc/apt/sources.list.d/backports.list

RUN apt-get update                                              \
      &&                                                        \
    apt-get install -y --no-install-recommends                  \
    certbot=1.*                                                 \
    jq=1.*                                                      \
      &&                                                        \
    bash -c "                                                   \
      source /usr/local/share/certs/providers/${PROVIDER}.bash  \
        &&                                                      \
      provider_dependencies                                     \
    "                                                           \
      &&                                                        \
    rm -rf /var/lib/apt/lists/*

WORKDIR /root

COPY entrypoint.sh entrypoint.sh
RUN chmod +x entrypoint.sh

EXPOSE 25/TCP 587/TCP 993/TCP

ENTRYPOINT ["./entrypoint.sh"]
CMD ["postfix", "-v", "start-fg"]
