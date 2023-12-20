LDFLAGS += -lcjson -lrabbitmq
TARGET = logconsumer

.deps/$(TARGET): .deps 
	./vendor/vcpkg/vcpkg install cjson librabbitmq
	@touch $@

$(TARGET): .deps/$(TARGET) $(SRCS) $(TARGET)/main.c
	$(CC) $(CFLAGS) $(INCLUDES) -o .bin/$@ $^ $(LDFLAGS)

