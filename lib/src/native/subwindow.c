#include "waybright.h"
#include "handlers.h"

struct waybright_subwindow* waybright_subwindow_create(struct wlr_subsurface* wlr_subsurface, struct waybright_subwindow_tree* parent) {
    struct waybright_subwindow* wb_subwindow = calloc(sizeof(struct waybright_subwindow), 1);

    wb_subwindow->wb = parent->wb;
    wb_subwindow->wlr_subsurface = wlr_subsurface;
    wb_subwindow->parent = parent;

    wb_subwindow->listeners.map.notify = handle_wlr_subsurface_map_event;
    wl_signal_add(&wlr_subsurface->events.map, &wb_subwindow->listeners.map);
    wb_subwindow->listeners.unmap.notify = handle_wlr_subsurface_unmap_event;
    wl_signal_add(&wlr_subsurface->events.unmap, &wb_subwindow->listeners.unmap);
    wb_subwindow->listeners.destroy.notify = handle_wlr_subsurface_destroy_event;
    wl_signal_add(&wlr_subsurface->events.destroy, &wb_subwindow->listeners.destroy);

    return wb_subwindow;
}

void waybright_subwindow_destroy(struct waybright_subwindow* wb_subwindow) {
    if (!wb_subwindow) return;

    if (wb_subwindow->child) {
        waybright_subwindow_tree_destroy(wb_subwindow->child);
    }

    wl_list_remove(&wb_subwindow->listeners.map.link);
    wl_list_remove(&wb_subwindow->listeners.unmap.link);
    wl_list_remove(&wb_subwindow->listeners.destroy.link);

    free(wb_subwindow);
}

struct waybright_subwindow_tree* waybright_subwindow_tree_create(struct waybright* wb, struct wlr_surface* wlr_surface) {
    struct waybright_subwindow_tree* wb_subwindow_tree = calloc(sizeof(struct waybright_subwindow_tree), 1);
    wb_subwindow_tree->wb = wb;

    wb_subwindow_tree->wlr_surface = wlr_surface;

    wl_list_init(&wb_subwindow_tree->wb_subwindow_children);

    wb_subwindow_tree->listeners.new_subsurface.notify = handle_wlr_subsurface_new_event;
    wl_signal_add(&wlr_surface->events.new_subsurface, &wb_subwindow_tree->listeners.new_subsurface);
    wb_subwindow_tree->listeners.commit.notify = handle_wlr_subsurface_tree_commit_event;
    wl_signal_add(&wlr_surface->events.commit, &wb_subwindow_tree->listeners.commit);
    wb_subwindow_tree->listeners.destroy.notify = handle_wlr_subsurface_tree_destroy_event;
    wl_signal_add(&wlr_surface->events.destroy, &wb_subwindow_tree->listeners.destroy);

    struct wlr_subsurface *wlr_subsurface;
    wl_list_for_each(wlr_subsurface, &wlr_surface->current.subsurfaces_below, current.link) {
        handle_wlr_subsurface_new_event(&wb_subwindow_tree->listeners.new_subsurface, wlr_subsurface);
    }
    wl_list_for_each(wlr_subsurface, &wlr_surface->current.subsurfaces_above, current.link) {
        handle_wlr_subsurface_new_event(&wb_subwindow_tree->listeners.new_subsurface, wlr_subsurface);
    }

    return wb_subwindow_tree;
}

void waybright_subwindow_tree_destroy(struct waybright_subwindow_tree* waybright_subwindow_tree) {
    if (!waybright_subwindow_tree) return;

    struct waybright_subwindow* child_subwindow;
    wl_list_for_each(child_subwindow, &waybright_subwindow_tree->wb_subwindow_children, link) {
        waybright_subwindow_destroy(child_subwindow);
    }

    wl_list_remove(&waybright_subwindow_tree->listeners.new_subsurface.link);
    wl_list_remove(&waybright_subwindow_tree->listeners.commit.link);
    wl_list_remove(&waybright_subwindow_tree->listeners.destroy.link);

    free(waybright_subwindow_tree);
}
