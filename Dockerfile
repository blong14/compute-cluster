FROM golang:1.16-bullseye AS go-build

RUN apt-get update

WORKDIR /go/src

COPY . /go/src
RUN make build-go

FROM debian:bullseye-slim

RUN apt update && \
    apt install -y ca-certificates postgresql-client

COPY --from=go-build /go/bin/cluster /go/bin/cluster

CMD /go/bin/cluster

