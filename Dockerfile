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
           procps \
           less \
    && rm -rf /var/lib/apt/lists/* \
    && echo "# apt done."

COPY motd /etc/motd
RUN echo '[ ! -z "$TERM" -a -r /etc/motd ] && cat /etc/issue && cat /etc/motd' >> /etc/bash.bashrc

CMD [ "/usr/bin/bash" ]
