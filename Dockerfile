FROM docker.io/debian:bullseye-slim
RUN apt-get update \
    && apt-get install -y \
           curl \
           openssl \
           jo \
           vim-tiny \
           tcpdump \
           ngrep \
           iproute2 \
           dnsutils \
           iputils-ping \
           telnet \
    && rm -rf /var/lib/apt/lists/* \
    && echo "# apt done."

CMD [ "/usr/bin/bash" ]
