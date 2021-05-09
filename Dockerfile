FROM debian:buster-slim

RUN apt-get update -y; \
    apt-get upgrade -y; \
    apt-get install -y --no-install-recommends \
    ca-certificates \
    gcc \
    libc6-dev \
    wget \
    pkg-config \
    openssl \
    libssl-dev \
    curl \
    git \
    sudo \
    build-essential \
    lldb \
    ;

# Add a user `rustdev` so that you're not developing as the `root` user
# The user needs to sudoer be able to install code-server
RUN adduser --gecos '/usr/bin/bash' --disabled-password dev && \
    echo "dev ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/nopasswd
ENV SHELL bash

ENV RUSTUP_HOME=/usr/local/rustup \
    CARGO_HOME=/usr/local/cargo \
    PATH=/usr/local/cargo/bin:$PATH \
    RUST_VERSION=1.52.0

RUN set -eux; \
    dpkgArch="$(dpkg --print-architecture)"; \
    case "${dpkgArch##*-}" in \ 
    amd64) rustArch='x86_64-unknown-linux-gnu'; rustupSha256='fb3a7425e3f10d51f0480ac3cdb3e725977955b2ba21c9bdac35309563b115e8' ;; \
    armhf) rustArch='armv7-unknown-linux-gnueabihf'; rustupSha256='f263e170da938888601a8e0bc822f8b40664ab067b390cf6c4fdb1d7c2d844e7' ;; \
    arm64) rustArch='aarch64-unknown-linux-gnu'; rustupSha256='de1dddd8213644cba48803118c7c16387838b4d53b901059e01729387679dd2a' ;; \
    i386) rustArch='i686-unknown-linux-gnu'; rustupSha256='66c03055119cecdfc20828c95429212ae5051372513f148342758bb5d0130997' ;; \
    esac; \
    url="https://static.rust-lang.org/rustup/archive/1.24.1/${rustArch}/rustup-init"; \
    wget "$url"; \
    echo "${rustupSha256} *rustup-init" | sha256sum -c -; \
    chmod +x rustup-init; \
    ./rustup-init -y --no-modify-path --profile default --default-toolchain $RUST_VERSION --default-host ${rustArch}; 

RUN rm rustup-init; 

RUN rustup --version; \
    cargo --version; \
    rustc --version; 

RUN chmod -R a+w,o+rwX $RUSTUP_HOME $CARGO_HOME;

USER dev
# Create USER environment variable to prevent "could not determine the current user, please set $USER" error when running "cargo new ..."
ENV USER dev

# ## Install extensions dependencies
RUN rustup component add rust-analysis 
RUN rustup component add rust-src 
RUN rustup component add rls 

RUN cargo install cargo-tarpaulin

RUN mkdir -p /home/dev/src/rust
WORKDIR /home/dev/src/rust

CMD ["/bin/bash"]
