#include "waybright.h"

void waybright_keyboard_destroy(struct waybright_keyboard* wb_keyboard) {
    if (!wb_keyboard) return;

    if (wb_keyboard->wb_input)
        free(wb_keyboard->wb_input);

    free(wb_keyboard);
}

void waybright_keyboard_focus_on_window(struct waybright_keyboard* wb_keyboard, struct waybright_window* wb_window) {
    struct wlr_seat* wlr_seat = wb_keyboard->wb->wlr_seat;
    struct wlr_keyboard* wlr_keyboard = wb_keyboard->wlr_keyboard;
    struct wlr_surface* wlr_surface = wb_window->wlr_xdg_surface->surface;

    wlr_seat_keyboard_notify_enter(
        wlr_seat, wlr_surface,
        wlr_keyboard->keycodes,
        wlr_keyboard->num_keycodes,
        &wlr_keyboard->modifiers
    );
}

void waybright_keyboard_clear_focus(struct waybright_keyboard* wb_keyboard) {
    struct wlr_seat* wlr_seat = wb_keyboard->wb->wlr_seat;

    wlr_seat_keyboard_clear_focus(wlr_seat);
}
