#include <stdlib.h>
#include <drm/drm_fourcc.h>
// #include <wlr/types/wlr_compositor.h>
// #include <wlr/render/wlr_texture.h>
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

struct waybright_monitor* waybright_monitor_create() {
    return calloc(sizeof(struct waybright_monitor), 1);
}

void waybright_canvas_destroy(struct waybright_canvas* wb_canvas) {
    if (!wb_canvas) return;

    cairo_destroy(wb_canvas->ctx);
    cairo_surface_destroy(wb_canvas->canvas);

    free(wb_canvas);
}

void waybright_monitor_destroy(struct waybright_monitor* wb_monitor) {
    if (!wb_monitor) return;

    wlr_output_destroy(wb_monitor->wlr_output);
    wlr_output_damage_destroy(wb_monitor->wlr_output_damage);
    waybright_canvas_destroy(wb_monitor->wb_canvas);

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

/// Seems to happen when the output is ready to display a frame AND if the compositor needs to display a frame (Ex. if a client commits a frame) ...
void handle_monitor_frame_event(struct wl_listener *listener, void *data) {
    struct waybright_monitor* wb_monitor = wl_container_of(listener, wb_monitor, listeners.frame);
    // struct wlr_output *wlr_output = data;

    if (wb_monitor->handle_event)
        wb_monitor->handle_event(event_type_monitor_frame, wb_monitor);

    struct wlr_renderer* wlr_renderer = wb_monitor->wb->wlr_renderer;
    struct wlr_output* wlr_output = wb_monitor->wlr_output;
    struct wlr_output_damage* wlr_output_damage = wb_monitor->wlr_output_damage;


    bool needs_frame; // Whether or not I need to render a new frame
    pixman_region32_t buffer_damage; // A list of regions that represent ALL damage accumulated from previous buffers
    pixman_region32_init(&buffer_damage);

    // I indicate that I want to render.
    wlr_output_damage_attach_render(wlr_output_damage, &needs_frame, &buffer_damage);

    if (!needs_frame) {
        // There's no need to render, so I indicate that I'll no longer render.
        wlr_output_rollback(wlr_output);
        return;
    }

    // If I'm here, then I need to render a new frame for the output.

    int width, height; // The will-be size of the new frame

    // "Computes the transformed and scaled output resolution."
    wlr_output_effective_resolution(wlr_output, &width, &height);

    // Time to start drawing! (what's the purpose of the width and height params? they don't seem to affect anything.)
    wlr_renderer_begin(wlr_renderer, width, height);

    // Fills the entire buffer with a single color.
    wlr_renderer_clear(wlr_renderer, wb_monitor->background_color);

    // I'm done drawing!
    wlr_renderer_end(wlr_renderer);

    // Submit my frame to the output.
    wlr_output_commit(wlr_output);

    // No longer unnecessary
    pixman_region32_fini(&buffer_damage);


    // struct wlr_renderer* wlr_renderer = wb_monitor->wb->wlr_renderer;
    // struct wlr_output* wlr_output = wb_monitor->wlr_output;
    // int width = wb_monitor->wlr_output->width;
    // int height = wb_monitor->wlr_output->height;
    // cairo_surface_t* canvas = wb_monitor->wb_canvas->canvas;

    //     int stride = cairo_format_stride_for_width(CAIRO_FORMAT_ARGB32, width);
    //     unsigned char *pixel_data = cairo_image_surface_get_data(canvas);
    // struct wlr_texture *texture = wlr_texture_from_pixels(
    //         wlr_renderer,
    //         DRM_FORMAT_ARGB8888,
    //         stride,
    //         width,
    //         height,
    //         pixel_data
    //     );

    // wlr_render_texture(wlr_renderer, texture, wlr_output->transform_matrix, 0, 0, 1.0);

    // wlr_texture_destroy(texture);
}

void handle_monitor_add_event(struct wl_listener *listener, void *data) {
    struct waybright* wb = wl_container_of(listener, wb, listeners.monitor_add);
    struct wlr_output *wlr_output = data;

	wlr_output_init_render(wlr_output, wb->wlr_allocator, wb->wlr_renderer);

    struct waybright_monitor* wb_monitor = waybright_monitor_create();
    wb_monitor->wb = wb;
    wb_monitor->wlr_output = wlr_output;
    wb_monitor->wlr_output_damage = wlr_output_damage_create(wlr_output);

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

void waybright_canvas_set_fill_style(struct waybright_canvas* wb_canvas, int color) {
    set_color_to_array(color, wb_canvas->color_fill);
}

void waybright_canvas_clear_rect(struct waybright_canvas* wb_canvas, int x, int y, int width, int height) {
    cairo_set_source_rgba(wb_canvas->ctx, 1.0, 1.0, 1.0, 1.0);
    cairo_rectangle(wb_canvas->ctx, x, y, width, height);
    cairo_fill(wb_canvas->ctx);
}

void waybright_canvas_fill_rect(struct waybright_canvas* wb_canvas, int x, int y, int width, int height) {
    cairo_set_source_rgba(
        wb_canvas->ctx,
        wb_canvas->color_fill[0],
        wb_canvas->color_fill[1],
        wb_canvas->color_fill[2],
        wb_canvas->color_fill[3]
    );
    cairo_rectangle(wb_canvas->ctx, x, y, width, height);
    cairo_fill(wb_canvas->ctx);
}

struct waybright_canvas* waybright_canvas_create() {
    return calloc(sizeof(struct waybright_canvas), 1);
}

void waybright_canvas_init(struct waybright_canvas* wb_canvas, struct waybright_monitor* wb_monitor) {
    wb_canvas->canvas = cairo_image_surface_create(
        CAIRO_FORMAT_ARGB32,
        wb_monitor->wlr_output->width,
        wb_monitor->wlr_output->height
    );
    wb_canvas->ctx = cairo_create(wb_canvas->canvas);
}

void waybright_monitor_enable(struct waybright_monitor* wb_monitor) {
    wlr_output_enable(wb_monitor->wlr_output, true);
    wlr_output_commit(wb_monitor->wlr_output);

    struct waybright_canvas* wb_canvas = waybright_canvas_create();
    waybright_canvas_init(wb_canvas, wb_monitor);
    wb_monitor->wb_canvas = wb_canvas;
}

void waybright_monitor_set_background_color(struct waybright_monitor* wb_monitor, int color) {
    set_color_to_array(color, wb_monitor->background_color);
}

int waybright_monitor_get_background_color(struct waybright_monitor* wb_monitor) {
    return get_color_from_array(wb_monitor->background_color);
}

// void waybright_monitor_render_canvas(struct waybright_monitor* wb_monitor) {
//     if (!wb_monitor->wb_canvas) return;

//     cairo_surface_t* canvas = wb_monitor->wb_canvas->canvas;

//     cairo_surface_flush(canvas);
// }