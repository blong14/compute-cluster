ARCH ?= x64
CC = gcc
CFLAGS = -Wall -Wextra
LDFLAGS = -Lvendor/vcpkg/installed/$(ARCH)-linux/lib
INCLUDES = -I$(PWD) -Ivendor/vcpkg/installed/$(ARCH)-linux/include
SRCS = *.c

.deps/setup:
	@mkdir .deps
	@mkdir .bin
	@touch $@

.deps/vcpkg: .deps/setup
	@mkdir vendor
	@git clone https://github.com/Microsoft/vcpkg.git vendor/vcpkg
	./vendor/vcpkg/bootstrap-vcpkg.sh
	./vendor/vcpkg/vcpkg integrate install
	@touch $@

.deps: .deps/vcpkg
	@echo "Installed dependencies"
	@touch $@

include $(wildcard */build.mk)

.PHONY: clean
clean:
	@rm -rf .bin 
	@rm -rf .deps
	@rm -rf vendor

