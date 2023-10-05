#pragma once

#include <malloc.h>
#include <wayland-server-core.h>
#include <wlr/backend.h>
#include <wlr/render/allocator.h>
#include <wlr/render/wlr_renderer.h>
#include <wlr/types/wlr_compositor.h>
#include <wlr/types/wlr_input_device.h>
#include <wlr/types/wlr_keyboard.h>
#include <wlr/types/wlr_output.h>
#include <wlr/types/wlr_output_damage.h>
#include <wlr/types/wlr_pointer.h>
#include <wlr/types/wlr_seat.h>
#include <wlr/types/wlr_xdg_shell.h>
#include <wlr/util/edges.h>
#include <xkbcommon/xkbcommon.h>

enum wb_image_error_type {
    image_error_type_none,
    image_error_type_image_not_found,
    image_error_type_image_load_failed,
};

enum wb_event_type {
    event_type_monitor_new,
    event_type_monitor_remove,
    event_type_monitor_frame,

    event_type_window_new,
    event_type_window_destroy,
    event_type_window_map,
    event_type_window_unmap,
    event_type_window_new_popup,
    event_type_window_commit,
    event_type_window_request_move,
    event_type_window_request_resize,
    event_type_window_request_maximize,
    event_type_window_request_minimize,
    event_type_window_request_fullscreen,
    event_type_window_request_show_window_menu,
    event_type_window_set_title,
    event_type_window_set_app_id,
    event_type_window_set_parent,

    event_type_input_new,

    event_type_pointer_remove,
    event_type_pointer_move,
    event_type_pointer_teleport,
    event_type_pointer_button,
    event_type_pointer_axis,

    event_type_keyboard_remove,
    event_type_keyboard_key,
    event_type_keyboard_modifiers,

    event_type_cursor_image,

    event_type_image_destroy,
    event_type_image_load,
};

struct waybright {
    struct wl_display* wl_display;
    struct wlr_backend* wlr_backend;
    struct wlr_renderer* wlr_renderer;
    struct wlr_allocator* wlr_allocator;
    struct wlr_compositor* wlr_compositor;
    struct wlr_xdg_shell* wlr_xdg_shell;
    struct wlr_seat* wlr_seat;

    struct wl_event_loop* wl_event_loop;

    uint32_t last_pointer_button_serial;
    const char* socket_name;

    struct {
        struct wl_listener monitor_new;
        struct wl_listener new_xdg_surface;
        struct wl_listener input_new;
        struct wl_listener cursor_image;
    } listeners;

    void(*handle_event)(int type, void* data);
};

struct waybright_renderer {
    struct wlr_output* wlr_output;
    struct wlr_renderer* wlr_renderer;
};

struct waybright_image_event {
    struct waybright_image* wb_image;
    void* event;
};

struct waybright_image {
    struct wlr_surface* wlr_surface;
    struct wlr_texture* wlr_texture;

    bool is_loaded;
    const char* path;

    struct {
        struct wl_listener load;
        struct wl_listener destroy;
    } listeners;

    int width;
    int height;

    void(*handle_event)(int type, void* data);
};

struct waybright_monitor {
    struct waybright* wb;
    struct waybright_renderer* wb_renderer;
    struct wlr_output* wlr_output;

    struct {
        struct wl_listener destroy;
        struct wl_listener frame;
    } listeners;

    void(*handle_event)(int type, void* data);
};

struct waybright_window_event {
    struct waybright_window* wb_window;
    void* event;
};

struct waybright_window {
    struct waybright* wb;
    struct wlr_xdg_surface* wlr_xdg_surface;
    struct wlr_xdg_toplevel* wlr_xdg_toplevel;
    struct wlr_xdg_popup* wlr_xdg_popup;

    struct {
        struct wl_listener destroy;
        struct wl_listener map;
        struct wl_listener unmap;
        struct wl_listener new_popup;
        struct wl_listener commit;
        struct wl_listener request_move;
        struct wl_listener request_maximize;
        struct wl_listener request_minimize;
        struct wl_listener request_fullscreen;
        struct wl_listener request_show_window_menu;
        struct wl_listener request_resize;
        struct wl_listener set_title;
        struct wl_listener set_app_id;
        struct wl_listener set_parent;
    } listeners;

    void(*handle_event)(int type, void* data);
};

struct waybright_input {
    struct waybright* wb;
    struct wlr_input_device* wlr_input_device;

    struct waybright_pointer* pointer;
    struct waybright_keyboard* keyboard;
};

