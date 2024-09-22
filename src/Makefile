BIN      := $(PWD)/../bin
PACKAGES := . ./cmd/... ./internal/...

.DEFAULT_GOAL := test-and-lint

$(shell mkdir -p .deps)

.deps/go: go.mod go.sum vendor/modules.txt
	go mod vendor
	@touch $@

.PHONY: clean
clean:
	go clean
	@rm -rf .deps/* || true

build-go: .deps/go
	@echo "[build] building go code..."
	go install cluster

build-zig:
	@echo "[build] building zig code..."
	zig build -p ..

.PHONY: build
build: build-go build-zig
	@echo "[build] complete..."

.PHONE: test-and-lint

test-and-lint: test lint

test-go: .deps/go
	@echo "[test] testing go code..."
	go test -v -cover -race ./...

test-zig:
	@echo "[test] testing zig code..."
	zig build test-zagent

.PHONY: test
test: test-go test-zig
	@echo "[test] complete..."

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

lint-zig: 
	@echo "[lint] linting zig code..."
	zig fmt .

lint-go: .deps/go
	@echo "[lint] linting go code..."
	go fmt ./...
	go vet ./...

.PHONY: lint
lint: lint-go lint-zig
	@echo "[lint] complete..."
