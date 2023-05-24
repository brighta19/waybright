#include "waybright.h"
#include "handlers.h"

void handle_monitor_remove_event(struct wl_listener *listener, void *data) {
    struct waybright_monitor* wb_monitor = wl_container_of(listener, wb_monitor, listeners.remove);
    // struct wlr_output *wlr_output = data;

    if (wb_monitor->handle_event)
        wb_monitor->handle_event(event_type_monitor_remove, wb_monitor);

    waybright_monitor_destroy(wb_monitor);
}

/// Occurs according to the monitor's refresh rate (set by the mode).
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
    wlr_renderer_clear(wlr_renderer, wb_monitor->wb_renderer->color_background);


    if (wb_monitor->handle_event)
        wb_monitor->handle_event(event_type_monitor_frame, wb_monitor);


    // I'm done drawing!
    wlr_renderer_end(wlr_renderer);

    // Submit my frame to the output.
    if (!wlr_output_commit(wlr_output))
        wlr_output_schedule_frame(wlr_output);
}

void handle_monitor_new_event(struct wl_listener *listener, void *data) {
    struct waybright* wb = wl_container_of(listener, wb, listeners.monitor_new);
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
        wb->handle_event(event_type_monitor_new, wb_monitor);
}

void handle_window_show_event(struct wl_listener *listener, void *data) {
    struct waybright_window* wb_window = wl_container_of(listener, wb_window, listeners.show);

    struct waybright_window_event wb_window_event = { wb_window, NULL };

    if (wb_window->handle_event)
        wb_window->handle_event(event_type_window_show, &wb_window_event);
}

void handle_window_hide_event(struct wl_listener *listener, void *data) {
    struct waybright_window* wb_window = wl_container_of(listener, wb_window, listeners.hide);

    struct waybright_window_event wb_window_event = { wb_window, NULL };

    if (wb_window->handle_event)
        wb_window->handle_event(event_type_window_hide, &wb_window_event);
}

void handle_window_remove_event(struct wl_listener *listener, void *data) {
    struct waybright_window* wb_window = wl_container_of(listener, wb_window, listeners.remove);

    struct waybright_window_event wb_window_event = { wb_window, NULL };

    if (wb_window->handle_event)
        wb_window->handle_event(event_type_window_remove, &wb_window_event);

    waybright_window_destroy(wb_window);
}

void handle_window_move_event(struct wl_listener *listener, void *data) {
    struct waybright_window* wb_window = wl_container_of(listener, wb_window, listeners.move);
    struct wlr_xdg_toplevel_move_event* event = data;

    // Accept move requests only if it is a response to pointer button events
    if (event->serial != wb_window->wb->last_pointer_button_serial) return;

    struct waybright_window_event wb_window_event = { wb_window, event };

    if (wb_window->handle_event)
        wb_window->handle_event(event_type_window_move, &wb_window_event);
}

void handle_window_resize_event(struct wl_listener *listener, void *data) {
    struct waybright_window* wb_window = wl_container_of(listener, wb_window, listeners.resize);
	struct wlr_xdg_toplevel_resize_event *event = data;

    // Accept move requests only if it is a response to pointer button events
    if (event->serial != wb_window->wb->last_pointer_button_serial) return;

    struct waybright_window_event wb_window_event = { wb_window, event };

    if (wb_window->handle_event)
        wb_window->handle_event(event_type_window_resize, &wb_window_event);
}

void handle_window_maximize_event(struct wl_listener *listener, void *data) {
    struct waybright_window* wb_window = wl_container_of(listener, wb_window, listeners.maximize);

    struct waybright_window_event wb_window_event = { wb_window, NULL };

    if (wb_window->handle_event)
        wb_window->handle_event(event_type_window_maximize, &wb_window_event);
}

void handle_window_fullscreen_event(struct wl_listener *listener, void *data) {
    struct waybright_window* wb_window = wl_container_of(listener, wb_window, listeners.fullscreen);

    struct waybright_window_event wb_window_event = { wb_window, NULL };

    if (wb_window->handle_event)
        wb_window->handle_event(event_type_window_fullscreen, &wb_window_event);
}

