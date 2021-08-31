FROM debian:bullseye-slim

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
    ssh \
    gpg \
    gnupg2 \
    mingw-w64 \
    libsqlite3-dev \
    ;

# Add a user `rustdev` so that you're not developing as the `root` user
# The user needs to sudoer be able to install code-server
RUN adduser --gecos '/usr/bin/bash' --disabled-password dev && \
    echo "dev ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/nopasswd
ENV SHELL bash

ENV RUSTUP_HOME=/usr/local/rustup \
    CARGO_HOME=/usr/local/cargo \
    PATH=/usr/local/cargo/bin:$PATH \
    RUST_VERSION=1.54.0

RUN set -eux; \
    dpkgArch="$(dpkg --print-architecture)"; \
    case "${dpkgArch##*-}" in \ 
    amd64) rustArch='x86_64-unknown-linux-gnu'; rustupSha256='3dc5ef50861ee18657f9db2eeb7392f9c2a6c95c90ab41e45ab4ca71476b4338'; arch='x86_64' ;; \
    armhf) rustArch='armv7-unknown-linux-gnueabihf'; rustupSha256='67777ac3bc17277102f2ed73fd5f14c51f4ca5963adadf7f174adf4ebc38747b' ;; \
    arm64) rustArch='aarch64-unknown-linux-gnu'; rustupSha256='32a1532f7cef072a667bac53f1a5542c99666c4071af0c9549795bbdb2069ec1' ;; \
    i386) rustArch='i686-unknown-linux-gnu'; rustupSha256='e50d1deb99048bc5782a0200aa33e4eea70747d49dffdc9d06812fd22a372515'; arch='i686' ;; \
    *) echo >&2 "unsupported architecture: ${dpkgArch}"; exit 1 ;; \
    esac; \
    echo $arch > /root/arch; \
    url="https://static.rust-lang.org/rustup/archive/1.24.3/${rustArch}/rustup-init"; \
    wget "$url"; \
    echo "${rustupSha256} *rustup-init" | sha256sum -c -; \
    chmod +x rustup-init; \
    ./rustup-init -y --no-modify-path --profile default --default-toolchain $RUST_VERSION --default-host ${rustArch}; 

RUN rm rustup-init; 

RUN rustup --version; \
    cargo --version; \
    rustc --version; 

RUN chmod -R a+w,o+rwX $RUSTUP_HOME $CARGO_HOME;

# Create USER environment variable to prevent "could not determine the current user, please set $USER" error when running "cargo new ..."
# USER dev
# ENV USER dev

# Install extensions dependencies
RUN rustup component add rust-analysis 
RUN rustup component add rust-src 
RUN rustup component add rls 

RUN cargo install cargo-tarpaulin
RUN cargo install cargo-criterion
RUN cargo install diesel_cli --no-default-features --features "sqlite"
RUN diesel completions bash > /etc/bash_completion.d/diesel

RUN mkdir -p /home/dev/src/rust

# Install windows target
RUN set -eux; \
    arch=$(cat /root/arch ); \
    if ! [ -z ${arch} ]; then \
    rustup target add ${arch}-pc-windows-gnu; \
    mkdir /root/.cargo; \
    echo "[target.${arch}-pc-windows-gnu]\nlinker = \"/usr/bin/${arch}-w64-mingw32-gcc\"\nar = \"/usr/bin/${arch}-w64-mingw32-ar\"" >> /root/.cargo/config.toml; \
    ln -s /root/.cargo /home/dev/src/rust/.cargo; \
    fi;

WORKDIR /home/dev/src/rust

CMD ["/bin/bash"]