struct waybright_pointer_event {
    struct waybright_pointer* wb_pointer;
    void* event;
};

struct waybright_pointer {
    struct waybright* wb;
    struct waybright_input* wb_input;
    struct wlr_pointer* wlr_pointer;

    double x;
    double y;

    struct {
        struct wl_listener destroy;
        struct wl_listener move;
        struct wl_listener teleport;
        struct wl_listener button;
        struct wl_listener axis;
        struct wl_listener frame;
    } listeners;

    void(*handle_event)(int type, void* data);
};

struct waybright_keyboard_event {
    struct waybright_keyboard* wb_keyboard;
    void* event;
};

struct waybright_keyboard {
    struct waybright* wb;
    struct waybright_input* wb_input;
    struct wlr_keyboard* wlr_keyboard;

    struct {
        struct wl_listener destroy;
        struct wl_listener key;
        struct wl_listener modifiers;
    } listeners;

    void(*handle_event)(int type, void* data);
};


int get_color_from_array(float* color_array);
void set_color_to_array(int color, float* color_array);

struct wlr_output_mode* waybright_get_wlr_output_mode_from_wl_list(struct wl_list *ptr);
struct waybright* waybright_create();
void waybright_destroy(struct waybright* wb);
int waybright_init(struct waybright*);

/// @param socket_name can be NULL to auto-select a name
int waybright_open_socket(struct waybright* wb, const char* socket_name);
void waybright_check_events(struct waybright* wb);
void waybright_close_socket(struct waybright* wb);
struct waybright_image* waybright_load_image(struct waybright* wb, const char* path, int* error);

void waybright_renderer_destroy(struct waybright_renderer* wb_renderer);
void waybright_renderer_begin(struct waybright_renderer* wb_renderer);
void waybright_renderer_end(struct waybright_renderer* wb_renderer);
void waybright_renderer_render(struct waybright_renderer* wb_renderer);
void waybright_renderer_scissor(struct waybright_renderer* wb_renderer, int x, int y, int width, int height);
void waybright_renderer_clear(struct waybright_renderer* wb_renderer, int color);
void waybright_renderer_fill_rect(struct waybright_renderer* wb_renderer, int x, int y, int width, int height, int color);
void waybright_renderer_draw_window(struct waybright_renderer* wb_renderer, struct waybright_window* wb_window, int x, int y, int width, int height, float alpha);
void waybright_renderer_draw_image(struct waybright_renderer* wb_renderer, struct waybright_image* wb_image, int x, int y, int width, int height, float alpha);
struct waybright_image* waybright_renderer_capture_window_frame(struct waybright_renderer* wb_renderer, struct waybright_window* wb_window);

void waybright_monitor_destroy(struct waybright_monitor* wb_monitor);
void waybright_monitor_enable(struct waybright_monitor* wb_monitor);
void waybright_monitor_disable(struct waybright_monitor* wb_monitor);

void waybright_window_destroy(struct waybright_window* wb_window);
void waybright_window_submit_pointer_move_event(struct waybright_window* wb_window, int time, int sx, int sy);
void waybright_window_submit_pointer_button_event(struct waybright_window* wb_window, int time, int button, int pressed);
void waybright_window_submit_pointer_axis_event(struct waybright_window* wb_window, int time, int orientation, double delta, int delta_discrete, int source);
void waybright_window_submit_keyboard_key_event(struct waybright_window* wb_window, int time, int keyCode, int pressed);
void waybright_window_submit_keyboard_modifiers_event(struct waybright_window* wb_window, struct waybright_keyboard* wb_keyboard);

void waybright_pointer_destroy(struct waybright_pointer* wb_pointer);
void waybright_pointer_focus_on_window(struct waybright_pointer* wb_pointer, struct waybright_window* wb_window, int sx, int sy);
void waybright_pointer_clear_focus(struct waybright_pointer* wb_pointer);

void waybright_keyboard_destroy(struct waybright_keyboard* wb_keyboard);
void waybright_keyboard_focus_on_window(struct waybright_keyboard* wb_keyboard, struct waybright_window* wb_window);
void waybright_keyboard_clear_focus(struct waybright_keyboard* wb_keyboard);

void waybright_image_destroy(struct waybright_image* wb_image);
struct waybright_image* waybright_image_create_from_surface(struct wlr_surface* wlr_surface);
struct waybright_image* waybright_image_create_from_texture(struct wlr_texture* wlr_texture);