void handle_window_new_popup_event(struct wl_listener *listener, void *data) {
    struct waybright_window* wb_parent_window = wl_container_of(listener, wb_parent_window, listeners.new_popup);
    struct waybright* wb = wb_parent_window->wb;
    struct wlr_xdg_popup* wlr_xdg_popup = data;
    struct wlr_xdg_surface* wlr_xdg_surface = wlr_xdg_popup->base;

    struct waybright_window* wb_window = calloc(sizeof(struct waybright_window), 1);
    wb_window->wb = wb;
    wb_window->wlr_xdg_surface = wlr_xdg_surface;
    wb_window->wlr_xdg_toplevel = wb_parent_window->wlr_xdg_toplevel;
    wb_window->wlr_xdg_popup = wlr_xdg_popup;

    wb_window->listeners.show.notify = handle_window_show_event;
    wl_signal_add(&wlr_xdg_surface->events.map, &wb_window->listeners.show);
    wb_window->listeners.hide.notify = handle_window_hide_event;
    wl_signal_add(&wlr_xdg_surface->events.unmap, &wb_window->listeners.hide);
    wb_window->listeners.remove.notify = handle_window_remove_event;
    wl_signal_add(&wlr_xdg_surface->events.destroy, &wb_window->listeners.remove);
    wb_window->listeners.new_popup.notify = handle_window_new_popup_event;
    wl_signal_add(&wlr_xdg_surface->events.new_popup, &wb_window->listeners.new_popup);

    struct waybright_window_event wb_window_event = { wb_parent_window, wb_window };

    if (wb_parent_window->handle_event)
        wb_parent_window->handle_event(event_type_window_new_popup, &wb_window_event);
}

void handle_window_new_event(struct wl_listener *listener, void *data) {
    struct waybright* wb = wl_container_of(listener, wb, listeners.window_new);
    struct wlr_xdg_surface *wlr_xdg_surface = data;

    if (wlr_xdg_surface->role != WLR_XDG_SURFACE_ROLE_TOPLEVEL)
        return;

    struct wlr_xdg_toplevel* wlr_xdg_toplevel = wlr_xdg_surface->toplevel;
    struct waybright_window* wb_window = calloc(sizeof(struct waybright_window), 1);
    wb_window->wb = wb;
    wb_window->wlr_xdg_surface = wlr_xdg_surface;
    wb_window->wlr_xdg_toplevel = wlr_xdg_toplevel;

    wb_window->listeners.show.notify = handle_window_show_event;
    wl_signal_add(&wlr_xdg_surface->events.map, &wb_window->listeners.show);
    wb_window->listeners.hide.notify = handle_window_hide_event;
    wl_signal_add(&wlr_xdg_surface->events.unmap, &wb_window->listeners.hide);
    wb_window->listeners.remove.notify = handle_window_remove_event;
    wl_signal_add(&wlr_xdg_surface->events.destroy, &wb_window->listeners.remove);

    wb_window->listeners.move.notify = handle_window_move_event;
    wl_signal_add(&wlr_xdg_toplevel->events.request_move, &wb_window->listeners.move);
    wb_window->listeners.maximize.notify = handle_window_maximize_event;
    wl_signal_add(&wlr_xdg_toplevel->events.request_maximize, &wb_window->listeners.maximize);
    wb_window->listeners.fullscreen.notify = handle_window_fullscreen_event;
    wl_signal_add(&wlr_xdg_toplevel->events.request_fullscreen, &wb_window->listeners.fullscreen);
    wb_window->listeners.resize.notify = handle_window_resize_event;
    wl_signal_add(&wlr_xdg_toplevel->events.request_resize, &wb_window->listeners.resize);
    wb_window->listeners.new_popup.notify = handle_window_new_popup_event;
    wl_signal_add(&wlr_xdg_surface->events.new_popup, &wb_window->listeners.new_popup);

    // More events coming soon to a town near you!

    if (wb->handle_event)
        wb->handle_event(event_type_window_new, wb_window);
}

void handle_pointer_move_event(struct wl_listener *listener, void *data) {
    struct waybright_pointer* wb_pointer = wl_container_of(listener, wb_pointer, listeners.move);
    struct wlr_event_pointer_motion* event = data;

    struct waybright_pointer_event wb_pointer_event = {
        wb_pointer,
        event
    };

    if (wb_pointer->handle_event)
        wb_pointer->handle_event(event_type_pointer_move, &wb_pointer_event);
}

