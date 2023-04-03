#include "wayland-server-core.h"
// #include <wlr/backend.h>
#include "malloc.h"

struct waybright {
    struct wl_display* display;
    // struct wlr_backend* backend;
    const char* socket_name;
};

struct waybright* waybright_create();
void waybright_destroy(struct waybright* wb);
int waybright_init(struct waybright*);
int waybright_open_socket(struct waybright* wb);
int waybright_open_socket_with_name(struct waybright* wb, const char* name);
void waybright_run(struct waybright* wb);
