# Define the platform as a build argument with a default value
ARG PLATFORM=linux/amd64
#--------------------------------------------------------
# Stage 1: Build the Rust executable
FROM --platform=${PLATFORM} rust:slim-bullseye AS build_rust_aztfexport_rename
WORKDIR /app
# Copy the Rust project files into the container
COPY ./src/rust_aztfexport_rename /app
# Run tests to ensure the code is correct
RUN cargo test --release --locked --all-targets --all-features
# Build the Rust project in release mode
RUN cargo build --release

#--------------------------------------------------------
# Stage 2: Final image
FROM --platform=${PLATFORM} docker.io/debian:bullseye-slim

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
        build-essential krb5-multidev \
    && rm -rf /var/lib/apt/lists/* \
    && echo "# apt done." \
    && echo "#Built @ $(date -Is)" >> /info-built.txt

# Pin uv and hardcode archive checksums (from the GitHub release assets) 2025-08
ARG UV_VERSION=0.9.15 # 2025-12-02
ARG UV_SHA256_X64="2053df0089327569cddd6afea920c2285b482d9b123f5db9f658273e96ab792c"
ARG UV_SHA256_AARCH64="d89430e201f629b203975c605cd6bfe85afc2bc0781d95838e2b5177a03b1545"

RUN set -eux; \
    arch="$(uname -m)"; \
    case "$arch" in \
        x86_64|amd64) target="x86_64-unknown-linux-gnu"; sha256="${UV_SHA256_X64}";; \
        aarch64|arm64) target="aarch64-unknown-linux-gnu"; sha256="${UV_SHA256_AARCH64}";; \
        *) echo "unsupported arch: $arch"; exit 1;; \
    esac; \
    base="https://github.com/astral-sh/uv/releases/download/${UV_VERSION}"; \
    asset="uv-${target}.tar.gz"; \
    curl -fsSLo /tmp/uv.tar.gz "${base}/${asset}"; \
    echo "${sha256}  /tmp/uv.tar.gz" | sha256sum -c -; \
    tmpdir="$(mktemp -d)"; \
    tar -xzf /tmp/uv.tar.gz -C "$tmpdir"; \
    install -m 0755 "$tmpdir"/uv /usr/local/bin/uv 2>/dev/null || install -m 0755 "$tmpdir"/*/uv /usr/local/bin/uv; \
    rm -rf "$tmpdir" /tmp/uv.tar.gz; \
    /usr/local/bin/uv --version


# Create python venv with uv
ENV VIRTUAL_ENV=/opt/venv
RUN mkdir -p ${VIRTUAL_ENV}
RUN uv venv ${VIRTUAL_ENV}
ENV PATH="${VIRTUAL_ENV}/bin:$PATH"
ENV UV_PY="${VIRTUAL_ENV}/bin/python"

# Install Python packages with uv (no pip needed)
RUN uv pip install --python "${UV_PY}" pykerberos
RUN uv pip install --python "${UV_PY}" "pywinrm[kerberos]" pywinrm requests
RUN uv pip install --python "${UV_PY}" jmespath

# Verify kerberos import at build time
RUN "${UV_PY}" -c "import kerberos; import sys; print('pykerberos OK', getattr(kerberos,'__version__', '?'), sys.version)"

# Azure CLI
RUN curl -fsSL https://aka.ms/InstallAzureCLIDeb | bash

# Ansible and Azure collection deps
RUN uv pip install --python "${UV_PY}" ansible
# https://galaxy.ansible.com/ui/repo/published/azure/azcollection/ #3.12.0 error ??
RUN ansible-galaxy collection install azure.azcollection==3.4.0 --force
RUN uv pip install --python "${UV_PY}" -r ${HOME}/.ansible/collections/ansible_collections/azure/azcollection/requirements.txt

# Install AWS cli
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip" &&\
    unzip /tmp/awscliv2.zip -d /tmp &&\
    /tmp/aws/install &&\
    rm -rf /tmp/aws*

# Install terraform switcher
# https://tfswitch.warrensbox.com/Install/
# Simplify tfswitch install ADD will extract local binary from tar.gz
ADD src/terraform_switch/terraform-switcher_v1.10.0_linux_amd64.tar.gz /tmp/tfswitch
RUN ls -l /tmp/tfswitch && mv /tmp/tfswitch/tfswitch /usr/local/bin/tfswitch && chmod +x /usr/local/bin/tfswitch
RUN tfswitch --latest

# Install k8s kubectl
RUN curl -L "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" -o /usr/local/bin/kubectl && chmod +x /usr/local/bin/kubectl

# Install rust
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
# Copy the Rust binary from the build_rust_aztfexport_rename stage
COPY --from=build_rust_aztfexport_rename /app/target/release/rust_aztfexport_rename /usr/local/bin/rust_aztfexport_rename

# Install nodejs nvm node version manager
ENV NODE_VERSION=22
ENV NVM_DIR="/usr/local/nvm"
RUN mkdir -p $NVM_DIR
# NVM tag=v0.40.3 2025-04-24 - commit "977563e97ddc66facf3a8e31c6cff01d236f09bd"
COPY src/nvm_node_installer/nvm_v0.40.3_20250424.sh $NVM_DIR/nvm.sh
RUN \. "$NVM_DIR/nvm.sh" \
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
