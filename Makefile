WAYLAND_PROTOCOLS=$(shell pkg-config --variable=pkgdatadir wayland-protocols)
WAYLAND_SCANNER=$(shell pkg-config --variable=wayland_scanner wayland-scanner)
LIBS=$(shell pkg-config --cflags --libs wayland-server) \
	$(shell pkg-config --cflags --libs wlroots)
SOURCE_FILES=$(shell echo lib/src/native/*.c)

build-deps: build/waybright.so lib/src/generated/waybright_bindings.dart

lib/src/native/xdg-shell-protocol.h:
	$(WAYLAND_SCANNER) server-header \
	$(WAYLAND_PROTOCOLS)/stable/xdg-shell/xdg-shell.xml \
	lib/src/native/xdg-shell-protocol.h

so: build/waybright.so # shorthand
build/waybright.so: lib/src/native/xdg-shell-protocol.h $(SOURCE_FILES)
	@mkdir -p build
	cc -shared -o build/waybright.so $(SOURCE_FILES) \
		-Wall -DWLR_USE_UNSTABLE -fPIC -Ilib/src/native/ $(LIBS)
	@cp build/waybright.so example/waybright.so

dart: lib/src/generated/waybright_bindings.dart # shorthand
lib/src/generated/waybright_bindings.dart: lib/src/native/xdg-shell-protocol.h\
lib/src/native/waybright.h
	dart run ffigen

clean:
	rm -rf lib/src/generated/waybright_bindings.dart \
		lib/src/native/xdg-shell-protocol.h build/

.PHONY: build-examples
