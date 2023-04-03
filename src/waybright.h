#include <wayland-server-core.h>
#include <wlr/backend.h>
#include <malloc.h>

struct waybright {
    struct wl_display* wl_display;
    struct wlr_backend* wlr_backend;
    const char* socket_name;
};

struct waybright* waybright_create();
void waybright_destroy(struct waybright* wb);
int waybright_init(struct waybright*);
/// @param socket_name can be NULL to auto-select a name
int waybright_open_socket(struct waybright* wb, const char* socket_name);
void waybright_run(struct waybright* wb);
