CC = gcc
CFLAGS = -Wall
LDFLAGS = -Lvendor/vcpkg/installed/x64-linux/lib -lrabbitmq
INCLUDES = -Ivendor/vcpkg/installed/x64-linux/include

.deps/setup:
	@mkdir .deps
	@touch $@

.deps/vcpkg: .deps/setup
	@mkdir vendor
	@git clone https://github.com/Microsoft/vcpkg.git vendor/vcpkg
	./vendor/vcpkg/bootstrap-vcpkg.sh
	./vendor/vcpkg/vcpkg integrate install
	@touch $@

.deps/librabbitmq: .deps/vcpkg
	./vendor/vcpkg/vcpkg install librabbitmq
	@touch $@

.deps: .deps/librabbitmq
	@echo "dependecies installed"
	@touch $@

default: all

TARGET = logconsumer

all: .deps $(TARGET)

$(TARGET): *.c
	$(CC) $(CFLAGS) $(INCLUDES) -o $@ $^ $(LDFLAGS)

clean:
	@rm -rf .deps
	@rm -rf vendor
	@rm -f $(TARGET)
