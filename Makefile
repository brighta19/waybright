lib/waybright.so: src/waybright.c
	cc -shared -o lib/waybright.so src/waybright.c \
	-Wall -DWLR_USE_UNSTABLE \
	$(shell pkg-config --libs wayland-server) \
	$(shell pkg-config --libs wlroots) \

clean:
	rm -rf lib/waybright.so
