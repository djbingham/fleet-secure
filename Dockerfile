FROM cfssl/cfssl
MAINTAINER David Bingham <dev@davidjbingham.co.uk>

ADD . /home

VOLUME /home/certificates

ENV FILE_CA_CONFIG="/home/config/ca-config.json"
ENV FILE_CSR_TEMPLATE="/home/config/csr-template.json"
ENV DIR_CERTIFICATES="/home/certificates"

RUN echo 'export PATH="$PATH:/home/commands"' >> ~/.bashrc

WORKDIR /home

ENTRYPOINT ["/home/entrypoint.sh"]
CMD auto
