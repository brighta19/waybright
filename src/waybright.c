
// #include <wlr/types/wlr_compositor.h>
// #include <wlr/types/wlr_output.h>
// #include <wlr/render/allocator.h>
// #include <wlr/render/wlr_renderer.h>
// #include <wlr/render/wlr_texture.h>

#include "./waybright.h"

struct waybright* waybright_create() {
    return calloc(sizeof(struct waybright), 1);
}

void waybright_destroy(struct waybright* wb) {
    if (wb)
        free(wb);
}

int waybright_init(struct waybright* wb) {
    wb->display = wl_display_create();
    if (!wb->display)
        return 1;

    // Initialize wlroots backend
    // wb->wlr_backend = wlr_backend_autocreate(wb->display);
    // if (!wb->wlr_backend)
    //     return 1;

    // wl_list_init(&wb->displays);
    // wl_list_init(&wb->views);

    // wb->listeners.display_add.notify = on_display_add;
    // wl_signal_add(&wb->backend->events.new_output, &wb->listeners.display_add);

    // // Initialize renderer
    // wb->renderer = rimeru_renderer_create();
    // rimeru_renderer_init(wb->renderer, wb);

    // // Initialize allocator
    // wb->allocator = wlr_allocator_autocreate(wb->backend, wb->renderer->wlr_renderer);
    // assert(wb->allocator);

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

int waybright_open_socket(struct waybright* wb) {
	// if (!wlr_backend_start(wb->wlr_backend)) {
	// 	wlr_backend_destroy(wb->wlr_backend);
    //     return 1;
	// }

    wb->socket_name = wl_display_add_socket_auto(wb->display);
    return wb->socket_name == NULL;
}

int waybright_open_socket_with_name(struct waybright* wb, const char* name) {
    wb->socket_name = name;
    return wl_display_add_socket(wb->display, name);
}

void waybright_run(struct waybright* wb) {
    wl_display_run(wb->display);
}