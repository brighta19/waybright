#include "waybright.h"

void waybright_monitor_destroy(struct waybright_monitor* wb_monitor) {
    if (!wb_monitor) return;

    waybright_renderer_destroy(wb_monitor->wb_renderer);

    free(wb_monitor);
}

void waybright_monitor_enable(struct waybright_monitor* wb_monitor) {
    wlr_output_enable(wb_monitor->wlr_output, true);
    wlr_output_commit(wb_monitor->wlr_output);
}

void waybright_monitor_disable(struct waybright_monitor* wb_monitor) {
    wlr_output_enable(wb_monitor->wlr_output, false);
}
