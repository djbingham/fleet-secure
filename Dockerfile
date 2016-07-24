FROM cfssl/cfssl
MAINTAINER David Bingham <dev@davidjbingham.co.uk>

RUN echo 'export PATH="$PATH:/app/commands"' >> ~/.bashrc

COPY scripts /app/scripts
COPY config /app/config

VOLUME /app/certificates

WORKDIR /app

ENV FILE_CA_CONFIG="/app/config/ca-config.json"
ENV FILE_CSR_TEMPLATE="/app/config/csr-template.json"
ENV DIR_CERTIFICATES="/app/certificates"

ENTRYPOINT ["/app/scripts/main.sh"]
CMD ["auto"]
