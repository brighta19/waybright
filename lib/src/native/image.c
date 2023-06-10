#include "waybright.h"
#include "handlers.h"

void waybright_image_destroy(struct waybright_image* wb_image) {
    if (!wb_image) return;

    wl_list_remove(&wb_image->listeners.destroy.link);
    wl_list_remove(&wb_image->listeners.load.link);

    free(wb_image);
}

struct waybright_image* waybright_image_create_from_surface(struct wlr_surface* wlr_surface) {
    struct waybright_image* wb_image = calloc(sizeof(struct waybright_image), 1);
    wb_image->wlr_surface = wlr_surface;

    wb_image->listeners.destroy.notify = handle_image_destroy_event;
    wl_signal_add(&wlr_surface->events.destroy, &wb_image->listeners.destroy);

    struct wlr_texture* wlr_texture = wlr_surface_get_texture(wlr_surface);
    if (wlr_texture) {
        wb_image->wlr_texture = wlr_texture;
        wb_image->width = wlr_texture->width;
        wb_image->height = wlr_texture->height;
        wb_image->is_loaded = true;
        // Cannot call handle_event(image_load) since it hasn't been set in dart yet
    }
    else {
        wb_image->is_loaded = false;
    }

    wb_image->listeners.load.notify = handle_image_load_event;
    wl_signal_add(&wlr_surface->events.commit, &wb_image->listeners.load);

    return wb_image;
}

struct waybright_image* waybright_image_create_from_texture(struct wlr_texture* wlr_texture) {
    struct waybright_image* wb_image = malloc(sizeof(struct waybright_image));

    wb_image->wlr_texture = wlr_texture;
    wb_image->width = wlr_texture->width;
    wb_image->height = wlr_texture->height;
    wb_image->is_loaded = true;

    return wb_image;
}
