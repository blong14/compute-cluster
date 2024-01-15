FROM debian:bookworm as build

ARG ARCH=x86_64
ARG ZIG_VERSION=0.11.0
ARG ZIG_URL=https://ziglang.org/download/${ZIG_VERSION}/zig-linux-${ARCH}-${ZIG_VERSION}.tar.xz
ARG ZIG_SHA256=b378d0aae30cb54f28494e7bc4efbc9bfb6326f47bfb302e8b5287af777b2f3c

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

RUN curl -o zig.tar.xz "$ZIG_URL" && \
    tar -xf zig.tar.xz -C /usr/local/bin --strip-components 1

WORKDIR /app

COPY . /app

RUN make build-zig

CMD ["zig"]

FROM debian:bookworm-slim

WORKDIR app

COPY --from=build /app/bin/zcluster /usr/local/bin

CMD ["zcluster"]
