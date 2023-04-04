#include <wayland-server-core.h>
#include <wlr/backend.h>
#include <wlr/render/allocator.h>
#include <wlr/types/wlr_output.h>
#include <wlr/render/wlr_renderer.h>
#include <malloc.h>

enum event_type {
    event_type_monitor_add,
    event_type_monitor_remove,
    event_type_monitor_frame,
};
struct waybright {
    struct wl_display* wl_display;
    struct wlr_backend* wlr_backend;
    struct wlr_renderer* wlr_renderer;
    struct wlr_allocator* wlr_allocator;
    const char* socket_name;

    struct {
        struct wl_listener monitor_add;
    } listeners;

    void(*handle_event)(int type, void* data);
};

struct waybright_monitor {
    struct waybright* wb;
    struct wlr_output* wlr_output;

    struct {
        struct wl_listener remove;
        struct wl_listener frame;
    } listeners;

    void(*handle_event)(int type, void* data);
};


struct wlr_output_mode* get_wlr_output_mode_from_wl_list(struct wl_list *ptr);
void waybright_monitor_set_event_handler(struct waybright_monitor* wb_monitor, void(*event_handler)(int event_type, void* data));
struct waybright* waybright_create();
void waybright_destroy(struct waybright* wb);
int waybright_init(struct waybright*);
void waybright_set_event_handler(struct waybright* wb, void(*event_handler)(int event_type, void* data));
/// @param socket_name can be NULL to auto-select a name
int waybright_open_socket(struct waybright* wb, const char* socket_name);
void waybright_run_event_loop(struct waybright* wb);
