#ifndef IMPELLER_RENDERER_H
#define IMPELLER_RENDERER_H

#include <stdbool.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

// Lifecycle
void impeller_init(int width, int height);
bool impeller_window_should_close(void);
void impeller_poll_events(void);
void impeller_swap_buffers(void);
void impeller_shutdown(void);
void impeller_get_window_size(int *w, int *h);
void impeller_update_window_size(int w, int h);

// Input
void impeller_get_cursor_pos(double *x, double *y);
bool impeller_is_mouse_down(void);

// Font
bool impeller_load_font(const char *filepath, const char *family_alias);

// Images
int impeller_load_texture(const char *filepath);
void impeller_draw_texture(int textureId, float x, float y, float w, float h);
int impeller_get_texture_width(int textureId);
int impeller_get_texture_height(int textureId);

// Rendering
void impeller_draw_rect(float x, float y, float w, float h, float r, float g,
                        float b, float a);

void impeller_draw_rounded_rect(float x, float y, float w, float h, float r,
                                float g, float b, float a, float radius);

void impeller_draw_rect_with_shadow(float x, float y, float w, float h, float r,
                                    float g, float b, float a, float shadow_r,
                                    float shadow_g, float shadow_b,
                                    float shadow_a, float shadow_blur,
                                    float shadow_x, float shadow_y);

void impeller_draw_rounded_rect_with_shadow(float x, float y, float w, float h,
                                            float r, float g, float b, float a,
                                            float radius, float shadow_r,
                                            float shadow_g, float shadow_b,
                                            float shadow_a, float shadow_blur,
                                            float shadow_x, float shadow_y);

typedef struct {
  float width;
  float height;
} ImpellerTextSize;
ImpellerTextSize impeller_measure_text(const char *text, float fontSize,
                                       const char *fontFamily);
void impeller_draw_text(const char *text, float x, float y, float fontSize,
                        float r, float g, float b, float a,
                        const char *fontFamily);

// Clipping
void impeller_save(void);
void impeller_restore(void);
void impeller_clip_rect(float x, float y, float w, float h);

// Input - Scroll
void impeller_get_scroll_delta(double *x, double *y);

// Keyboard Input
uint32_t impeller_get_next_char(void);
bool impeller_is_key_down(int key);

// FPS Overlay (renders FPS counter at top-right)
void impeller_draw_fps_overlay(void);

#ifdef __cplusplus
}
#endif

#endif