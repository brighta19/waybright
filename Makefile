EXECUTABLE=waybright

build/$(EXECUTABLE): lib/waybright.so lib/waybright_bindings.dart bin/waybright.dart lib/waybright.dart
	@mkdir -p build
	dart compile exe bin/waybright.dart -o build/$(EXECUTABLE)

build-deps: lib/waybright.so lib/waybright_bindings.dart

lib/waybright.so: src/waybright.c
	cc -shared -o lib/waybright.so src/waybright.c \
	-Wall -DWLR_USE_UNSTABLE -fPIC \
	$(shell pkg-config --libs wayland-server) \
	$(shell pkg-config --libs wlroots)

lib/waybright_bindings.dart: src/waybright.h
	dart run ffigen

clean:
	rm -rf lib/waybright.so lib/waybright_bindings.dart build/
