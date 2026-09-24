#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <stdbool.h>
#include <string.h>
#include <unistd.h>
#include <signal.h>
#include <math.h>
#include <sys/mman.h>
#include <sys/syscall.h>
#include <fcntl.h>
#include <time.h>
#include <wayland-client.h>
#include "wlr-screencopy-client-protocol.h"

#define INTERVAL_MS 300
#define DELTA_THRESHOLD 18
#define SYSFS_PATH "/sys/devices/platform/asus-nb-wmi/leds/asus::kbd_backlight/kbd_rgb_mode"

static volatile sig_atomic_t g_running = 1;

static void sig_handler(int sig) {
    (void)sig;
    g_running = 0;
}

// Convert RGB (0..255) to HSV
static void rgb_to_hsv(double r, double g, double b, double *h, double *s, double *v) {
    double min_val = fmin(fmin(r, g), b);
    double max_val = fmax(fmax(r, g), b);
    double delta = max_val - min_val;

    *v = max_val;
    if (max_val > 0.0001) {
        *s = delta / max_val;
    } else {
        *s = 0;
        *h = 0;
        return;
    }

    if (delta < 0.0001) {
        *h = 0;
    } else if (max_val == r) {
        *h = 60.0 * fmod(((g - b) / delta), 6.0);
    } else if (max_val == g) {
        *h = 60.0 * (((b - r) / delta) + 2.0);
    } else {
        *h = 60.0 * (((r - g) / delta) + 4.0);
    }
    if (*h < 0.0) *h += 360.0;
}

// Convert HSV to RGB (0..255)
static void hsv_to_rgb(double h, double s, double v, double *r, double *g, double *b) {
    double c = v * s;
    double x = c * (1.0 - fabs(fmod(h / 60.0, 2.0) - 1.0));
    double m = v - c;
    double r1, g1, b1;

    if (h < 60.0) {
        r1 = c; g1 = x; b1 = 0;
    } else if (h < 120.0) {
        r1 = x; g1 = c; b1 = 0;
    } else if (h < 180.0) {
        r1 = 0; g1 = c; b1 = x;
    } else if (h < 240.0) {
        r1 = 0; g1 = x; b1 = c;
    } else if (h < 300.0) {
        r1 = x; g1 = 0; b1 = c;
    } else {
        r1 = c; g1 = 0; b1 = x;
    }

    *r = (r1 + m) * 255.0;
    *g = (g1 + m) * 255.0;
    *b = (b1 + m) * 255.0;
}

// Enhance color vibrancy so it cuts through plastic keycaps cleanly
static void enhance_vibrancy(uint8_t in_r, uint8_t in_g, uint8_t in_b,
                             uint8_t *out_r, uint8_t *out_g, uint8_t *out_b) {
    double r = in_r / 255.0;
    double g = in_g / 255.0;
    double b = in_b / 255.0;
    double h, s, v;

    rgb_to_hsv(r, g, b, &h, &s, &v);

    // If there is visible color, boost saturation to prevent keycap washout
    if (s > 0.10) {
        s = fmin(1.0, s * 1.30);
    }
    // Scale value for rich LED glow without blinding
    if (v > 0.15) {
        v = fmin(1.0, pow(v, 0.85) * 1.15);
    }

    double er, eg, eb;
    hsv_to_rgb(h, s, v, &er, &eg, &eb);

    *out_r = (uint8_t)fmin(255.0, fmax(0.0, er));
    *out_g = (uint8_t)fmin(255.0, fmax(0.0, eg));
    *out_b = (uint8_t)fmin(255.0, fmax(0.0, eb));
}

struct app_state {
    struct wl_display *display;
    struct wl_registry *registry;
    struct wl_shm *shm;
    struct wl_output *output;
    struct zwlr_screencopy_manager_v1 *screencopy_manager;
    
    int width, height, stride, format;
    int frame_ready;
    int frame_failed;
    
    void *data;
    size_t size;
    struct wl_buffer *buffer;
    
