# Define the platform as a build argument with a default value
ARG PLATFORM=linux/amd64

# Stage 1: Build the Rust executable
FROM --platform=${PLATFORM} rust:1.85.1-slim AS builder
WORKDIR /app
# Copy the Rust project files into the container
COPY ./src/rust_aztfexport_rename /app
# Run tests to ensure the code is correct
RUN cargo test --release --locked --all-targets --all-features
# Build the Rust project in release mode
RUN cargo build --release

# Stage 2: Final image
# Use the platform argument in the FROM instruction
FROM --platform=${PLATFORM} docker.io/debian:stable-slim

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
        python3 python3-venv python3-dev \
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

    # Create python venv
ENV VIRTUAL_ENV=/opt/venv
# ENV VIRTUAL_ENV=${HOME}/venv/
RUN mkdir -p ${VIRTUAL_ENV}
# create venv
RUN python3 -m venv ${VIRTUAL_ENV}
ENV PATH="${VIRTUAL_ENV}/bin:$PATH"

# Install ansible
RUN pip install pykerberos 
RUN pip install pywinrm[kerberos] pywinrm requests
RUN pip install jmespath

# Install Azure cli and ansible modules
RUN curl -sL https://aka.ms/InstallAzureCLIDeb |  bash

RUN pip install ansible
RUN ansible-galaxy collection install azure.azcollection --force
#
# # Debug azure.azcollection requirements with --progress=plain
# RUN ls -al ${HOME}/.ansible/collections/
# RUN ls -al         ${HOME}/.ansible/collections/ansible_collections/azure/azcollection/
RUN pip install -r ${HOME}/.ansible/collections/ansible_collections/azure/azcollection/requirements.txt

# Install AWS cli
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip" &&\
    unzip /tmp/awscliv2.zip -d /tmp &&\
    /tmp/aws/install &&\
    rm -rf /tmp/aws*

# Install terraform switcher
# https://tfswitch.warrensbox.com/Install/
# RUN curl -L https://raw.githubusercontent.com/warrensbox/terraform-switcher/release/install.sh | bash
COPY /src/install-tfswitch-20241216.sh /tmp/install-tfswitch.sh
RUN bash /tmp/install-tfswitch.sh "v1.2.4" && tfswitch --latest
# aztfexport - https://github.com/Azure/aztfexport - M$ does not have debian version
# https://packages.microsoft.com/ubuntu/22.04/prod/pool/main/a/aztfexport/
# 2024-04-16 v0.14.1, 2024-12-16 v0.15.0, 2025-03-25 v0.17.1, 2025-06-16 v0.18.0
RUN curl -sSL https://packages.microsoft.com/ubuntu/22.04/prod/pool/main/a/aztfexport/aztfexport_0.18.0_amd64.deb -o /tmp/aztfexport_amd64.deb \
    && dpkg -i /tmp/aztfexport_amd64.deb

# Copy aztfexport shell scripts
COPY /src/aztfexport/* /usr/local/bin

# Copy script that uses okta to retrieve AWS k8s credentials
COPY /src/okta-get-aws-eks-credentials.sh /usr/local/bin

# Install k8s kubectl
RUN curl -L "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" -o /usr/local/bin/kubectl && chmod +x /usr/local/bin/kubectl

# Install rust
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
# Copy the Rust binary from the builder stage
COPY --from=builder /app/target/release/rust_aztfexport_rename /usr/local/bin/rust_aztfexport_rename

# Install nodejs nvm node version manager
ENV NODE_VERSION=22
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

# ENTRYPOINT [ "/entrypoint-default.sh" ]
CMD [ "/usr/bin/env", "bash" ]
