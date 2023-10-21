#include "waybright.h"
#include "handlers.h"

void handle_monitor_remove_event(struct wl_listener *listener, void *data) {
    struct waybright_monitor* wb_monitor = wl_container_of(listener, wb_monitor, listeners.destroy);

    if (wb_monitor->handle_event)
        wb_monitor->handle_event(event_type_monitor_remove, wb_monitor);

    waybright_monitor_destroy(wb_monitor);
}

/// Occurs according to the monitor's refresh rate (set by the mode).
void handle_monitor_frame_event(struct wl_listener *listener, void *data) {
    struct waybright_monitor* wb_monitor = wl_container_of(listener, wb_monitor, listeners.frame);

    if (wb_monitor->handle_event)
        wb_monitor->handle_event(event_type_monitor_frame, wb_monitor);
}

void handle_monitor_new_event(struct wl_listener *listener, void *data) {
    struct waybright* wb = wl_container_of(listener, wb, listeners.monitor_new);
    struct wlr_output *wlr_output = data;

    wlr_output_init_render(wlr_output, wb->wlr_allocator, wb->wlr_renderer);
    wlr_output_create_global(wlr_output);

    struct waybright_renderer* wb_renderer = calloc(sizeof(struct waybright_renderer), 1);
    wb_renderer->wlr_output = wlr_output;
    wb_renderer->wlr_renderer = wb->wlr_renderer;

    struct waybright_monitor* wb_monitor = calloc(sizeof(struct waybright_monitor), 1);
    wb_monitor->wb = wb;
    wb_monitor->wb_renderer = wb_renderer;
    wb_monitor->wlr_output = wlr_output;

    wb_monitor->listeners.destroy.notify = handle_monitor_remove_event;
    wl_signal_add(&wlr_output->events.destroy, &wb_monitor->listeners.destroy);
    wb_monitor->listeners.frame.notify = handle_monitor_frame_event;
    wl_signal_add(&wlr_output->events.frame, &wb_monitor->listeners.frame);

    if (wb->handle_event)
        wb->handle_event(event_type_monitor_new, wb_monitor);
}

// Called when the surface has a displayable buffer
void handle_xdg_surface_map_event(struct wl_listener *listener, void *data) {
    struct waybright_window* wb_window = wl_container_of(listener, wb_window, listeners.map);

    wb_window->subwindow_tree = waybright_subwindow_tree_create(wb_window->wb, wb_window->wlr_xdg_surface->surface);

    struct waybright_window_event wb_window_event = { wb_window, NULL };

    if (wb_window->handle_event)
        wb_window->handle_event(event_type_window_map, &wb_window_event);
}

// Called when the surface no longer has a displayable buffer
void handle_xdg_surface_unmap_event(struct wl_listener *listener, void *data) {
    struct waybright_window* wb_window = wl_container_of(listener, wb_window, listeners.unmap);

    waybright_subwindow_tree_destroy(wb_window->subwindow_tree);
    wb_window->subwindow_tree = NULL;

    struct waybright_window_event wb_window_event = { wb_window, NULL };

    if (wb_window->handle_event)
        wb_window->handle_event(event_type_window_unmap, &wb_window_event);
}

// Called when the surface is about to be destroyed
void handle_xdg_surface_destroy_event(struct wl_listener *listener, void *data) {
    struct waybright_window* wb_window = wl_container_of(listener, wb_window, listeners.destroy);

    struct waybright_window_event wb_window_event = { wb_window, NULL };

    if (wb_window->handle_event)
        wb_window->handle_event(event_type_window_destroy, &wb_window_event);

    waybright_window_destroy(wb_window);
}

