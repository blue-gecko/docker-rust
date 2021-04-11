FROM rust:1.51-buster

## Set profile to Default
RUN rustup set profile default

## Install extensions dependencies
RUN rustup component add rust-analysis
RUN rustup component add rust-src
RUN rustup component add rls
RUN rustup component add rustfmt
RUN rustup component add clippy
RUN rustup component add rust-docs
RUN rustup component add rust-analysis

## Install stable toolchain
RUN rustup toolchain install stable-x86_64-unknown-linux-gnu

RUN cargo install cargo-tarpaulin

WORKDIR /usr/src/rust

CMD ["/bin/bash"]
