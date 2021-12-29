FROM ubuntu:20.04
LABEL maintainer="Matt Hughes <matt.c.hughes@gmail.com>"
ARG user
ARG userid
ARG groupid

RUN apt-get update && apt-get install -y curl gcc-arm-linux-gnueabihf gcc sudo rsync ssh

RUN addgroup --gid ${groupid} $user && useradd -m --uid ${userid} --gid ${groupid} $user
RUN echo "${user} ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/nopasswd

ENV RUST_VERSION 1.57.0
ENV TARGET_NAME armv7-unknown-linux-gnueabihf

USER ${userid}:${groupid}
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --profile minimal --default-toolchain "${RUST_VERSION}" \
    && $HOME/.cargo/bin/rustup target add ${TARGET_NAME}