// Called when the top-level surface creates a new popup
void handle_xdg_surface_new_popup_event(struct wl_listener *listener, void *data) {
    struct waybright_window* wb_parent_window = wl_container_of(listener, wb_parent_window, listeners.new_popup);
    struct waybright* wb = wb_parent_window->wb;
    struct wlr_xdg_popup* wlr_xdg_popup = data;
    struct wlr_xdg_surface* wlr_xdg_surface = wlr_xdg_popup->base;

    struct waybright_window* wb_window = calloc(sizeof(struct waybright_window), 1);
    wb_window->wb = wb;
    wb_window->wlr_xdg_surface = wlr_xdg_surface;
    wb_window->wlr_xdg_toplevel = wb_parent_window->wlr_xdg_toplevel;
    wb_window->wlr_xdg_popup = wlr_xdg_popup;

    wb_window->listeners.map.notify = handle_xdg_surface_map_event;
    wl_signal_add(&wlr_xdg_surface->events.map, &wb_window->listeners.map);
    wb_window->listeners.unmap.notify = handle_xdg_surface_unmap_event;
    wl_signal_add(&wlr_xdg_surface->events.unmap, &wb_window->listeners.unmap);
    wb_window->listeners.destroy.notify = handle_xdg_surface_destroy_event;
    wl_signal_add(&wlr_xdg_surface->events.destroy, &wb_window->listeners.destroy);
    wb_window->listeners.new_popup.notify = handle_xdg_surface_new_popup_event;
    wl_signal_add(&wlr_xdg_surface->events.new_popup, &wb_window->listeners.new_popup);

    struct waybright_window_event wb_window_event = { wb_parent_window, wb_window };

    if (wb_parent_window->handle_event)
        wb_parent_window->handle_event(event_type_window_new_popup, &wb_window_event);
}

void handle_wlr_subsurface_map_event(struct wl_listener *listener, void* data) {
    struct waybright_subwindow* wb_subwindow = wl_container_of(listener, wb_subwindow, listeners.map);

    struct waybright_subwindow_tree* wb_subwindow_tree = waybright_subwindow_tree_create(wb_subwindow->wb, wb_subwindow->wlr_subsurface->surface);
    wb_subwindow_tree->parent = wb_subwindow->parent;
    wb_subwindow_tree->wb_subwindow = wb_subwindow;

    wb_subwindow->child = wb_subwindow_tree;
}

// TODO: pointer events for subsurfaces
// TODO: damage tracking for subsurfaces
void handle_wlr_subsurface_unmap_event(struct wl_listener *listener, void* data) {
    struct waybright_subwindow* wb_subwindow = wl_container_of(listener, wb_subwindow, listeners.unmap);

    if (wb_subwindow->child) {
        waybright_subwindow_tree_destroy(wb_subwindow->child);
        wb_subwindow->child = NULL;
    }
}

void handle_wlr_subsurface_destroy_event(struct wl_listener *listener, void* data) {
    struct waybright_subwindow* wb_subwindow = wl_container_of(listener, wb_subwindow, listeners.destroy);

    wl_list_remove(&wb_subwindow->link);
    waybright_subwindow_destroy(wb_subwindow);
}

void handle_wlr_subsurface_tree_commit_event(struct wl_listener *listener, void* data) {
    // struct waybright_subwindow_tree* wb_subwindow_tree = wl_container_of(listener, wb_subwindow_tree, listeners.commit);
    // struct waybright_window* wb_window = wb_subwindow_tree->wb_window;

    // struct waybright_window_event wb_window_event = { wb_window, NULL };

    // if (wb_window->handle_event)
    //     wb_window->handle_event(event_type_window_commit, &wb_window_event);
}

void handle_wlr_subsurface_tree_destroy_event(struct wl_listener *listener, void* data) {
    struct waybright_subwindow_tree* wb_subwindow_tree = wl_container_of(listener, wb_subwindow_tree, listeners.destroy);

    waybright_subwindow_tree_destroy(wb_subwindow_tree);
}

void handle_wlr_subsurface_new_event(struct wl_listener *listener, void* data) {
    struct waybright_subwindow_tree* wb_subwindow_tree = wl_container_of(listener, wb_subwindow_tree, listeners.new_subsurface);
    struct wlr_subsurface* wlr_subsurface = data;

    struct waybright_subwindow* wb_subwindow = waybright_subwindow_create(wlr_subsurface, wb_subwindow_tree);

    struct wlr_subsurface *wlr_subsurface_other;
    wl_list_for_each(wlr_subsurface_other, &wlr_subsurface->surface->current.subsurfaces_below, current.link) {
        handle_wlr_subsurface_new_event(&wb_subwindow_tree->listeners.new_subsurface, wlr_subsurface_other);
    }
    wl_list_for_each(wlr_subsurface_other, &wlr_subsurface->surface->current.subsurfaces_above, current.link) {
        handle_wlr_subsurface_new_event(&wb_subwindow_tree->listeners.new_subsurface, wlr_subsurface_other);
    }

    wl_list_insert(&wb_subwindow_tree->wb_subwindow_children, &wb_subwindow->link);
}