    uint32_t avg_r, avg_g, avg_b;
    uint8_t last_r, last_g, last_b;
    bool has_last;
    
    int sysfs_fd;
};

static void frame_handle_buffer(void *data, struct zwlr_screencopy_frame_v1 *frame,
                               uint32_t format, uint32_t width, uint32_t height, uint32_t stride) {
    struct app_state *state = data;
    state->format = format;
    state->width = width;
    state->height = height;
    state->stride = stride;
    state->size = stride * height;

    if (!state->buffer) {
        int fd = memfd_create("asus_ambilight_shm", MFD_CLOEXEC);
        if (fd < 0) return;
        if (ftruncate(fd, state->size) < 0) {
            close(fd);
            return;
        }
        state->data = mmap(NULL, state->size, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
        if (state->data == MAP_FAILED) {
            close(fd);
            state->data = NULL;
            return;
        }
        struct wl_shm_pool *pool = wl_shm_create_pool(state->shm, fd, state->size);
        state->buffer = wl_shm_pool_create_buffer(pool, 0, width, height, stride, format);
        wl_shm_pool_destroy(pool);
        close(fd);
    }

    zwlr_screencopy_frame_v1_copy(frame, state->buffer);
}

static void frame_handle_flags(void *data, struct zwlr_screencopy_frame_v1 *frame, uint32_t flags) {
    (void)data; (void)frame; (void)flags;
}

static void frame_handle_ready(void *data, struct zwlr_screencopy_frame_v1 *frame,
                              uint32_t tv_sec_hi, uint32_t tv_sec_lo, uint32_t tv_nsec) {
    (void)frame; (void)tv_sec_hi; (void)tv_sec_lo; (void)tv_nsec;
    struct app_state *state = data;
    state->frame_ready = 1;

    // Subsample buffer with step to compute average color across screen in microseconds
    int step_x = 32;
    int step_y = 32;
    uint64_t total_r = 0, total_g = 0, total_b = 0;
    uint64_t count = 0;

    uint8_t *pixels = (uint8_t *)state->data;
    if (!pixels) return;

    for (int y = 0; y < state->height; y += step_y) {
        uint8_t *row = pixels + (y * state->stride);
        for (int x = 0; x < state->width; x += step_x) {
            uint8_t *pixel = row + (x * 4);
            uint8_t b = pixel[0];
            uint8_t g = pixel[1];
            uint8_t r = pixel[2];
            total_r += r;
            total_g += g;
            total_b += b;
            count++;
        }
    }

    if (count > 0) {
        state->avg_r = total_r / count;
        state->avg_g = total_g / count;
        state->avg_b = total_b / count;
    }
}

static void frame_handle_failed(void *data, struct zwlr_screencopy_frame_v1 *frame) {
    (void)frame;
    struct app_state *state = data;
    state->frame_failed = 1;
}

static const struct zwlr_screencopy_frame_v1_listener frame_listener = {
    .buffer = frame_handle_buffer,
    .flags = frame_handle_flags,
    .ready = frame_handle_ready,
    .failed = frame_handle_failed,
};

static void registry_handle_global(void *data, struct wl_registry *registry,
                                  uint32_t name, const char *interface, uint32_t version) {
    (void)version;
    struct app_state *state = data;
    if (strcmp(interface, wl_shm_interface.name) == 0) {
        state->shm = wl_registry_bind(registry, name, &wl_shm_interface, 1);
    } else if (strcmp(interface, wl_output_interface.name) == 0) {
        if (!state->output) {
            state->output = wl_registry_bind(registry, name, &wl_output_interface, 1);
        }
    } else if (strcmp(interface, zwlr_screencopy_manager_v1_interface.name) == 0) {
        state->screencopy_manager = wl_registry_bind(registry, name, &zwlr_screencopy_manager_v1_interface, 1);
    }
}

static void registry_handle_global_remove(void *data, struct wl_registry *registry, uint32_t name) {
    (void)data; (void)registry; (void)name;
}

static const struct wl_registry_listener registry_listener = {
    .global = registry_handle_global,
    .global_remove = registry_handle_global_remove,
};

static void apply_color(struct app_state *state, uint8_t r, uint8_t g, uint8_t b) {
    // Dynamically acquire fast sysfs path as soon as permissions become available
    if (state->sysfs_fd < 0) {
        state->sysfs_fd = open(SYSFS_PATH, O_WRONLY);
        if (state->sysfs_fd >= 0) {
            printf("[asus-ambilight] Direct fast sysfs path acquired!\n");
            fflush(stdout);
        }
    }

    // 1. Try fastest zero-overhead path: direct kernel sysfs
    if (state->sysfs_fd >= 0) {
        char buf[64];
        int len = snprintf(buf, sizeof(buf), "0 0 %u %u %u 0\n", r, g, b);
        lseek(state->sysfs_fd, 0, SEEK_SET);
        if (write(state->sysfs_fd, buf, len) > 0) {
            return;
        }
    }

    // 2. Compatibility path: asusctl aura command
    char cmd[128];
    snprintf(cmd, sizeof(cmd), "asusctl aura effect static -c %02x%02x%02x >/dev/null 2>&1", r, g, b);
    system(cmd);
}

int main(int argc, char *argv[]) {
    (void)argc; (void)argv;
    signal(SIGINT, sig_handler);
    signal(SIGTERM, sig_handler);

    struct app_state state = {0};
    state.sysfs_fd = open(SYSFS_PATH, O_WRONLY);

    state.display = wl_display_connect(NULL);
    if (!state.display) {
        fprintf(stderr, "[asus-ambilight] Failed to connect to Wayland display\n");
        return 1;
    }

    state.registry = wl_display_get_registry(state.display);
    wl_registry_add_listener(state.registry, &registry_listener, &state);
    wl_display_roundtrip(state.display);

    if (!state.shm || !state.output || !state.screencopy_manager) {
        fprintf(stderr, "[asus-ambilight] Missing Wayland protocols\n");
        wl_display_disconnect(state.display);
        return 1;
    }

    printf("[asus-ambilight] Daemon active. Fast sysfs path: %s\n",
           state.sysfs_fd >= 0 ? "ENABLED" : "DISABLED (using asusctl fallback)");
    fflush(stdout);

    while (g_running) {
        state.frame_ready = 0;
        state.frame_failed = 0;

        struct zwlr_screencopy_frame_v1 *frame =
            zwlr_screencopy_manager_v1_capture_output(state.screencopy_manager, 0, state.output);
        zwlr_screencopy_frame_v1_add_listener(frame, &frame_listener, &state);

        while (!state.frame_ready && !state.frame_failed && g_running) {
            if (wl_display_dispatch(state.display) < 0) {
                g_running = 0;
                break;
            }
        }
        zwlr_screencopy_frame_v1_destroy(frame);

        if (state.frame_ready) {
            uint8_t final_r, final_g, final_b;
            enhance_vibrancy(state.avg_r, state.avg_g, state.avg_b,
                             &final_r, &final_g, &final_b);

            // Compute delta from last applied color
            int delta = abs((int)final_r - (int)state.last_r) +
                        abs((int)final_g - (int)state.last_g) +
                        abs((int)final_b - (int)state.last_b);

            if (!state.has_last || delta >= DELTA_THRESHOLD) {
                apply_color(&state, final_r, final_g, final_b);
                state.last_r = final_r;
                state.last_g = final_g;
                state.last_b = final_b;
                state.has_last = true;
            }
        }

        // Sleep for the target interval (300ms)
        usleep(INTERVAL_MS * 1000);
    }

    printf("\n[asus-ambilight] Shutting down cleanly...\n");
    if (state.sysfs_fd >= 0) close(state.sysfs_fd);
    if (state.data) munmap(state.data, state.size);
    if (state.buffer) wl_buffer_destroy(state.buffer);
    wl_display_disconnect(state.display);
    return 0;
}
