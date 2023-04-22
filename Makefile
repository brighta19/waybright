EXECUTABLE=waybright
WAYLAND_PROTOCOLS=$(shell pkg-config --variable=pkgdatadir wayland-protocols)
WAYLAND_SCANNER=$(shell pkg-config --variable=wayland_scanner wayland-scanner)
LIBS=$(shell pkg-config --libs wayland-server) \
	$(shell pkg-config --libs wlroots) \
	$(shell pkg-config --libs cairo) \
	$(shell pkg-config --libs libdrm)

build/$(EXECUTABLE): build/waybright.so lib/src/generated/waybright_bindings.dart bin/waybright.dart lib/*
	@mkdir -p build
	dart compile exe bin/waybright.dart -o build/$(EXECUTABLE)

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
