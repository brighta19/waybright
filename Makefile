WAYLAND_PROTOCOLS=$(shell pkg-config --variable=pkgdatadir wayland-protocols)
WAYLAND_SCANNER=$(shell pkg-config --variable=wayland_scanner wayland-scanner)
LIBS=$(shell pkg-config --cflags --libs wayland-server) \
	$(shell pkg-config --cflags --libs wlroots) \
	$(shell pkg-config --cflags --libs cairo) \
	$(shell pkg-config --cflags --libs libdrm)
EXAMPLES=$(shell find example -name '*.dart' -exec basename -s .dart {} \;)

build-examples: $(EXAMPLES)

$(EXAMPLES): build/waybright.so lib/src/generated/waybright_bindings.dart
	dart compile exe example/$@.dart -o build/$@

build-deps: build/waybright.so lib/src/generated/waybright_bindings.dart

lib/src/native/xdg-shell-protocol.h:
	$(WAYLAND_SCANNER) server-header \
	$(WAYLAND_PROTOCOLS)/stable/xdg-shell/xdg-shell.xml \
	lib/src/native/xdg-shell-protocol.h

so: build/waybright.so # shorthand
build/waybright.so: lib/src/native/xdg-shell-protocol.h lib/src/native/waybright.c
	@mkdir -p build
	cc -shared -o build/waybright.so lib/src/native/waybright.c \
	-Wall -DWLR_USE_UNSTABLE -fPIC -Ilib/src/native/ $(LIBS)

dart: lib/src/generated/waybright_bindings.dart # shorthand
lib/src/generated/waybright_bindings.dart: lib/src/native/xdg-shell-protocol.h lib/src/native/waybright.h
	dart run ffigen

clean:
	rm -rf lib/src/generated/waybright_bindings.dart lib/src/native/xdg-shell-protocol.h build/

.PHONY: build-examples
