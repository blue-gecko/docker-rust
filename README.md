# Rust command-line tools

Includes cargo components (format, clippy, source, docs, analysis, language server)
Also includes tarpaulin code coverage tool

`/usr/local/bin/docker run -e USER=$USER -it --security-opt seccomp=unconfined -v $(pwd):/usr/src/rust:delegated --name=rust-dev --hostname=rust-dev --rm bluegecko/rust:latest /bin/bash`

Opens with a bash shell, closes and cleans up on exit (remove `--rm` to leave container available for `start` and `attach`).
