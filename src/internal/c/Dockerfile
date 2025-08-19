FROM debian:trixie as build

RUN apt-get update && apt-get install -y \
    build-essential \
    cmake \
    curl \
    git \
    ninja-build \
    pkg-config \
    tar \
    unzip \
    zip

WORKDIR app

ARG SRVC=logconsumer
ARG ARCH=x64

ENV VCPKG_FORCE_SYSTEM_BINARIES true

COPY Makefile /app
RUN make .deps

COPY . /app
RUN ARCH=${ARCH} make ${SRVC}

FROM debian:bookworm-slim

WORKDIR app

COPY --from=build /app/.bin/${SRVC} /app/${SRVC}

CMD ["ls"]
