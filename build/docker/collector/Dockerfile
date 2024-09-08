FROM golang:1.23-bookworm as build

WORKDIR /app

COPY src /app

RUN make build-go

FROM debian:bookworm-slim

WORKDIR /app

COPY --from=build /go/bin/cluster /usr/local/bin/cluster

CMD ["cluster", "run", "collector"]
