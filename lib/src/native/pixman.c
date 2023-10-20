#include "waybright.h"

void waybright_pixman_region32_init(struct pixman_region32* region) {
    return pixman_region32_init(region);
}

struct pixman_box32* waybright_pixman_region32_rectangles(struct pixman_region32* region, int* n_rects) {
    return pixman_region32_rectangles(region, n_rects);
}

void waybright_pixman_region32_fini(struct pixman_region32* region) {
    return pixman_region32_fini(region);
}