void handle_pointer_teleport_event(struct wl_listener *listener, void *data) {
    struct waybright_pointer* wb_pointer = wl_container_of(listener, wb_pointer, listeners.teleport);
    struct wlr_event_pointer_motion_absolute* event = data;

    struct waybright_pointer_event wb_pointer_event = {
        wb_pointer,
        event
    };

    if (wb_pointer->handle_event)
        wb_pointer->handle_event(event_type_pointer_teleport, &wb_pointer_event);
}

void handle_pointer_axis_event(struct wl_listener *listener, void *data) {
    struct waybright_pointer* wb_pointer = wl_container_of(listener, wb_pointer, listeners.axis);
    struct wlr_event_pointer_motion_absolute* event = data;

    struct waybright_pointer_event wb_pointer_event = {
        wb_pointer,
        event
    };

    if (wb_pointer->handle_event)
        wb_pointer->handle_event(event_type_pointer_axis, &wb_pointer_event);
}

void handle_pointer_button_event(struct wl_listener *listener, void *data) {
    struct waybright_pointer* wb_pointer = wl_container_of(listener, wb_pointer, listeners.button);
    struct wlr_event_pointer_button* event = data;

    struct waybright_pointer_event wb_pointer_event = {
        wb_pointer,
        event
    };

    if (wb_pointer->handle_event)
        wb_pointer->handle_event(event_type_pointer_button, &wb_pointer_event);
}

void handle_pointer_remove_event(struct wl_listener* listener, void *data) {
    struct waybright_pointer* wb_pointer = wl_container_of(listener, wb_pointer, listeners.remove);

    if (wb_pointer->handle_event)
        wb_pointer->handle_event(event_type_pointer_remove, wb_pointer);

    waybright_pointer_destroy(wb_pointer);
}

void handle_pointer_new_event(struct waybright* wb, struct waybright_pointer* wb_pointer) {
    struct wlr_input_device* wlr_input_device = wb_pointer->wb_input->wlr_input_device;

    wb_pointer->listeners.remove.notify = handle_pointer_remove_event;
    wl_signal_add(&wlr_input_device->events.destroy, &wb_pointer->listeners.remove);

    struct wlr_pointer* wlr_pointer = wb_pointer->wlr_pointer;

    wb_pointer->listeners.move.notify = handle_pointer_move_event;
    wl_signal_add(&wlr_pointer->events.motion, &wb_pointer->listeners.move);
    wb_pointer->listeners.teleport.notify = handle_pointer_teleport_event;
    wl_signal_add(&wlr_pointer->events.motion_absolute, &wb_pointer->listeners.teleport);
    wb_pointer->listeners.button.notify = handle_pointer_button_event;
    wl_signal_add(&wlr_pointer->events.button, &wb_pointer->listeners.button);
    wb_pointer->listeners.axis.notify = handle_pointer_axis_event;
    wl_signal_add(&wlr_pointer->events.axis, &wb_pointer->listeners.axis);
}

void handle_keyboard_remove_event(struct wl_listener* listener, void *data) {
    struct waybright_keyboard* wb_keyboard = wl_container_of(listener, wb_keyboard, listeners.remove);

    if (wb_keyboard->handle_event)
        wb_keyboard->handle_event(event_type_keyboard_remove, wb_keyboard);

    waybright_keyboard_destroy(wb_keyboard);
}

void handle_keyboard_key_event(struct wl_listener* listener, void *data) {
    struct waybright_keyboard* wb_keyboard = wl_container_of(listener, wb_keyboard, listeners.key);
	struct wlr_keyboard_key_event* event = data;

    struct waybright_keyboard_event wb_keyboard_event = {
        wb_keyboard,
        event
    };

    if (wb_keyboard->handle_event)
        wb_keyboard->handle_event(event_type_keyboard_key, &wb_keyboard_event);
}

void handle_keyboard_modifiers_event(struct wl_listener* listener, void *data) {
    struct waybright_keyboard* wb_keyboard = wl_container_of(listener, wb_keyboard, listeners.modifiers);
	struct wlr_keyboard_modifiers_event* event = data;

    struct waybright_keyboard_event wb_keyboard_event = {
        wb_keyboard,
        event
    };

    if (wb_keyboard->handle_event)
        wb_keyboard->handle_event(event_type_keyboard_modifiers, &wb_keyboard_event);
}

