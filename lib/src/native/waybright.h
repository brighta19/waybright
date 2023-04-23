#include <wayland-server-core.h>
#include <wlr/backend.h>
#include <wlr/render/allocator.h>
#include <wlr/render/wlr_renderer.h>
#include <wlr/types/wlr_compositor.h>
#include <wlr/types/wlr_input_device.h>
#include <wlr/types/wlr_keyboard.h>
#include <wlr/types/wlr_output.h>
#include <wlr/types/wlr_output_damage.h>
#include <wlr/types/wlr_xdg_shell.h>
#include <wlr/types/wlr_seat.h>
#include <wlr/types/wlr_pointer.h>
#include <malloc.h>

enum event_type {
    event_type_monitor_new,
    event_type_monitor_remove,
    event_type_monitor_frame,

    event_type_window_new,
    event_type_window_remove,
    event_type_window_show,
    event_type_window_hide,

    event_type_input_new,

    event_type_pointer_move,
    event_type_pointer_teleport,
    event_type_pointer_button,
    event_type_pointer_remove,

    event_type_keyboard_remove,
};

struct waybright {
    struct wl_display* wl_display;
    struct wlr_backend* wlr_backend;
    struct wlr_renderer* wlr_renderer;
    struct wlr_allocator* wlr_allocator;
    struct wlr_compositor* wlr_compositor;
    struct wlr_xdg_shell* wlr_xdg_shell;
    struct wlr_seat* wlr_seat;

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
};

struct waybright_monitor {
    struct waybright* wb;
    struct waybright_renderer* wb_renderer;
    struct wlr_output* wlr_output;

    float background_color[4];

    struct {
        struct wl_listener remove;
        struct wl_listener frame;
    } listeners;

    void(*handle_event)(int type, void* data);
};

struct waybright_window {
    struct waybright* wb;
    struct wlr_xdg_surface* wlr_xdg_surface;
    struct wlr_xdg_toplevel* wlr_xdg_toplevel;

    int is_popup;

    struct {
        struct wl_listener show;
        struct wl_listener hide;
        struct wl_listener remove;
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
        struct wl_listener move;
        struct wl_listener teleport;
        struct wl_listener button;
        struct wl_listener remove;
    } listeners;

    void(*handle_event)(int type, void* data);
};

struct waybright_keyboard {
    struct waybright* wb;
    struct waybright_input* wb_input;
    struct wlr_keyboard* wlr_keyboard;

    struct {
        struct wl_listener remove;
    } listeners;

    void(*handle_event)(int type, void* data);
};

struct wlr_output_mode* get_wlr_output_mode_from_wl_list(struct wl_list *ptr);
struct waybright* waybright_create();
void waybright_destroy(struct waybright* wb);
int waybright_init(struct waybright*);

/// @param socket_name can be NULL to auto-select a name
int waybright_open_socket(struct waybright* wb, const char* socket_name);
void waybright_run_event_loop(struct waybright* wb);

int waybright_renderer_get_fill_style(struct waybright_renderer* wb_renderer);
void waybright_renderer_set_fill_style(struct waybright_renderer* wb_renderer, int color);
void waybright_renderer_clear_rect(struct waybright_renderer* wb_renderer, int x, int y, int width, int height);
void waybright_renderer_fill_rect(struct waybright_renderer* wb_renderer, int x, int y, int width, int height);
void waybright_renderer_draw_window(struct waybright_renderer* wb_renderer, struct waybright_window* wb_window, int x, int y);

void waybright_monitor_enable(struct waybright_monitor* wb_monitor);
void waybright_monitor_disable(struct waybright_monitor* wb_monitor);
void waybright_monitor_set_background_color(struct waybright_monitor* wb_monitor, int color);
int waybright_monitor_get_background_color(struct waybright_monitor* wb_monitor);

void waybright_window_focus(struct waybright_window* wb_window);
void waybright_window_blur(struct waybright_window* wb_window);
void waybright_window_submit_pointer_move_event(struct waybright_window* wb_window, int time, int sx, int sy);
void waybright_window_submit_pointer_button_event(struct waybright_window* wb_window, int time, int button, int pressed);

void waybright_pointer_focus_on_window(struct waybright_pointer* wb_pointer, struct waybright_window* wb_window, int sx, int sy);
void waybright_pointer_clear_focus(struct waybright_pointer* wb_pointer);
