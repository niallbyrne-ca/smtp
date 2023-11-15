FROM docker.io/cisagov/postfix:latest

ENV ENV_FILE ""
ENV DKIM_DELAY "30"
ENV DNS_PROPAGATION_DELAY "30"
ENV RENEW_INTERVAL_IN_DAYS "7"
ENV TEST_MODE "1"
ENV USER_LIST "admin admin\n"

ARG PROVIDER="aws"

RUN mkdir -p certbot /usr/local/share/certs/providers /usr/local/share/certs/scripts /run/secrets
COPY providers/"${PROVIDER}".bash /usr/local/share/certs/providers
COPY scripts/*.bash /usr/local/share/certs/scripts

RUN apt-get update  \
      &&            \
    apt install -y  \
    certbot         \
    jq              \
    procps          \
    psmisc          \
      &&            \
    bash -c "       \
      source /usr/local/share/certs/providers/${PROVIDER}.bash  \
        &&                                                      \
      provider_dependencies                                     \
    "               \
      &&            \
    rm -rf /var/lib/apt/lists/*

COPY entrypoint.sh entrypoint.sh
RUN chmod +x entrypoint.sh

EXPOSE 25/TCP 587/TCP 993/TCP

ENTRYPOINT ["./entrypoint.sh"]
CMD ["postfix", "-v", "start-fg"]
