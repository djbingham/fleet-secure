FROM cfssl/cfssl
MAINTAINER David Bingham <dev@davidjbingham.co.uk>

ADD . /home

VOLUME /home/certificates

ENV CONFIG_CA="/home/config/ca-config.json"
ENV CONFIG_CSR_TEMPLATE="/home/config/csr-template.json"
ENV DIR_CERTIFICATES="/home/certificates"

RUN echo 'export PATH="$PATH:/home/commands"' >> ~/.bashrc

WORKDIR /home

ENTRYPOINT ./entrypoint.sh
CMD auto
