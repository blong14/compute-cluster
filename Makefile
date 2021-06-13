PACKAGES := . ./cmd/... ./pkg/...
GOBIN    := $(PWD)/bin

.DEFAULT_GOAL := test-and-lint

$(shell mkdir -p .deps)

.deps/go: go.mod go.sum vendor/modules.txt
	go mod vendor
	@touch $@

.PHONY: clean
clean:
	go clean
	@rm -rf .deps/* || true

.PHONY: build
build:
	GOOS=linux GOARCH=arm64 go install cluster

.PHONE: test-and-lint

test-and-lint: test lint

.PHONY: test
test: .deps/go
	go test -v -cover -race ./...

cover: .deps/go
	@rm -rf cover-all.out
	$(foreach pkg, $(PACKAGES), $(MAKE) cover-pkg PKG=$(pkg) || true;)
	@grep mode: cover.out > coverage.out
	@cat cover-all.out >> coverage.out
	go tool cover -html=coverage.out -o cover.html
	@rm -rf cover.out cover-all.out coverage.out

cover-pkg: .deps/go
	go test -coverprofile cover.out $(PKG)
	@grep -v mode: cover.out >> cover-all.out

.PHONY: lint
lint: .deps/go
	go fmt ./...
	go vet ./...