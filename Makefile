EXECUTABLE=waybright

build/$(EXECUTABLE): build/waybright.so lib/src/waybright_bindings.dart bin/waybright.dart lib/waybright.dart
	@mkdir -p build
	dart compile exe bin/waybright.dart -o build/$(EXECUTABLE)

build-deps: build/waybright.so lib/src/waybright_bindings.dart

so: build/waybright.so # shorthand
build/waybright.so: lib/src/waybright.c
	@mkdir -p build
	cc -shared -o build/waybright.so lib/src/waybright.c \
	-Wall -DWLR_USE_UNSTABLE -fPIC \
	$(shell pkg-config --libs wayland-server) \
	$(shell pkg-config --libs wlroots) \
	$(shell pkg-config --libs cairo) \
	$(shell pkg-config --libs libdrm)

dart: lib/src/waybright_bindings.dart # shorthand
lib/src/waybright_bindings.dart: lib/src/waybright.h
	dart run ffigen

clean:
	rm -rf lib/src/waybright_bindings.dart build/