void handle_wlr_surface_commit_event(struct wl_listener *listener, void *data) {
    struct waybright_window* wb_window = wl_container_of(listener, wb_window, listeners.commit);

    struct waybright_window_event wb_window_event = { wb_window, NULL };

    if (wb_window->handle_event)
        wb_window->handle_event(event_type_window_commit, &wb_window_event);
}

// Called when the top-level surface wants to be moved
void handle_xdg_toplevel_request_move_event(struct wl_listener *listener, void *data) {
    struct waybright_window* wb_window = wl_container_of(listener, wb_window, listeners.request_move);
    struct wlr_xdg_toplevel_move_event* event = data;

    // Accept move requests only if it is a response to pointer button events
    if (event->serial != wb_window->wb->last_pointer_button_serial) return;

    struct waybright_window_event wb_window_event = { wb_window, event };

    if (wb_window->handle_event)
        wb_window->handle_event(event_type_window_request_move, &wb_window_event);
}

// Called when the top-level surface wants to be resized
void handle_xdg_toplevel_request_resize_event(struct wl_listener *listener, void *data) {
    struct waybright_window* wb_window = wl_container_of(listener, wb_window, listeners.request_resize);
    struct wlr_xdg_toplevel_resize_event *event = data;

    // Accept move requests only if it is a response to pointer button events
    if (event->serial != wb_window->wb->last_pointer_button_serial) return;

    struct waybright_window_event wb_window_event = { wb_window, event };

    if (wb_window->handle_event)
        wb_window->handle_event(event_type_window_request_resize, &wb_window_event);
}

// Called when the top-level surface wants to be (un)maximized
void handle_xdg_toplevel_request_maximize_event(struct wl_listener *listener, void *data) {
    struct waybright_window* wb_window = wl_container_of(listener, wb_window, listeners.request_maximize);

    struct waybright_window_event wb_window_event = { wb_window, NULL };

    if (wb_window->handle_event)
        wb_window->handle_event(event_type_window_request_maximize, &wb_window_event);
}

// Called when the top-level surface wants to be minimized
void handle_xdg_toplevel_request_minimize_event(struct wl_listener *listener, void *data) {
    struct waybright_window* wb_window = wl_container_of(listener, wb_window, listeners.request_minimize);

    struct waybright_window_event wb_window_event = { wb_window, NULL };

    if (wb_window->handle_event)
        wb_window->handle_event(event_type_window_request_minimize, &wb_window_event);
}

// Called when the top-level surface wants to be (un)fullscreened
void handle_xdg_toplevel_request_fullscreen_event(struct wl_listener *listener, void *data) {
    struct waybright_window* wb_window = wl_container_of(listener, wb_window, listeners.request_fullscreen);

    struct waybright_window_event wb_window_event = { wb_window, NULL };

    if (wb_window->handle_event)
        wb_window->handle_event(event_type_window_request_fullscreen, &wb_window_event);
}

// Called when the top-level surface wants a context menu to be shown
void handle_xdg_toplevel_request_show_window_menu_event(struct wl_listener *listener, void *data) {
    struct waybright_window* wb_window = wl_container_of(listener, wb_window, listeners.request_show_window_menu);
    struct wlr_xdg_toplevel_show_window_menu_event* event = data;

    struct waybright_window_event wb_window_event = { wb_window, &event };

    if (wb_window->handle_event)
        wb_window->handle_event(event_type_window_request_show_window_menu, &wb_window_event);
}

// Called when the top-level surface sets its title
void handle_xdg_toplevel_set_title_event(struct wl_listener *listener, void *data) {
    struct waybright_window* wb_window = wl_container_of(listener, wb_window, listeners.set_title);

    struct waybright_window_event wb_window_event = { wb_window, NULL };

    if (wb_window->handle_event)
        wb_window->handle_event(event_type_window_set_title, &wb_window_event);
}

// Called when the top-level surface sets its app id
void handle_xdg_toplevel_set_app_id_event(struct wl_listener *listener, void *data) {
    struct waybright_window* wb_window = wl_container_of(listener, wb_window, listeners.set_app_id);

    struct waybright_window_event wb_window_event = { wb_window, NULL };

    if (wb_window->handle_event)
        wb_window->handle_event(event_type_window_set_app_id, &wb_window_event);
}

