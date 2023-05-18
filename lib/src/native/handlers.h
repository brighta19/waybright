#pragma once

void handle_monitor_remove_event(struct wl_listener *listener, void *data);
void handle_monitor_frame_event(struct wl_listener *listener, void *data);
void handle_monitor_new_event(struct wl_listener *listener, void *data);

void handle_window_show_event(struct wl_listener *listener, void *data);
void handle_window_hide_event(struct wl_listener *listener, void *data);
void handle_window_remove_event(struct wl_listener *listener, void *data);
void handle_window_move_event(struct wl_listener *listener, void *data);
void handle_window_resize_event(struct wl_listener *listener, void *data);
void handle_window_maximize_event(struct wl_listener *listener, void *data);
void handle_window_fullscreen_event(struct wl_listener *listener, void *data);
void handle_window_new_event(struct wl_listener *listener, void *data);

void handle_pointer_teleport_event(struct wl_listener *listener, void *data);
void handle_pointer_axis_event(struct wl_listener *listener, void *data);
void handle_pointer_button_event(struct wl_listener *listener, void *data);
void handle_pointer_remove_event(struct wl_listener* listener, void *data);
void handle_pointer_new_event(struct waybright* wb, struct waybright_pointer* wb_pointer);

void handle_keyboard_remove_event(struct wl_listener* listener, void *data);
void handle_keyboard_key_event(struct wl_listener* listener, void *data);
void handle_keyboard_modifiers_event(struct wl_listener* listener, void *data);
void handle_keyboard_new_event(struct waybright* wb, struct waybright_keyboard* wb_keyboard);

void handle_input_new_event(struct wl_listener *listener, void *data);

void handle_image_ready_event(struct wl_listener *listener, void *data);
void handle_image_destroy_event(struct wl_listener *listener, void *data);
