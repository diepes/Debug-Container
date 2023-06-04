FROM --platform=linux/amd64 docker.io/debian:stable-slim
RUN apt-get update \
    && apt-get install -y \
        curl \
        openssl \
        jo \
        vim-tiny \
        tcpdump ngrep \
        iproute2 dnsutils iputils-ping telnet \
        procps \
        less \
        python3 python3-pip \
        openssh-server ssh-client \
        pv \
        sudo \
        git unzip \
        musl-dev musl-tools \
        libpq-dev \
        libsqlite-dev \
        libssl-dev \
        linux-libc-dev \
    && rm -rf /var/lib/apt/lists/* \
    && echo "# apt done." \
    && echo "#Built @ $(date -Is)" >> /info-built.txt

#Install ansible
RUN pip3 install --upgrade pip; \
    pip3 install --upgrade virtualenv; \
    pip3 install pywinrm[kerberos]; \
    pip3 install pywinrm; \
    pip3 install jmspath; \
    pip3 install requests; \
    python3 -m pip install ansible;

#Install Azure cli and ansible modules
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash; \
    ansible-galaxy collection install azure.azcollection; \
    pip3 install -r ~/.ansible/collections/ansible_collections/azure/azcollection/requirements-azure.txt;

#Install AWS cli
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip"; \
    unzip /tmp/awscliv2.zip -d /tmp; \
    /tmp/aws/install; \
    rm -rf /tmp/aws*;

#Install rust
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

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
