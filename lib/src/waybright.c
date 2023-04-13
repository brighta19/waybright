#include <drm/drm_fourcc.h>
#include <stdlib.h>
#include "./waybright.h"

int get_color_from_array(float* color_array) {
    return ((int)(color_array[0] * 0xff) << 16) +
        ((int)(color_array[1] * 0xff) << 8) +
        (color_array[2] * 0xff);
}

void set_color_to_array(int color, float* color_array) {
    color_array[0] = ((color & 0xff0000) >> 16) / (float)0xff;
    color_array[1] = ((color & 0x00ff00) >> 8) / (float)0xff;
    color_array[2] = (color & 0x0000ff) / (float)0xff;
    color_array[3] = 1.0;
}

void waybright_renderer_destroy(struct waybright_renderer* wb_renderer) {
    if (!wb_renderer) return;

    free(wb_renderer);
}

void waybright_monitor_destroy(struct waybright_monitor* wb_monitor) {
    if (!wb_monitor) return;

    waybright_renderer_destroy(wb_monitor->wb_renderer);

    free(wb_monitor);
}

void waybright_window_destroy(struct waybright_window* wb_window) {
    if (!wb_window) return;

    free(wb_window);
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

/// Seems to happen when the output is ready to display a frame AND if the compositor needs to display a frame (Ex. if a client commits a frame) ...
void handle_monitor_frame_event(struct wl_listener *listener, void *data) {
    struct waybright_monitor* wb_monitor = wl_container_of(listener, wb_monitor, listeners.frame);
    struct wlr_output *wlr_output = data;
    struct wlr_renderer* wlr_renderer = wb_monitor->wb->wlr_renderer;


    // I indicate that I want to render.
    if (!wlr_output_attach_render(wlr_output, NULL)) {
        return;
    }

    int width, height; // The will-be size of the new frame

    // "Computes the transformed and scaled output resolution."
    wlr_output_effective_resolution(wlr_output, &width, &height);

    // Time to start drawing! (what's the purpose of the width and height params? they don't seem to affect anything.)
    wlr_renderer_begin(wlr_renderer, width, height);

    // Fills the entire buffer with a single color.
    wlr_renderer_clear(wlr_renderer, wb_monitor->background_color);


    if (wb_monitor->handle_event)
        wb_monitor->handle_event(event_type_monitor_frame, wb_monitor);


    // I'm done drawing!
    wlr_renderer_end(wlr_renderer);

    // Submit my frame to the output.
    wlr_output_commit(wlr_output);
}

void handle_monitor_add_event(struct wl_listener *listener, void *data) {
    struct waybright* wb = wl_container_of(listener, wb, listeners.monitor_add);
    struct wlr_output *wlr_output = data;

	wlr_output_init_render(wlr_output, wb->wlr_allocator, wb->wlr_renderer);

    struct waybright_renderer* wb_renderer = calloc(sizeof(struct waybright_renderer), 1);
    wb_renderer->wlr_output = wlr_output;
    wb_renderer->wlr_renderer = wb->wlr_renderer;
    set_color_to_array(0x000000, wb_renderer->color_fill);

    struct waybright_monitor* wb_monitor = calloc(sizeof(struct waybright_monitor), 1);
    wb_monitor->wb = wb;
    wb_monitor->wb_renderer = wb_renderer;
    wb_monitor->wlr_output = wlr_output;

    wb_monitor->listeners.remove.notify = handle_monitor_remove_event;
    wl_signal_add(&wlr_output->events.destroy, &wb_monitor->listeners.remove);
    wb_monitor->listeners.frame.notify = handle_monitor_frame_event;
    wl_signal_add(&wlr_output->events.frame, &wb_monitor->listeners.frame);

    if (wb->handle_event)
        wb->handle_event(event_type_monitor_add, wb_monitor);
}

void handle_window_show_event(struct wl_listener *listener, void *data) {
    struct waybright_window* wb_window = wl_container_of(listener, wb_window, listeners.show);

    if (wb_window->handle_event)
        wb_window->handle_event(event_type_window_show, wb_window);
}

void handle_window_hide_event(struct wl_listener *listener, void *data) {
    struct waybright_window* wb_window = wl_container_of(listener, wb_window, listeners.hide);

    if (wb_window->handle_event)
        wb_window->handle_event(event_type_window_hide, wb_window);
}

void handle_window_remove_event(struct wl_listener *listener, void *data) {
    struct waybright_window* wb_window = wl_container_of(listener, wb_window, listeners.remove);

    if (wb_window->handle_event)
        wb_window->handle_event(event_type_window_remove, wb_window);

    waybright_window_destroy(wb_window);
}

void handle_window_add_event(struct wl_listener *listener, void *data) {
    struct waybright* wb = wl_container_of(listener, wb, listeners.window_add);
    struct wlr_xdg_surface *wlr_xdg_surface = data;

    if (wlr_xdg_surface->role != WLR_XDG_SURFACE_ROLE_TOPLEVEL)
        return;

    struct wlr_xdg_toplevel* wlr_xdg_toplevel = wlr_xdg_surface->toplevel;
    struct waybright_window* wb_window = calloc(sizeof(struct waybright_window), 1);
    wb_window->wb = wb;
    wb_window->wlr_xdg_surface = wlr_xdg_surface;
    wb_window->wlr_xdg_toplevel = wlr_xdg_toplevel;
    wb_window->is_popup = 0;

	wb_window->listeners.show.notify = handle_window_show_event;
	wl_signal_add(&wlr_xdg_surface->events.map, &wb_window->listeners.show);
	wb_window->listeners.hide.notify = handle_window_hide_event;
	wl_signal_add(&wlr_xdg_surface->events.unmap, &wb_window->listeners.hide);
	wb_window->listeners.remove.notify = handle_window_remove_event;
	wl_signal_add(&wlr_xdg_surface->events.destroy, &wb_window->listeners.remove);

    // More events coming soon to a town near you!

    if (wb->handle_event)
        wb->handle_event(event_type_window_add, wb_window);
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

    // Enables clients to allocate surfaces (windows)
    wb->wlr_compositor = wlr_compositor_create(wb->wl_display, wb->wlr_renderer);
    if (!wb->wlr_compositor)
        return 1;

    wb->wlr_xdg_shell = wlr_xdg_shell_create(wb->wl_display);
    if (!wb->wlr_xdg_shell)
        return 1;
    wb->listeners.window_add.notify = handle_window_add_event;
    wl_signal_add(&wb->wlr_xdg_shell->events.new_surface, &wb->listeners.window_add);


    // init_signals(wb);

    return 0;
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

void waybright_renderer_set_fill_style(struct waybright_renderer* wb_renderer, int color) {
    set_color_to_array(color, wb_renderer->color_fill);
}

void waybright_renderer_clear_rect(struct waybright_renderer* wb_renderer, int x, int y, int width, int height) {
    struct wlr_output* wlr_output = wb_renderer->wlr_output;
    struct wlr_renderer* wlr_renderer = wlr_output->renderer;

    struct wlr_box wlr_box = { .x = x, .y = y, .width = width, .height = height };
    wlr_render_rect(wlr_renderer, &wlr_box, (float[4]){1.0, 1.0, 1.0, 1.0}, wlr_output->transform_matrix);
}

void waybright_renderer_fill_rect(struct waybright_renderer* wb_renderer, int x, int y, int width, int height) {
    struct wlr_output* wlr_output = wb_renderer->wlr_output;
    struct wlr_renderer* wlr_renderer = wlr_output->renderer;

    struct wlr_box wlr_box = { .x = x, .y = y, .width = width, .height = height };
    wlr_render_rect(wlr_renderer, &wlr_box, wb_renderer->color_fill, wlr_output->transform_matrix);
}

void waybright_monitor_enable(struct waybright_monitor* wb_monitor) {
    wlr_output_enable(wb_monitor->wlr_output, true);
    wlr_output_commit(wb_monitor->wlr_output);
}

void waybright_monitor_disable(struct waybright_monitor* wb_monitor) {
    wlr_output_enable(wb_monitor->wlr_output, false);
}

void waybright_monitor_set_background_color(struct waybright_monitor* wb_monitor, int color) {
    set_color_to_array(color, wb_monitor->background_color);
}

int waybright_monitor_get_background_color(struct waybright_monitor* wb_monitor) {
    return get_color_from_array(wb_monitor->background_color);
}
