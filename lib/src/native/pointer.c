#include "waybright.h"

void waybright_pointer_destroy(struct waybright_pointer* wb_pointer) {
    if (!wb_pointer) return;

    if (wb_pointer->wb_input)
        free(wb_pointer->wb_input);

    free(wb_pointer);
}

void waybright_pointer_focus_on_window(struct waybright_pointer* wb_pointer, struct waybright_window* wb_window, int sx, int sy) {
    struct wlr_seat* wlr_seat = wb_pointer->wb->wlr_seat;
    struct wlr_surface* wlr_surface = wb_window->wlr_xdg_surface->surface;

    wlr_seat_pointer_notify_enter(wlr_seat, wlr_surface, sx, sy);
}

void waybright_pointer_clear_focus(struct waybright_pointer* wb_pointer) {
    struct wlr_seat* wlr_seat = wb_pointer->wb->wlr_seat;

    wlr_seat_pointer_clear_focus(wlr_seat);
}
