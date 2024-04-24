FROM --platform=linux/amd64 docker.io/debian:stable-slim
RUN apt-get update \
    && apt-get install -y \
        curl \
        openssl pkg-config \
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
        libssl-dev \
        linux-libc-dev \
        libkrb5-dev \
    && rm -rf /var/lib/apt/lists/* \
    && echo "# apt done." \
    && echo "#Built @ $(date -Is)" >> /info-built.txt

# Install ansible
RUN pip3 install --break-system-packages --upgrade \
            pip virtualenv \
    && pip3 install --break-system-packages \
            pykerberos pywinrm[kerberos] pywinrm requests
RUN pip3 install --break-system-packages \
            jmespath

# Install Azure cli and ansible modules
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash

RUN pip3 install --break-system-packages ansible &&\
    ansible-galaxy collection install azure.azcollection --force &&\
    pip3 install --break-system-packages -r ~/.ansible/collections/ansible_collections/azure/azcollection/requirements-azure.txt

# Install AWS cli
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip" &&\
    unzip /tmp/awscliv2.zip -d /tmp &&\
    /tmp/aws/install &&\
    rm -rf /tmp/aws*

# Install terraform switcher
# https://tfswitch.warrensbox.com/Install/
# RUN curl -L https://raw.githubusercontent.com/warrensbox/terraform-switcher/release/install.sh | bash
COPY install-tfswitch-20240421.sh /tmp/install-tfswitch.sh
RUN bash /tmp/install-tfswitch.sh 1.0.2 && tfswitch --latest
# aztfexport - https://github.com/Azure/aztfexport - M$ does not have debian version
# https://packages.microsoft.com/ubuntu/22.04/prod/pool/main/a/aztfexport/ 
# 2024-04-16 v0.14.1
RUN curl -sSL https://packages.microsoft.com/ubuntu/22.04/prod/pool/main/a/aztfexport/aztfexport_0.14.1_amd64.deb -o /tmp/aztfexport_amd64.deb \
    && dpkg -i /tmp/aztfexport_amd64.deb

# Install rust
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

# Install nodejs nvm node version manager
ENV NODE_VERSION=20
ENV NVM_DIR="/usr/local/nvm"
# NVM v0.39.6 2023-08 - Use git commit to pin code.
ENV NVM_VERSION=c92adb3c479d70bb29f4399a808c972ef41510e7
# Node install - fixed git nvm version. 
RUN git clone https://github.com/nvm-sh/nvm.git "${NVM_DIR}" 
RUN mkdir -p $NVM_DIR
WORKDIR  "${NVM_DIR}"
RUN git checkout ${NVM_VERSION} \
    && \. "./nvm.sh" \
    && nvm install "${NODE_VERSION}" \
    && echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' >> "${HOME}/.bashrc" \
    && echo '[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"' >> "${HOME}/.bashrc"  


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
WORKDIR "/root"

CMD [ "/usr/bin/env", "bash" ]
