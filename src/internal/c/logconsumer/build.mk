LDFLAGS += -lrabbitmq
TARGET = logconsumer

.deps/$(TARGET): .deps 
	./vendor/vcpkg/vcpkg install librabbitmq
	@touch $@

$(TARGET): .deps/$(TARGET) $(SRCS) $(TARGET)/main.c
	$(CC) $(CFLAGS) $(INCLUDES) -o .bin/$@ $^ $(LDFLAGS)

