#include "waybright.h"

void waybright_pointer_destroy(struct waybright_pointer* wb_pointer) {
    if (!wb_pointer) return;

    if (wb_pointer->wb_input)
        free(wb_pointer->wb_input);

    wl_list_remove(&wb_pointer->listeners.destroy.link);
    wl_list_remove(&wb_pointer->listeners.axis.link);
    wl_list_remove(&wb_pointer->listeners.button.link);
    wl_list_remove(&wb_pointer->listeners.relative_move.link);
    wl_list_remove(&wb_pointer->listeners.absolute_move.link);

    free(wb_pointer);
}

void waybright_pointer_focus_on_window(struct waybright_pointer* wb_pointer, struct waybright_window* wb_window, int sx, int sy) {
    struct wlr_seat* wlr_seat = wb_pointer->wb->wlr_seat;

    double sub_x, sub_y;
    struct wlr_surface* wlr_surface = wlr_surface_surface_at(
        wb_window->wlr_xdg_surface->surface, sx, sy, &sub_x, &sub_y);
    if (!wlr_surface) return;

    wlr_seat_pointer_notify_enter(wlr_seat, wlr_surface, sub_x, sub_y);
}

void waybright_pointer_clear_focus(struct waybright_pointer* wb_pointer) {
    struct wlr_seat* wlr_seat = wb_pointer->wb->wlr_seat;

    wlr_seat_pointer_clear_focus(wlr_seat);
}
