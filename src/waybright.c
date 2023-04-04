#include <stdlib.h>
// #include <wlr/types/wlr_compositor.h>
// #include <wlr/render/wlr_texture.h>
#include "./waybright.h"

struct waybright_monitor* waybright_monitor_create() {
    return calloc(sizeof(struct waybright_monitor), 1);
}

void waybright_monitor_destroy(struct waybright_monitor* wb_monitor) {
    if (!wb_monitor) return;

    wlr_output_destroy(wb_monitor->wlr_output);

    free(wb_monitor);
}

void waybright_monitor_set_event_handler(struct waybright_monitor* wb_monitor, void(*event_handler)(int event_type, void* data)) {
    wb_monitor->handle_event = event_handler;
}

struct wlr_output_mode* get_wlr_output_mode_from_wl_list(struct wl_list *ptr) {
    return wl_container_of(ptr, (struct wlr_output_mode*)NULL, link);
}

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

void handle_monitor_remove_event(struct wl_listener *listener, void *data) {
    struct waybright_monitor* wb_monitor = wl_container_of(listener, wb_monitor, listeners.remove);
    // struct wlr_output *wlr_output = data;

    if (wb_monitor->handle_event)
        wb_monitor->handle_event(event_type_monitor_remove, wb_monitor);

    waybright_monitor_destroy(wb_monitor);
}

void handle_monitor_frame_event(struct wl_listener *listener, void *data) {
    struct waybright_monitor* wb_monitor = wl_container_of(listener, wb_monitor, listeners.frame);
    // struct wlr_output *wlr_output = data;

    if (wb_monitor->handle_event)
        wb_monitor->handle_event(event_type_monitor_frame, wb_monitor);
}

void handle_monitor_add_event(struct wl_listener *listener, void *data) {
    struct waybright* wb = wl_container_of(listener, wb, listeners.monitor_add);
    struct wlr_output *wlr_output = data;

	wlr_output_init_render(wlr_output, wb->wlr_allocator, wb->wlr_renderer);

    struct waybright_monitor* wb_monitor = waybright_monitor_create();
    wb_monitor->wb = wb;
    wb_monitor->wlr_output = wlr_output;

    wb_monitor->listeners.remove.notify = handle_monitor_remove_event;
    wl_signal_add(&wb_monitor->wlr_output->events.destroy, &wb_monitor->listeners.remove);
    wb_monitor->listeners.frame.notify = handle_monitor_frame_event;
    wl_signal_add(&wb_monitor->wlr_output->events.frame, &wb_monitor->listeners.frame);

    if (wb->handle_event)
        wb->handle_event(event_type_monitor_add, wb_monitor);
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

    wb->listeners.monitor_add.notify = handle_monitor_add_event;
    wl_signal_add(&wb->wlr_backend->events.new_output, &wb->listeners.monitor_add);

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

void waybright_set_event_handler(struct waybright* wb, void(*event_handler)(int event_type, void* data)) {
    wb->handle_event = event_handler;
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

void waybright_run_event_loop(struct waybright* wb) {
    wl_display_run(wb->wl_display);
}