void handle_keyboard_new_event(struct waybright* wb, struct waybright_keyboard* wb_keyboard) {
    struct wlr_input_device* wlr_input_device = wb_keyboard->wb_input->wlr_input_device;
    struct wlr_keyboard* wlr_keyboard = wb_keyboard->wlr_keyboard;

	struct xkb_context *context = xkb_context_new(XKB_CONTEXT_NO_FLAGS);
	struct xkb_keymap *keymap = xkb_keymap_new_from_names(context, NULL,
		XKB_KEYMAP_COMPILE_NO_FLAGS);

	wlr_keyboard_set_keymap(wlr_keyboard, keymap);
	xkb_keymap_unref(keymap);
	xkb_context_unref(context);
	wlr_keyboard_set_repeat_info(wlr_keyboard, 25, 600);

    wb_keyboard->listeners.remove.notify = handle_keyboard_remove_event;
    wl_signal_add(&wlr_input_device->events.destroy, &wb_keyboard->listeners.remove);
    wb_keyboard->listeners.key.notify = handle_keyboard_key_event;
    wl_signal_add(&wlr_keyboard->events.key, &wb_keyboard->listeners.key);
    wb_keyboard->listeners.modifiers.notify = handle_keyboard_modifiers_event;
    wl_signal_add(&wlr_keyboard->events.modifiers, &wb_keyboard->listeners.modifiers);

	wlr_seat_set_keyboard(wb->wlr_seat, wlr_keyboard);
}

void handle_input_new_event(struct wl_listener *listener, void *data) {
    struct waybright* wb = wl_container_of(listener, wb, listeners.input_new);
    struct wlr_input_device* wlr_input_device = data;

    struct waybright_input* wb_input = calloc(sizeof(struct waybright_input), 1);
    wb_input->wb = wb;
    wb_input->wlr_input_device = wlr_input_device;

    switch (wlr_input_device->type) {
        case WLR_INPUT_DEVICE_POINTER:
            struct waybright_pointer* wb_pointer = calloc(sizeof(struct waybright_pointer), 1);
            wb_pointer->wb = wb;
            wb_pointer->wlr_pointer = wlr_pointer_from_input_device(wlr_input_device);
            wb_pointer->wb_input = wb_input;
            wb_input->pointer = wb_pointer;

            handle_pointer_new_event(wb, wb_pointer);
            break;

        case WLR_INPUT_DEVICE_KEYBOARD:
            struct waybright_keyboard* wb_keyboard = calloc(sizeof(struct waybright_keyboard), 1);
            wb_keyboard->wb = wb;
            wb_keyboard->wlr_keyboard = wlr_keyboard_from_input_device(wlr_input_device);
            wb_keyboard->wb_input = wb_input;
            wb_input->keyboard = wb_keyboard;

            handle_keyboard_new_event(wb, wb_keyboard);
            break;

        // stay turned for more!
        default:
            break;
    }

    if (wb->handle_event)
        wb->handle_event(event_type_input_new, wb_input);
}

void handle_image_ready_event(struct wl_listener *listener, void *data) {
    struct waybright_image* wb_image = wl_container_of(listener, wb_image, listeners.ready);
    struct wlr_texture* wlr_texture = wlr_surface_get_texture(wb_image->wlr_surface);

    if (!wlr_texture)
        return;

    wb_image->wlr_texture = wlr_texture;
    wb_image->width = wlr_texture->width;
    wb_image->height = wlr_texture->height;
    wb_image->is_ready = true;
}

void handle_image_destroy_event(struct wl_listener *listener, void *data) {
    struct waybright_image* wb_image = wl_container_of(listener, wb_image, listeners.destroy);

    if (wb_image->handle_event)
        wb_image->handle_event(event_type_image_destroy, wb_image);

    waybright_image_destroy(wb_image);
}

void handle_cursor_image_event(struct wl_listener *listener, void *data) {
    struct waybright* wb = wl_container_of(listener, wb, listeners.cursor_image);
    struct wlr_seat_pointer_request_set_cursor_event* event = data;
    struct wlr_surface* wlr_surface = event->surface;

    if (!wlr_surface) {
        if (wb->handle_event)
            wb->handle_event(event_type_cursor_image, NULL);
        return;
    }

    struct waybright_image* wb_image = waybright_image_create_from_surface(wlr_surface);
    wb_image->offset_x = -event->hotspot_x;
    wb_image->offset_y = -event->hotspot_y;

    if (wb->handle_event)
        wb->handle_event(event_type_cursor_image, wb_image);
}
