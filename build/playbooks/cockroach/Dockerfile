FROM cockroachdb/bazel:20220328-163955 AS build

RUN apt-get update && \
    apt-get -y upgrade

WORKDIR /usr/local/src

COPY . /usr/local/src

RUN sh build.sh arm64

FROM ubuntu:22.04

RUN apt-get update && \
    apt-get -y upgrade && \
    apt-get install -y \
    ca-certificates \
    hostname \
    libc6 \
    tar \
    tzdata && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /cockroach/

COPY --from=build /usr/local/src/cockroach/artifacts/cockroach /cockroach/cockroach

ENTRYPOINT [ "/cockroach/cockroach" ]
