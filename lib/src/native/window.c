#include "waybright.h"

struct waybright_window* waybright_window_create(struct waybright* wb, struct wlr_xdg_surface* wlr_xdg_surface) {
    struct waybright_window* wb_window = calloc(sizeof(struct waybright_window), 1);

    wb_window->wb = wb;
    wb_window->wlr_xdg_surface = wlr_xdg_surface;
    wb_window->wlr_xdg_toplevel = wlr_xdg_surface->toplevel;

    return wb_window;
}

void waybright_window_destroy(struct waybright_window* wb_window) {
    if (!wb_window) return;

    wl_list_remove(&wb_window->listeners.destroy.link);
    wl_list_remove(&wb_window->listeners.map.link);
    wl_list_remove(&wb_window->listeners.unmap.link);
    wl_list_remove(&wb_window->listeners.new_popup.link);

    if (wb_window->wlr_xdg_popup == NULL) {
        wl_list_remove(&wb_window->listeners.commit.link);
        wl_list_remove(&wb_window->listeners.request_move.link);
        wl_list_remove(&wb_window->listeners.request_maximize.link);
        wl_list_remove(&wb_window->listeners.request_minimize.link);
        wl_list_remove(&wb_window->listeners.request_fullscreen.link);
        wl_list_remove(&wb_window->listeners.request_show_window_menu.link);
        wl_list_remove(&wb_window->listeners.request_resize.link);
        wl_list_remove(&wb_window->listeners.set_title.link);
        wl_list_remove(&wb_window->listeners.set_app_id.link);
        wl_list_remove(&wb_window->listeners.set_parent.link);
    }

    waybright_subwindow_tree_destroy(wb_window->subwindow_tree);

    free(wb_window);
}

void waybright_window_submit_pointer_move_event(struct waybright_window* wb_window, int time, int sx, int sy) {
    struct wlr_seat* wlr_seat = wb_window->wb->wlr_seat;

    wlr_seat_pointer_notify_motion(wlr_seat, time, sx, sy);
}

void waybright_window_submit_pointer_button_event(struct waybright_window* wb_window, int time, int button, int pressed) {
    struct wlr_seat* wlr_seat = wb_window->wb->wlr_seat;

    int state = pressed ? WLR_BUTTON_PRESSED : WLR_BUTTON_RELEASED;
    wb_window->wb->last_pointer_button_serial = wlr_seat_pointer_notify_button(wlr_seat, time, button, state);
}

void waybright_window_submit_pointer_axis_event(struct waybright_window* wb_window, int time, int orientation, double delta, int delta_discrete, int source) {
    struct wlr_seat* wlr_seat = wb_window->wb->wlr_seat;

    wlr_seat_pointer_notify_axis(wlr_seat, time, orientation, delta, delta_discrete, source);
}

void waybright_window_submit_keyboard_key_event(struct waybright_window* wb_window, int time, int keyCode, int pressed) {
    struct wlr_seat* wlr_seat = wb_window->wb->wlr_seat;

    int state = pressed ? WL_KEYBOARD_KEY_STATE_PRESSED : WL_KEYBOARD_KEY_STATE_RELEASED;
    wlr_seat_keyboard_notify_key(wlr_seat, time, keyCode, state);
}

void waybright_window_submit_keyboard_modifiers_event(struct waybright_window* wb_window, struct waybright_keyboard* wb_keyboard) {
    struct wlr_seat* wlr_seat = wb_window->wb->wlr_seat;

    wlr_seat_keyboard_notify_modifiers(wlr_seat, &wb_keyboard->wlr_keyboard->modifiers);
}
