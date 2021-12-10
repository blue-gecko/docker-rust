FROM debian:bullseye-slim

RUN apt-get update -y; \
    apt-get upgrade -y; \
    apt-get install -y --no-install-recommends \
    ca-certificates \
    build-essential \
    cmake \
    patch \
    clang \
    wget \
    curl \
    git \
    sudo \
    ssh \
    pkg-config \
    openssl \
    libssl-dev \
    libxml2-dev \
    zlib1g-dev \
    lzma-dev \
    llvm-dev \
    uuid-dev \
    libmpc-dev \
    libmpfr-dev \
    libgmp-dev \
    lldb \
    gpg \
    gnupg2 \
    mingw-w64 \
    libsqlite3-dev \
    sqlite3 \
    ;

# Mac OS X SDK version
ARG OSX_SDK_VERSION=11.3
ARG OSX_SDK_SUM=9adc1373d3879e1973d28ad9f17c9051b02931674a3ec2a2498128989ece2cb1
ARG OSX_VERSION_MIN=10.14

# Install OS X Cross
# A Mac OS X cross toolchain for Linux, FreeBSD, OpenBSD and Android
RUN set -eux \
    && echo "Cloning osxcross..." \
    && git clone https://github.com/tpoechtrager/osxcross.git /usr/local/osxcross \
    && cd /usr/local/osxcross \
    && rm -rf ./.git \
    && true

# Build OS X Cross
RUN set -eux \
    && echo "Building osxcross with ${OSX_SDK_VERSION}..." \
    && cd /usr/local/osxcross \
    && curl -Lo "./tarballs/MacOSX${OSX_SDK_VERSION}.sdk.tar.xz" \
    "https://github.com/joseluisq/macosx-sdks/releases/download/${OSX_SDK_VERSION}/MacOSX${OSX_SDK_VERSION}.sdk.tar.xz" \
    && echo "${OSX_SDK_SUM} ./tarballs/MacOSX${OSX_SDK_VERSION}.sdk.tar.xz" | sha256sum -c - \
    && env UNATTENDED=yes OSX_VERSION_MIN=${OSX_VERSION_MIN} ./build.sh \
    && rm -rf *~ taballs *.tar.xz \
    && rm -rf /tmp/* \
    && true

# Add OS X Cross to PATH
ENV PATH=$PATH:/usr/local/osxcross/target/bin

# Add a user `dev` so that you're not developing as the `root` user
# The user needs to sudoer be able to install code-server
RUN adduser --gecos '/usr/bin/bash' --disabled-password dev && \
    echo "dev ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/nopasswd
ENV SHELL bash

ENV RUSTUP_HOME=/usr/local/rustup \
    CARGO_HOME=/usr/local/cargo \
    PATH=/usr/local/cargo/bin:$PATH \
    RUST_VERSION=1.57.0

RUN set -eux; \
    rustArch='x86_64-unknown-linux-gnu'; \
    rustupSha256='3dc5ef50861ee18657f9db2eeb7392f9c2a6c95c90ab41e45ab4ca71476b4338';  \
    url="https://static.rust-lang.org/rustup/archive/1.24.3/${rustArch}/rustup-init"; \
    wget "$url"; \
    echo "${rustupSha256} *rustup-init" | sha256sum -c -; \
    chmod +x rustup-init; \
    ./rustup-init -y --no-modify-path --profile minimal --default-toolchain $RUST_VERSION --default-host ${rustArch}; 

RUN rm rustup-init; 

RUN rustup --version; \
    cargo --version; \
    rustc --version; 

RUN chmod -R a+w,o+rwX $RUSTUP_HOME $CARGO_HOME;

# Create USER environment variable to prevent "could not determine the current user, please set $USER" error when running "cargo new ..."
# USER dev
# ENV USER dev

# Install stable and nightly toolchain and components
RUN rustup set profile default; \
    rustup toolchain install $RUST_VERSION --component rust-docs rustfmt clippy rust-analysis rust-src rls; \
    rustup toolchain install stable --component rust-docs rustfmt clippy rust-analysis rust-src rls; \
    rustup toolchain install nightly --component rust-docs rustfmt clippy rust-analysis rust-src rls; \
    rustup default $RUST_VERSION; \
    rustup completions bash rustup >> /etc/bash_completion.d/rustup; \
    rustup completions bash cargo >> /etc/bash_completion.d/cargo;

# Install cargo extensions
RUN cargo install nu; \ 
    cargo install cargo-tarpaulin; \
    cargo install cargo-criterion; \
    cargo install cargo-watch; \ 
    cargo install drill; \ 
    cargo install diesel_cli --no-default-features --features "sqlite"; \ 
    diesel completions bash > /etc/bash_completion.d/diesel;

# Create and set working directory
RUN mkdir -p /home/dev/src/rust
WORKDIR /home/dev/src/rust

# Install windows target (using mingw)
RUN set -eux; \
    rustup target add x86_64-pc-windows-gnu; \
    mkdir /root/.cargo; \
    echo "[target.x86_64-pc-windows-gnu]\nlinker = \"/usr/bin/x86_64-w64-mingw32-gcc\"\nar = \"/usr/bin/x86_64-w64-mingw32-ar\"" >> /root/.cargo/config.toml; \
    ln -s /root/.cargo /home/dev/src/rust/.cargo; 

# Install MacOS target
RUN set -eux; \
    rustup target add x86_64-apple-darwin; \
    echo "\n[target.x86_64-apple-darwin]\nlinker = \"x86_64-apple-darwin20.4-clang\"\nar = \"x86_64-apple-darwin20.4-ar\"" >> /root/.cargo/config.toml; 

# Expose ports for webservices
EXPOSE 80 8000 8001 8080 8081

# Start bash shell running
CMD ["/bin/bash"]