// Called when the top-level surface sets its parent
void handle_xdg_toplevel_set_parent_event(struct wl_listener *listener, void *data) {
    struct waybright_window* wb_window = wl_container_of(listener, wb_window, listeners.set_parent);

    struct waybright_window_event wb_window_event = { wb_window, NULL };

    if (wb_window->handle_event)
        wb_window->handle_event(event_type_window_set_parent, &wb_window_event);
}

// Called when a new xdg surface is created
void handle_new_xdg_surface_event(struct wl_listener *listener, void *data) {
    struct waybright* wb = wl_container_of(listener, wb, listeners.new_xdg_surface);
    struct wlr_xdg_surface *wlr_xdg_surface = data;

    // We'll take care of popups in a separate handler
    if (wlr_xdg_surface->role != WLR_XDG_SURFACE_ROLE_TOPLEVEL)
        return;

    struct wlr_xdg_toplevel* wlr_xdg_toplevel = wlr_xdg_surface->toplevel;
    struct waybright_window* wb_window = waybright_window_create(wb, wlr_xdg_surface);

    wb_window->listeners.map.notify = handle_xdg_surface_map_event;
    wl_signal_add(&wlr_xdg_surface->events.map, &wb_window->listeners.map);
    wb_window->listeners.unmap.notify = handle_xdg_surface_unmap_event;
    wl_signal_add(&wlr_xdg_surface->events.unmap, &wb_window->listeners.unmap);
    wb_window->listeners.destroy.notify = handle_xdg_surface_destroy_event;
    wl_signal_add(&wlr_xdg_surface->events.destroy, &wb_window->listeners.destroy);
    wb_window->listeners.new_popup.notify = handle_xdg_surface_new_popup_event;
    wl_signal_add(&wlr_xdg_surface->events.new_popup, &wb_window->listeners.new_popup);
    wb_window->listeners.commit.notify = handle_wlr_surface_commit_event;
    wl_signal_add(&wlr_xdg_surface->surface->events.commit, &wb_window->listeners.commit);

    wb_window->listeners.request_move.notify = handle_xdg_toplevel_request_move_event;
    wl_signal_add(&wlr_xdg_toplevel->events.request_move, &wb_window->listeners.request_move);
    wb_window->listeners.request_resize.notify = handle_xdg_toplevel_request_resize_event;
    wl_signal_add(&wlr_xdg_toplevel->events.request_resize, &wb_window->listeners.request_resize);
    wb_window->listeners.request_maximize.notify = handle_xdg_toplevel_request_maximize_event;
    wl_signal_add(&wlr_xdg_toplevel->events.request_maximize, &wb_window->listeners.request_maximize);
    wb_window->listeners.request_minimize.notify = handle_xdg_toplevel_request_minimize_event;
    wl_signal_add(&wlr_xdg_toplevel->events.request_minimize, &wb_window->listeners.request_minimize);
    wb_window->listeners.request_fullscreen.notify = handle_xdg_toplevel_request_fullscreen_event;
    wl_signal_add(&wlr_xdg_toplevel->events.request_fullscreen, &wb_window->listeners.request_fullscreen);
    wb_window->listeners.request_show_window_menu.notify = handle_xdg_toplevel_request_show_window_menu_event;
    wl_signal_add(&wlr_xdg_toplevel->events.request_show_window_menu, &wb_window->listeners.request_show_window_menu);
    wb_window->listeners.set_title.notify = handle_xdg_toplevel_set_title_event;
    wl_signal_add(&wlr_xdg_toplevel->events.set_title, &wb_window->listeners.set_title);
    wb_window->listeners.set_app_id.notify = handle_xdg_toplevel_set_app_id_event;
    wl_signal_add(&wlr_xdg_toplevel->events.set_app_id, &wb_window->listeners.set_app_id);
    wb_window->listeners.set_parent.notify = handle_xdg_toplevel_set_parent_event;
    wl_signal_add(&wlr_xdg_toplevel->events.set_parent, &wb_window->listeners.set_parent);

    if (wb->handle_event)
        wb->handle_event(event_type_window_new, wb_window);
}

