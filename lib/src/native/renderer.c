#define _POSIX_C_SOURCE 200809L

#include <time.h>
#include <wlr/render/gles2.h>
#include <wlr/types/wlr_matrix.h>
#include <wlr/util/box.h>
#include "waybright.h"

void waybright_renderer_destroy(struct waybright_renderer* wb_renderer) {
    if (!wb_renderer) return;

    free(wb_renderer);
}

void waybright_renderer_clear(struct waybright_renderer* wb_renderer, int color) {
    struct wlr_output* wlr_output = wb_renderer->wlr_output;
    struct wlr_renderer* wlr_renderer = wlr_output->renderer;

    float color_array[4];
    set_color_to_array(color, color_array);

    wlr_renderer_clear(wlr_renderer, color_array);
}

void waybright_renderer_fill_rect(struct waybright_renderer* wb_renderer, int x, int y, int width, int height, int color) {
    struct wlr_output* wlr_output = wb_renderer->wlr_output;
    struct wlr_renderer* wlr_renderer = wlr_output->renderer;

    float color_array[4];
    set_color_to_array(color, color_array);

    struct wlr_box wlr_box = { .x = x, .y = y, .width = width, .height = height };
    wlr_render_rect(wlr_renderer, &wlr_box, color_array, wlr_output->transform_matrix);
}

void waybright_renderer_draw_window(struct waybright_renderer* wb_renderer, struct waybright_window* wb_window, int x, int y, int width, int height, float alpha) {
    struct wlr_output* wlr_output = wb_renderer->wlr_output;
    struct wlr_renderer* wlr_renderer = wlr_output->renderer;
    struct wlr_surface* wlr_surface = wb_window->wlr_xdg_surface->surface;

    struct wlr_texture* wlr_texture = wlr_surface_get_texture(wlr_surface);
    if (!wlr_texture)
        return;

    struct wlr_box wlr_box = {
        .x = x,
        .y = y,
        .width = width,
        .height = height
    };

    float matrix[9];
    wlr_matrix_project_box(matrix, &wlr_box, wlr_surface->current.transform, 0.0, wlr_output->transform_matrix);

    struct wlr_fbox wlr_fbox;
    wlr_surface_get_buffer_source_box(wlr_surface, &wlr_fbox);

    wlr_render_subtexture_with_matrix(wlr_renderer, wlr_texture, &wlr_fbox, matrix, alpha);

    struct timespec now;
    clock_gettime(CLOCK_MONOTONIC, &now);
    wlr_surface_send_frame_done(wlr_surface, &now);
}

void waybright_renderer_draw_image(struct waybright_renderer* wb_renderer, struct waybright_image* wb_image, int x, int y, int width, int height, float alpha) {
    // BUG: When trying to read the texture's width and height, the program crashes
    // (segmentation fault). It happens when I create a transient window from
    // the `weston-stacking` program. Something to do with the cursor image.
    // TODO: fix this function

    struct wlr_output* wlr_output = wb_renderer->wlr_output;
    struct wlr_renderer* wlr_renderer = wlr_output->renderer;

    struct wlr_texture* wlr_texture = wb_image->wlr_texture;
    if (!wlr_texture)
        return;

    struct wlr_box wlr_box = {
        .x = x,
        .y = y,
        .width = width,
        .height = height
    };

    float matrix[9];
    wlr_matrix_project_box(matrix, &wlr_box, WL_OUTPUT_TRANSFORM_NORMAL, 0.0, wlr_output->transform_matrix);

    // A fix for the assertion failure on wlr_texture_is_gles2(wlr_texture).
    // The pointer to the texture's implementation is different from the
    // pointer to the renderer's implementation.
    if (wlr_renderer_is_gles2(wlr_renderer) && !wlr_texture_is_gles2(wlr_texture))
        return;

    wlr_render_texture_with_matrix(wlr_renderer, wlr_texture, matrix, alpha);
}

struct waybright_image* waybright_renderer_capture_window_frame(struct waybright_renderer* wb_renderer, struct waybright_window* wb_window) {
    struct wlr_surface* wlr_surface = wb_window->wlr_xdg_surface->surface;
    struct wlr_renderer* wlr_renderer = wb_renderer->wlr_renderer;

    struct wlr_buffer* wlr_buffer = wlr_surface->buffer->source;
    if (!wlr_buffer) {
        fprintf(stderr, "waybright_renderer_capture_window_frame: wlr_buffer is NULL\n");
        return NULL;
    }

    wlr_buffer_lock(wlr_buffer);

    struct wlr_texture* wlr_texture = wlr_texture_from_buffer(wlr_renderer, wlr_buffer);

    wlr_buffer_unlock(wlr_buffer);

    if (!wlr_texture) {
        fprintf(stderr, "waybright_renderer_capture_window_frame: wlr_texture is NULL\n");
        return NULL;
    }

    struct waybright_image* wb_image = malloc(sizeof(struct waybright_image));
    wb_image->wlr_texture = wlr_texture;
    wb_image->width = wlr_texture->width;
    wb_image->height = wlr_texture->height;
    wb_image->is_loaded = true;

    return wb_image;
}

void waybright_renderer_begin(struct waybright_renderer* wb_renderer) {
    struct wlr_output* wlr_output = wb_renderer->wlr_output;
    struct wlr_renderer* wlr_renderer = wlr_output->renderer;

    if (wlr_output->back_buffer == NULL) {
        if (!wlr_output_attach_render(wlr_output, NULL)) {
            return;
        }
    }


    int width, height;

    // "Computes the transformed and scaled output resolution."
    wlr_output_effective_resolution(wlr_output, &width, &height);

    wlr_renderer_begin(wlr_renderer, width, height);
}

void waybright_renderer_end(struct waybright_renderer* wb_renderer) {
    struct wlr_output* wlr_output = wb_renderer->wlr_output;
    struct wlr_renderer* wlr_renderer = wlr_output->renderer;

    wlr_renderer_end(wlr_renderer);
}

void waybright_renderer_render(struct waybright_renderer* wb_renderer) {
    struct wlr_output* wlr_output = wb_renderer->wlr_output;

    if (!wlr_output_commit(wlr_output))
        wlr_output_schedule_frame(wlr_output);

    // wlr_output_commit(wlr_output);
}

void waybright_renderer_scissor(struct waybright_renderer* wb_renderer, int x, int y, int width, int height) {
    struct wlr_output* wlr_output = wb_renderer->wlr_output;
    struct wlr_renderer* wlr_renderer = wlr_output->renderer;

    wlr_renderer_scissor(wlr_renderer, &(struct wlr_box) {
        .x = x,
        .y = y,
        .width = width,
        .height = height
    });
}
