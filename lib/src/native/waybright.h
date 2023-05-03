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

enum wb_event_type {
    event_type_monitor_new,
    event_type_monitor_remove,
    event_type_monitor_frame,

    event_type_window_new,
    event_type_window_remove,
    event_type_window_show,
    event_type_window_hide,
    event_type_window_move,
    event_type_window_maximize,
    event_type_window_fullscreen,
    event_type_window_resize,

    event_type_input_new,

    event_type_pointer_remove,
    event_type_pointer_move,
    event_type_pointer_teleport,
    event_type_pointer_button,
    event_type_pointer_axis,

    event_type_keyboard_remove,
    event_type_keyboard_key,
    event_type_keyboard_modifiers,
};

struct waybright {
    struct wl_display* wl_display;
    struct wlr_backend* wlr_backend;
    struct wlr_renderer* wlr_renderer;
    struct wlr_allocator* wlr_allocator;
    struct wlr_compositor* wlr_compositor;
    struct wlr_xdg_shell* wlr_xdg_shell;
    struct wlr_seat* wlr_seat;

    uint32_t last_pointer_button_serial;
    const char* socket_name;

    struct {
        struct wl_listener monitor_new;
        struct wl_listener window_new;
        struct wl_listener input_new;
    } listeners;

    void(*handle_event)(int type, void* data);
};

struct waybright_renderer {
    struct wlr_output* wlr_output;
    struct wlr_renderer* wlr_renderer;

    float color_fill[4];
    float color_background[4];
};

struct waybright_image {
    struct wlr_texture* wlr_texture;

    const char* path;

    int width;
    int height;
};

struct waybright_monitor {
    struct waybright* wb;
    struct waybright_renderer* wb_renderer;
    struct wlr_output* wlr_output;

    struct {
        struct wl_listener remove;
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

    int is_popup;

    struct {
        struct wl_listener remove;
        struct wl_listener show;
        struct wl_listener hide;
        struct wl_listener move;
        struct wl_listener maximize;
        struct wl_listener fullscreen;
        struct wl_listener resize;
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
        struct wl_listener remove;
        struct wl_listener move;
        struct wl_listener teleport;
        struct wl_listener button;
        struct wl_listener axis;
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
        struct wl_listener remove;
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
void waybright_run_event_loop(struct waybright* wb);
void waybright_close_socket(struct waybright* wb);
struct waybright_image* waybright_load_png_image(struct waybright* wb, const char* path);

void waybright_renderer_destroy(struct waybright_renderer* wb_renderer);
void waybright_renderer_set_background_color(struct waybright_renderer* wb_renderer, int color);
int waybright_renderer_get_background_color(struct waybright_renderer* wb_renderer);
int waybright_renderer_get_fill_style(struct waybright_renderer* wb_renderer);
void waybright_renderer_set_fill_style(struct waybright_renderer* wb_renderer, int color);
void waybright_renderer_clear_rect(struct waybright_renderer* wb_renderer, int x, int y, int width, int height);
void waybright_renderer_fill_rect(struct waybright_renderer* wb_renderer, int x, int y, int width, int height);
void waybright_renderer_draw_window(struct waybright_renderer* wb_renderer, struct waybright_window* wb_window, int x, int y, int width, int height);
void waybright_renderer_draw_image(struct waybright_renderer* wb_renderer, struct waybright_image* wb_image, int x, int y, int width, int height);

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
