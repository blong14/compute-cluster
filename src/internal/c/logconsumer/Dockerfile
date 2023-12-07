FROM debian:bookworm as build

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

COPY Makefile /app/Makefile
COPY main.c /app/main.c

RUN make all

FROM debian:bookworm-slim

WORKDIR app

COPY --from=build /app/logconsumer /app/logconsumer

CMD ["/app/logconsumer"]
