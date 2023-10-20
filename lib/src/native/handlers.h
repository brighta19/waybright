#pragma once

void handle_monitor_remove_event(struct wl_listener *listener, void *data);
void handle_monitor_frame_event(struct wl_listener *listener, void *data);
void handle_monitor_new_event(struct wl_listener *listener, void *data);

void handle_xdg_surface_map_event(struct wl_listener *listener, void *data);
void handle_xdg_surface_unmap_event(struct wl_listener *listener, void *data);
void handle_xdg_surface_destroy_event(struct wl_listener *listener, void *data);
void handle_xdg_surface_new_popup_event(struct wl_listener *listener, void *data);
void handle_xdg_toplevel_request_move_event(struct wl_listener *listener, void *data);
void handle_xdg_toplevel_request_resize_event(struct wl_listener *listener, void *data);
void handle_xdg_toplevel_request_maximize_event(struct wl_listener *listener, void *data);
void handle_xdg_toplevel_request_minimize_event(struct wl_listener *listener, void *data);
void handle_xdg_toplevel_request_fullscreen_event(struct wl_listener *listener, void *data);
void handle_xdg_toplevel_request_show_window_menu_event(struct wl_listener *listener, void *data);
void handle_xdg_toplevel_set_title_event(struct wl_listener *listener, void *data);
void handle_xdg_toplevel_set_app_id_event(struct wl_listener *listener, void *data);
void handle_xdg_toplevel_set_parent_event(struct wl_listener *listener, void *data);
void handle_new_xdg_surface_event(struct wl_listener *listener, void *data);

void handle_pointer_relative_move_event(struct wl_listener *listener, void *data);
void handle_pointer_absolute_move_event(struct wl_listener *listener, void *data);
void handle_pointer_axis_event(struct wl_listener *listener, void *data);
void handle_pointer_frame_event(struct wl_listener *listener, void *data);
void handle_pointer_button_event(struct wl_listener *listener, void *data);
void handle_pointer_remove_event(struct wl_listener* listener, void *data);
void handle_pointer_new_event(struct waybright* wb, struct waybright_pointer* wb_pointer);

void handle_keyboard_remove_event(struct wl_listener* listener, void *data);
void handle_keyboard_key_event(struct wl_listener* listener, void *data);
void handle_keyboard_modifiers_event(struct wl_listener* listener, void *data);
void handle_keyboard_new_event(struct waybright* wb, struct waybright_keyboard* wb_keyboard);

void handle_input_new_event(struct wl_listener *listener, void *data);

void handle_image_load_event(struct wl_listener *listener, void *data);
void handle_image_destroy_event(struct wl_listener *listener, void *data);
void handle_cursor_image_event(struct wl_listener *listener, void *data);
