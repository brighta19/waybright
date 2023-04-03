#include <stdlib.h>
// #include <wlr/types/wlr_compositor.h>
// #include <wlr/types/wlr_output.h>
// #include <wlr/render/wlr_texture.h>
#include "./waybright.h"

struct waybright* waybright_create() {
    return calloc(sizeof(struct waybright), 1);
}

void waybright_destroy(struct waybright* wb) {
    if (!wb) return;

    wlr_allocator_destroy(wb->wlr_allocator);
    wlr_renderer_destroy(wb->wlr_renderer);
    wlr_backend_destroy(wb->wlr_backend);
    wl_display_destroy_clients(wb->wl_display);
    wl_display_destroy(wb->wl_display);

    free(wb);
}

int waybright_init(struct waybright* wb) {
    if (!getenv("XDG_RUNTIME_DIR"))
        return 1;

    wb->wl_display = wl_display_create();
    if (!wb->wl_display)
        return 1;

    wb->wlr_backend = wlr_backend_autocreate(wb->wl_display);
    if (!wb->wlr_backend)
        return 1;

    wb->wlr_renderer = wlr_renderer_autocreate(wb->wlr_backend);
    if (!wb->wlr_renderer)
        return 1;

    wlr_renderer_init_wl_display(wb->wlr_renderer, wb->wl_display);

    wb->wlr_allocator = wlr_allocator_autocreate(wb->wlr_backend, wb->wlr_renderer);
    if (!wb->wlr_allocator)
        return 1;

    // wl_list_init(&wb->displays);
    // wl_list_init(&wb->views);

    // wb->listeners.display_add.notify = on_display_add;
    // wl_signal_add(&wb->backend->events.new_output, &wb->listeners.display_add);


    // // Initialize compositor
    // wb->compositor = wlr_compositor_create(wb->display, wb->renderer->wlr_renderer);
    // assert(wb->compositor);

    // // Initialize xdg-shell
    // wb->xdg_shell = wlr_xdg_shell_create(wb->display);
    // assert(wb->xdg_shell);
    // wb->listeners.new_xdg_surface.notify = on_new_xdg_surface;
    // wl_signal_add(&wb->xdg_shell->events.new_surface, &wb->listeners.new_xdg_surface);

    // init_signals(wb);

    return 0;
}

void waybright_set_handler(struct waybright* wb, int type, void(handler)()) {
    if (type == events_monitor_add) {
        wb->listeners.monitor_add.notify = handler;
        wl_signal_add(&wb->wlr_backend->events.new_output, &wb->listeners.monitor_add);
    }
}

int waybright_open_socket(struct waybright* wb, const char* socket_name) {
    if (socket_name) {
        if (wl_display_add_socket(wb->wl_display, socket_name) != 0) {
            wlr_backend_destroy(wb->wlr_backend);
            return 1;
        }

        wb->socket_name = socket_name;
    }
    else {
        wb->socket_name = wl_display_add_socket_auto(wb->wl_display);

        if (!wb->socket_name) {
            wlr_backend_destroy(wb->wlr_backend);
            return 1;
        }
    }

	if (!wlr_backend_start(wb->wlr_backend)) {
		wlr_backend_destroy(wb->wlr_backend);
        wl_display_destroy(wb->wl_display);
        return 1;
	}

    setenv("WAYLAND_DISPLAY", wb->socket_name, 1);
    return 0;
}

void waybright_run(struct waybright* wb) {
    wl_display_run(wb->wl_display);
}
