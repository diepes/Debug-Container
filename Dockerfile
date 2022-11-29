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
           python3 \
           openssh-server \
           pv \
           sudo \
    && rm -rf /var/lib/apt/lists/* \
    && echo "# apt done."

ARG ROOT_PASS="ilovelinux"
# Note: generate encrypted password with $(openssl passwd -6 tm-admin-example)
RUN echo 'root:$(openssl passwd -6 $ROOT_PASS)' | chpasswd --encrypted root \
    && useradd --system --create-home --no-log-init --gid root --groups sudo --uid 1001 --password '$(openssl passwd -6 $ROOT_PASS)' user1001 \
    && useradd --system --create-home --no-log-init --gid root --groups sudo --uid 1000 --password '$(openssl passwd -6 $ROOT_PASS)' user1000 \
    && useradd --system --create-home --no-log-init --gid root --groups sudo  --uid 999 --password '$(openssl passwd -6 $ROOT_PASS)' user999
    # Add default user, to allow sudo if debug container attached to running k8s pod

COPY sudoers-debug /etc/sudoers.d/
COPY entrypoint* /
COPY motd /etc/motd
RUN echo '[ ! -z "$TERM" -a -r /etc/motd ] && cat /etc/issue && cat /etc/motd' >> /etc/bash.bashrc

CMD [ "/usr/bin/env", "bash" ]
