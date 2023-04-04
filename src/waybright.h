#include <wayland-server-core.h>
#include <wlr/backend.h>
#include <wlr/render/allocator.h>
#include <wlr/types/wlr_output.h>
#include <wlr/render/wlr_renderer.h>
#include <malloc.h>

enum events {
    events_monitor_add,
    events_monitor_remove
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

    void(*handler)(int type, void* data);
};

struct waybright_monitor {
    struct waybright* wb;
    struct wlr_output* wlr_output;

    struct {
        struct wl_listener remove;
    } listeners;

    void(*handler)(int type, void* data);
};


struct wlr_output_mode* wl_list_wlr_output_mode_item(struct wl_list *ptr);
struct waybright* waybright_create();
void waybright_destroy(struct waybright* wb);
int waybright_init(struct waybright*);
void waybright_set_handler(struct waybright* wb, void(*handler)(int type, void* data));
/// @param socket_name can be NULL to auto-select a name
int waybright_open_socket(struct waybright* wb, const char* socket_name);
void waybright_run(struct waybright* wb);

void waybright_monitor_set_handler(struct waybright_monitor* wbo, void(*handler)(int type, void* data));
