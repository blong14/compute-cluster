FROM golang:1.14-buster AS go-build

RUN apt-get update

COPY . /go/src

WORKDIR /go/src

RUN make build

FROM debian:buster-slim

RUN apt update && apt install -y ca-certificates

COPY --from=go-build /go/bin/linux_arm64/cluster /go/bin/cluster

CMD /go/bin/cluster