void handle_pointer_relative_move_event(struct wl_listener *listener, void *data) {
    struct waybright_pointer* wb_pointer = wl_container_of(listener, wb_pointer, listeners.relative_move);
    struct wlr_event_pointer_motion* event = data;

    struct waybright_pointer_event wb_pointer_event = {
        wb_pointer,
        event
    };

    if (wb_pointer->handle_event)
        wb_pointer->handle_event(event_type_pointer_relative_move, &wb_pointer_event);
}

void handle_pointer_absolute_move_event(struct wl_listener *listener, void *data) {
    struct waybright_pointer* wb_pointer = wl_container_of(listener, wb_pointer, listeners.absolute_move);
    struct wlr_event_pointer_motion_absolute* event = data;

    struct waybright_pointer_event wb_pointer_event = {
        wb_pointer,
        event
    };

    if (wb_pointer->handle_event)
        wb_pointer->handle_event(event_type_pointer_absolute_move, &wb_pointer_event);
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

void handle_pointer_frame_event(struct wl_listener *listener, void *data) {
    struct waybright_pointer* wb_pointer = wl_container_of(listener, wb_pointer, listeners.frame);

    wlr_seat_pointer_notify_frame(wb_pointer->wb->wlr_seat);
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
    struct waybright_pointer* wb_pointer = wl_container_of(listener, wb_pointer, listeners.destroy);

    if (wb_pointer->handle_event)
        wb_pointer->handle_event(event_type_pointer_remove, wb_pointer);

    waybright_pointer_destroy(wb_pointer);
}

void handle_pointer_new_event(struct waybright* wb, struct waybright_pointer* wb_pointer) {
    struct wlr_input_device* wlr_input_device = wb_pointer->wb_input->wlr_input_device;

    wb_pointer->listeners.destroy.notify = handle_pointer_remove_event;
    wl_signal_add(&wlr_input_device->events.destroy, &wb_pointer->listeners.destroy);

    struct wlr_pointer* wlr_pointer = wb_pointer->wlr_pointer;

    wb_pointer->listeners.relative_move.notify = handle_pointer_relative_move_event;
    wl_signal_add(&wlr_pointer->events.motion, &wb_pointer->listeners.relative_move);
    wb_pointer->listeners.absolute_move.notify = handle_pointer_absolute_move_event;
    wl_signal_add(&wlr_pointer->events.motion_absolute, &wb_pointer->listeners.absolute_move);
    wb_pointer->listeners.button.notify = handle_pointer_button_event;
    wl_signal_add(&wlr_pointer->events.button, &wb_pointer->listeners.button);
    wb_pointer->listeners.axis.notify = handle_pointer_axis_event;
    wl_signal_add(&wlr_pointer->events.axis, &wb_pointer->listeners.axis);
    wb_pointer->listeners.frame.notify = handle_pointer_frame_event;
    wl_signal_add(&wlr_pointer->events.frame, &wb_pointer->listeners.frame);
}

void handle_keyboard_remove_event(struct wl_listener* listener, void *data) {
    struct waybright_keyboard* wb_keyboard = wl_container_of(listener, wb_keyboard, listeners.destroy);

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

    wb_keyboard->listeners.destroy.notify = handle_keyboard_remove_event;
    wl_signal_add(&wlr_input_device->events.destroy, &wb_keyboard->listeners.destroy);
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

void handle_image_load_event(struct wl_listener *listener, void *data) {
    struct waybright_image* wb_image = wl_container_of(listener, wb_image, listeners.load);

    if (wb_image->is_loaded)
        return;

    struct wlr_texture* wlr_texture = wlr_surface_get_texture(wb_image->wlr_surface);

    if (!wlr_texture)
        return;

    wb_image->wlr_texture = wlr_texture;
    wb_image->width = wlr_texture->width;
    wb_image->height = wlr_texture->height;
    wb_image->is_loaded = true;

    if (wb_image->handle_event)
        wb_image->handle_event(event_type_image_load, wb_image);
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

    struct waybright_image_event wb_image_event = {
        .wb_image = NULL,
        .event = event
    };

    if (!wlr_surface) {
        if (wb->handle_event)
            wb->handle_event(event_type_cursor_image, &wb_image_event);
        return;
    }

    struct waybright_image* wb_image = waybright_image_create_from_surface(wlr_surface);
    wb_image_event.wb_image = wb_image;

    if (wb->handle_event)
        wb->handle_event(event_type_cursor_image, &wb_image_event);

    if (wb_image->handle_event)
        wb_image->handle_event(event_type_image_load, wb_image);
}
