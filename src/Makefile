PACKAGES := . ./cmd/... ./pkg/...
GOBIN    := $(PWD)/bin

.DEFAULT_GOAL := test-and-lint

$(shell mkdir -p .deps)

.deps/nim: compute_cluster.nimble
	nimble install
	nimble develop
	@touch $@

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

build-nim: .deps/nim
	@echo "[build] building nim code..."
	nimble c -d:release --threads:on -o:/nim/bin/ncluster --path:./pkg cmd/compute_cluster.nim

.PHONY: build
build: build-go build-nim
	@echo "[build] complete..."

.PHONE: test-and-lint

test-and-lint: test lint

test-go: .deps/go
	@echo "[test] testing go code..."
	go test -v -cover -race ./...

test-nim: .deps/nim
	@echo "[test] testing nim code..."
	nimble test --threads:on --path:./pkg

.PHONY: test
test: test-go test-nim
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

lint-go: .deps/go
	@echo "[lint] linting go code..."
	go fmt ./...
	go vet ./...

lint-nim: .deps/nim
	@echo "[lint] linting nim project..."
	nimble check

.PHONY: lint
lint: lint-go lint-nim
	@echo "[lint] complete..."
	
