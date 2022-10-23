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
           openssh-server \
    && rm -rf /var/lib/apt/lists/* \
    && echo "# apt done."

COPY entrypoint* /
COPY motd /etc/motd
RUN echo '[ ! -z "$TERM" -a -r /etc/motd ] && cat /etc/issue && cat /etc/motd' >> /etc/bash.bashrc

CMD [ "/usr/bin/env", "bash" ]
#CMD [ "/bin/sleep", "3600" ]
