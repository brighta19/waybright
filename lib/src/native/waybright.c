#define STB_IMAGE_IMPLEMENTATION

#include <stdlib.h>
#include <drm_fourcc.h>
#include <wlr/render/wlr_texture.h>
#include <wlr/types/wlr_data_control_v1.h>
#include <wlr/types/wlr_data_device.h>
#include <wlr/types/wlr_export_dmabuf_v1.h>
#include <wlr/types/wlr_gamma_control_v1.h>
#include <wlr/types/wlr_primary_selection_v1.h>
#include <wlr/types/wlr_single_pixel_buffer_v1.h>
#include <wlr/types/wlr_subcompositor.h>
#include <wlr/types/wlr_viewporter.h>
#include "stb_image.h"
#include "waybright.h"
#include "handlers.h"

int get_color_from_array(float* color_array) {
    return ((int)(color_array[0] * 0xff) << 24) +
           ((int)(color_array[1] * 0xff) << 16) +
           ((int)(color_array[2] * 0xff) << 8) +
                 (color_array[3] * 0xff);
}

void set_color_to_array(int color, float* color_array) {
    color_array[0] = ((color & 0xff000000) >> 24) / (float)0xff;
    color_array[1] = ((color & 0x00ff0000) >> 16) / (float)0xff;
    color_array[2] = ((color & 0x0000ff00) >> 8)  / (float)0xff;
    color_array[3] =  (color & 0x000000ff)        / (float)0xff;
}

struct wlr_output_mode* waybright_get_wlr_output_mode_from_wl_list(struct wl_list *ptr) {
    return wl_container_of(ptr, (struct wlr_output_mode*)NULL, link);
}

struct waybright* waybright_create() {
    return calloc(sizeof(struct waybright), 1);
}

void waybright_destroy(struct waybright* wb) {
    if (!wb) return;

    wlr_seat_destroy(wb->wlr_seat);
    wlr_allocator_destroy(wb->wlr_allocator);
    wlr_renderer_destroy(wb->wlr_renderer);
    wlr_backend_destroy(wb->wlr_backend);
    wl_display_destroy_clients(wb->wl_display);
    wl_display_destroy(wb->wl_display);

    wl_list_remove(&wb->listeners.cursor_image.link);
    wl_list_remove(&wb->listeners.input_new.link);
    wl_list_remove(&wb->listeners.monitor_new.link);
    wl_list_remove(&wb->listeners.new_xdg_surface.link);
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

    if (!wlr_renderer_init_wl_display(wb->wlr_renderer, wb->wl_display))
        return 1;

    wb->wlr_allocator = wlr_allocator_autocreate(wb->wlr_backend, wb->wlr_renderer);
    if (!wb->wlr_allocator)
        return 1;

    // Enables clients to allocate surfaces (windows)
    wb->wlr_compositor = wlr_compositor_create(wb->wl_display, wb->wlr_renderer);
    if (!wb->wlr_compositor)
        return 1;

    wb->wlr_xdg_shell = wlr_xdg_shell_create(wb->wl_display, 3);
    if (!wb->wlr_xdg_shell)
        return 1;

    wb->wlr_seat = wlr_seat_create(wb->wl_display, "seat0");
    if (!wb->wlr_seat)
        return 1;

    wlr_subcompositor_create(wb->wl_display);
    wlr_data_device_manager_create(wb->wl_display);
    wlr_export_dmabuf_manager_v1_create(wb->wl_display);
    wlr_data_control_manager_v1_create(wb->wl_display);
    wlr_gamma_control_manager_v1_create(wb->wl_display);
    wlr_primary_selection_v1_device_manager_create(wb->wl_display);
    wlr_viewporter_create(wb->wl_display);
    wlr_single_pixel_buffer_manager_v1_create(wb->wl_display);

    wb->listeners.input_new.notify = handle_input_new_event;
    wl_signal_add(&wb->wlr_backend->events.new_input, &wb->listeners.input_new);
    wb->listeners.monitor_new.notify = handle_monitor_new_event;
    wl_signal_add(&wb->wlr_backend->events.new_output, &wb->listeners.monitor_new);
    wb->listeners.new_xdg_surface.notify = handle_new_xdg_surface_event;
    wl_signal_add(&wb->wlr_xdg_shell->events.new_surface, &wb->listeners.new_xdg_surface);
    wb->listeners.cursor_image.notify = handle_cursor_image_event;
    wl_signal_add(&wb->wlr_seat->events.request_set_cursor, &wb->listeners.cursor_image);

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

    wb->wl_event_loop = wl_display_get_event_loop(wb->wl_display);

    setenv("WAYLAND_DISPLAY", wb->socket_name, 1);
    return 0;
}

void waybright_check_events(struct waybright* wb) {
    wl_display_flush_clients(wb->wl_display);
    wl_event_loop_dispatch(wb->wl_event_loop, 1);
}

void waybright_close_socket(struct waybright* wb) {
    wl_display_destroy_clients(wb->wl_display);
    wl_display_terminate(wb->wl_display);
}

struct waybright_image* waybright_load_image(struct waybright* wb, const char* path, int* error) {
    *error = image_error_type_none;

    FILE *fp = fopen(path, "r");
    if (!fp) {
        *error = image_error_type_image_not_found;
        return NULL;
    }

    int width, height;
    unsigned char* data = stbi_load_from_file(fp, &width, &height, NULL, 4);
    fclose(fp);
    if (!data) {
        *error = image_error_type_image_load_failed;
        return NULL;
    }

    int stride = width * 4;

    struct wlr_texture* wlr_texture = wlr_texture_from_pixels(
        wb->wlr_renderer,
        DRM_FORMAT_ABGR8888,
        stride,
        width,
        height,
        data
    );

    stbi_image_free(data);

    if (!wlr_texture) {
        *error = image_error_type_image_load_failed;
        return NULL;
    }

    struct waybright_image* wb_image = waybright_image_create_from_texture(wlr_texture);
    wb_image->path = strdup(path);

    return wb_image;
}
