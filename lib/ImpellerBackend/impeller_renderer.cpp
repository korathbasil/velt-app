#include "include/impeller_renderer.h"
#include "impeller.hpp"
#include <GLFW/glfw3.h>
#include <dlfcn.h>
#include <fstream>
#include <iostream>
#include <map>
#include <string_view>

#define STB_IMAGE_IMPLEMENTATION
#include "vendor/stb_image.h"

// --- Namespace Aliasing ---
namespace impeller {
using ::ImpellerColor;
using ::ImpellerISize;
using ::ImpellerMapping;
using ::ImpellerPixelFormat;
using ::ImpellerPoint;
using ::ImpellerRect;
using ::kImpellerColorSpaceSRGB;
using ::kImpellerPixelFormatRGBA8888;
} // namespace impeller

namespace impeller::hpp {
ProcTable gGlobalProcTable;
}

// --- Renderer State ---
struct RendererState {
  GLFWwindow *window = nullptr;
  void *lib_handle = nullptr;

  std::unique_ptr<impeller::hpp::Context> context;
  std::unique_ptr<impeller::hpp::Surface> surface;
  std::unique_ptr<impeller::hpp::DisplayListBuilder> builder;
  std::unique_ptr<impeller::hpp::TypographyContext> type_context;

  int width = 0;
  int height = 0;

  struct TextureData {
    std::shared_ptr<impeller::hpp::Texture> texture;
    int width;
    int height;
  };
  std::map<int, TextureData> textures;
  std::map<std::string, int> texturePathCache;
  int next_texture_id = 1;

  RendererState(int w, int h) : width(w), height(h) {}

  ~RendererState() {
    builder.reset();
    surface.reset();
    type_context.reset();
    context.reset();
    if (window)
      glfwDestroyWindow(window);
    glfwTerminate();
    if (lib_handle)
      dlclose(lib_handle);
  }
};

static std::unique_ptr<RendererState> gState;

// Scroll state
static double gScrollX = 0;
static double gScrollY = 0;

void scroll_callback(GLFWwindow *window, double xoffset, double yoffset) {
  gScrollX += xoffset;
  gScrollY += yoffset;
}

// Keyboard Input State
static std::vector<uint32_t> gCharQueue;

void char_callback(GLFWwindow *window, unsigned int codepoint) {
  gCharQueue.push_back(codepoint);
}

void key_callback(GLFWwindow *window, int key, int scancode, int action,
                  int mods) {
  if (key == GLFW_KEY_BACKSPACE &&
      (action == GLFW_PRESS || action == GLFW_REPEAT)) {
    gCharQueue.push_back(0x08); // ASCII Backspace
  }
}

void *ResolveImpellerSymbol(const char *name) {
  if (!gState || !gState->lib_handle)
    return nullptr;
  return dlsym(gState->lib_handle, name);
}

std::unique_ptr<impeller::hpp::Mapping> CreateFileMapping(const char *path) {
  std::ifstream file(path, std::ios::binary | std::ios::ate);
  if (!file)
    return nullptr;
  std::streamsize size = file.tellg();
  file.seekg(0, std::ios::beg);
  if (size <= 0)
    return nullptr;
  uint8_t *data = new uint8_t[size];
  if (!file.read((char *)data, size)) {
    delete[] data;
    return nullptr;
  }
  return std::make_unique<impeller::hpp::Mapping>(data, size,
                                                  [data]() { delete[] data; });
}

impeller::hpp::Paragraph BuildParagraph(const char *text, float fontSize,
                                        float r, float g, float b, float a,
                                        const char *fontFamily) {
  impeller::hpp::ParagraphBuilder builder(*gState->type_context);
  impeller::hpp::ParagraphStyle style;
  style.SetFontFamily(fontFamily);
  style.SetFontSize(fontSize);
  impeller::hpp::Paint paint;
  impeller::ImpellerColor c = {r, g, b, a, impeller::kImpellerColorSpaceSRGB};
  paint.SetColor(c);
  style.SetForeground(paint);
  builder.PushStyle(style);
  builder.AddText(std::string_view(text));
  builder.PopStyle();
  return builder.Build(10000.0f);
}

extern "C" {

void impeller_init(int width, int height) {
  gState = std::make_unique<RendererState>(width, height);
  if (!glfwInit())
    return;

  glfwWindowHint(GLFW_CLIENT_API, GLFW_OPENGL_ES_API);
  glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3);
  glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 0);

  gState->window = glfwCreateWindow(width, height, "Velt", NULL, NULL);
  if (!gState->window)
    return;

  glfwSetScrollCallback(gState->window, scroll_callback);
  glfwSetCharCallback(gState->window, char_callback);
  glfwSetKeyCallback(gState->window, key_callback);

  glfwMakeContextCurrent(gState->window);

  // Try multiple paths for the shared library
  gState->lib_handle =
      dlopen("./lib/ImpellerBackend/lib/libimpeller.so", RTLD_LAZY);
  if (!gState->lib_handle)
    gState->lib_handle =
        dlopen("lib/ImpellerBackend/lib/libimpeller.so", RTLD_LAZY);
  if (!gState->lib_handle)
    gState->lib_handle = dlopen("libimpeller.so", RTLD_LAZY);

  if (gState->lib_handle &&
      impeller::hpp::gGlobalProcTable.Initialize(ResolveImpellerSymbol)) {
    auto gl_resolver = [](const char *name) -> void * {
      return (void *)glfwGetProcAddress(name);
    };
    gState->context = std::make_unique<impeller::hpp::Context>(
        impeller::hpp::Context::OpenGLES(gl_resolver));

    if (gState->context && *gState->context) {
      impeller::ImpellerPixelFormat format =
          impeller::kImpellerPixelFormatRGBA8888;
      impeller::ImpellerISize fb_size = {(int64_t)width, (int64_t)height};
      gState->surface = std::make_unique<impeller::hpp::Surface>(
          impeller::hpp::Surface::WrapFBO(*gState->context, 0, format,
                                          fb_size));
      gState->builder = std::make_unique<impeller::hpp::DisplayListBuilder>();
      gState->type_context =
          std::make_unique<impeller::hpp::TypographyContext>();

      glViewport(0, 0, width, height);
    }
  }
}

// --- MISSING FUNCTIONS (FIXED) ---

void impeller_get_cursor_pos(double *x, double *y) {
  if (!gState || !gState->window) {
    *x = 0;
    *y = 0;
    return;
  }
  glfwGetCursorPos(gState->window, x, y);
}

bool impeller_is_mouse_down() {
  if (!gState || !gState->window)
    return false;
  return glfwGetMouseButton(gState->window, GLFW_MOUSE_BUTTON_LEFT) ==
         GLFW_PRESS;
}

// ---------------------------------

bool impeller_load_font(const char *filepath, const char *family_alias) {
  if (!gState || !gState->type_context)
    return false;
  auto mapping = CreateFileMapping(filepath);
  if (!mapping)
    return false;
  return gState->type_context->RegisterFont(std::move(mapping), family_alias);
}

ImpellerTextSize impeller_measure_text(const char *text, float fontSize,
                                       const char *fontFamily) {
  if (!gState || !gState->type_context)
    return {0, 0};
  auto paragraph = BuildParagraph(text, fontSize, 0, 0, 0, 1, fontFamily);
  return {paragraph.GetMinIntrinsicWidth() + 2.0f, paragraph.GetHeight()};
}

void impeller_draw_text(const char *text, float x, float y, float fontSize,
                        float r, float g, float b, float a,
                        const char *fontFamily) {
  if (!gState || !gState->builder)
    return;
  auto paragraph = BuildParagraph(text, fontSize, r, g, b, a, fontFamily);
  impeller::ImpellerPoint point = {x, y};
  gState->builder->DrawParagraph(paragraph, point);
}

bool impeller_window_should_close() {
  return gState && gState->window && glfwWindowShouldClose(gState->window);
}
void impeller_poll_events(void) { glfwPollEvents(); }

void impeller_get_window_size(int *w, int *h) {
  if (!gState || !gState->window) {
    *w = 0;
    *h = 0;
    return;
  }
  glfwGetWindowSize(gState->window, w, h);
}

void impeller_update_window_size(int w, int h) {
  if (!gState || !gState->context)
    return;
  gState->width = w;
  gState->height = h;

  // Recreate surface with new size
  impeller::ImpellerPixelFormat format = impeller::kImpellerPixelFormatRGBA8888;
  impeller::ImpellerISize fb_size = {(int64_t)w, (int64_t)h};

  gState->surface.reset();
  gState->surface = std::make_unique<impeller::hpp::Surface>(
      impeller::hpp::Surface::WrapFBO(*gState->context, 0, format, fb_size));

  glViewport(0, 0, w, h);
}

// Helper to draw shadow
void draw_shadow(const impeller::ImpellerRect &rect, float r, float g, float b,
                 float a, float blur, float offset_x, float offset_y) {
  if (!gState || !gState->builder)
    return;

  impeller::hpp::Paint shadow_paint;
  impeller::ImpellerColor shadow_color = {r, g, b, a,
                                          impeller::kImpellerColorSpaceSRGB};
  shadow_paint.SetColor(shadow_color);

  auto mask_filter =
      impeller::hpp::MaskFilter::Blur(kImpellerBlurStyleNormal, blur);
  shadow_paint.SetMaskFilter(mask_filter);

  impeller::ImpellerRect shadow_rect = {rect.x + offset_x, rect.y + offset_y,
                                        rect.width, rect.height};
  gState->builder->DrawRect(shadow_rect, shadow_paint);
}

void impeller_draw_rect(float x, float y, float w, float h, float r, float g,
                        float b, float a) {
  if (!gState || !gState->builder)
    return;
  impeller::ImpellerRect rect = {x, y, w, h};
  impeller::ImpellerColor color = {r, g, b, a,
                                   impeller::kImpellerColorSpaceSRGB};
  auto paint = impeller::hpp::Paint();
  paint.SetColor(color);
  gState->builder->DrawRect(rect, paint);
}

void impeller_draw_rounded_rect(float x, float y, float w, float h, float r,
                                float g, float b, float a, float radius) {
  if (!gState || !gState->builder)
    return;
  impeller::ImpellerRect rect = {x, y, w, h};
  impeller::ImpellerColor color = {r, g, b, a,
                                   impeller::kImpellerColorSpaceSRGB};
  auto paint = impeller::hpp::Paint();
  paint.SetColor(color);

  ImpellerRoundingRadii radii = {
      {radius, radius}, {radius, radius}, {radius, radius}, {radius, radius}};

  gState->builder->DrawRoundedRect(rect, radii, paint);
}

void impeller_draw_rect_with_shadow(float x, float y, float w, float h, float r,
                                    float g, float b, float a, float shadow_r,
                                    float shadow_g, float shadow_b,
                                    float shadow_a, float shadow_blur,
                                    float shadow_x, float shadow_y) {
  if (!gState || !gState->builder)
    return;

  impeller::ImpellerRect rect = {x, y, w, h};

  // Draw shadow first
  if (shadow_a > 0) {
    draw_shadow(rect, shadow_r, shadow_g, shadow_b, shadow_a, shadow_blur,
                shadow_x, shadow_y);
  }

  // Draw main rect
  impeller::ImpellerColor color = {r, g, b, a,
                                   impeller::kImpellerColorSpaceSRGB};
  auto paint = impeller::hpp::Paint();
  paint.SetColor(color);
  gState->builder->DrawRect(rect, paint);
}

void impeller_draw_rounded_rect_with_shadow(float x, float y, float w, float h,
                                            float r, float g, float b, float a,
                                            float radius, float shadow_r,
                                            float shadow_g, float shadow_b,
                                            float shadow_a, float shadow_blur,
                                            float shadow_x, float shadow_y) {
  if (!gState || !gState->builder)
    return;

  impeller::ImpellerRect rect = {x, y, w, h};
  ImpellerRoundingRadii radii = {
      {radius, radius}, {radius, radius}, {radius, radius}, {radius, radius}};

  // Draw shadow first
  if (shadow_a > 0) {
    // Custom draw_shadow logic for rounded rect
    // We can reuse draw_shadow logic but call DrawRoundedRect
    impeller::hpp::Paint shadow_paint;
    impeller::ImpellerColor shadow_color = {shadow_r, shadow_g, shadow_b,
                                            shadow_a,
                                            impeller::kImpellerColorSpaceSRGB};
    shadow_paint.SetColor(shadow_color);

    auto mask_filter =
        impeller::hpp::MaskFilter::Blur(kImpellerBlurStyleNormal, shadow_blur);
    shadow_paint.SetMaskFilter(mask_filter);

    impeller::ImpellerRect shadow_rect = {rect.x + shadow_x, rect.y + shadow_y,
                                          rect.width, rect.height};
    gState->builder->DrawRoundedRect(shadow_rect, radii, shadow_paint);
  }

  // Draw main rect
  impeller::ImpellerColor color = {r, g, b, a,
                                   impeller::kImpellerColorSpaceSRGB};
  auto paint = impeller::hpp::Paint();
  paint.SetColor(color);
  gState->builder->DrawRoundedRect(rect, radii, paint);
}

int impeller_load_texture(const char *filepath) {
  if (!gState || !gState->context)
    return 0;

  if (gState->texturePathCache.count(filepath)) {
    return gState->texturePathCache[filepath];
  }

  int width, height, channels;
  stbi_set_flip_vertically_on_load(0);
  unsigned char *data =
      stbi_load(filepath, &width, &height, &channels, 4); // Force RGBA
  if (!data) {
    std::cerr << "Failed to load image: " << filepath
              << " Reason: " << stbi_failure_reason() << std::endl;
    return 0;
  }

  ImpellerTextureDescriptor desc;
  desc.pixel_format = kImpellerPixelFormatRGBA8888;
  desc.size = {(int64_t)width, (int64_t)height};
  desc.mip_count = 1;

  auto mapping = std::make_unique<impeller::hpp::Mapping>(
      data, width * height * 4, [data]() { stbi_image_free(data); });

  auto texture = std::make_shared<impeller::hpp::Texture>(
      impeller::hpp::Texture::WithContents(*gState->context, desc,
                                           std::move(mapping)));

  if (!*texture) {
    std::cerr << "Failed to create texture from image: " << filepath
              << std::endl;
    return 0;
  }

  int id = gState->next_texture_id++;
  gState->textures[id] = {texture, width, height};
  gState->texturePathCache[filepath] = id;
  return id;
}

void impeller_draw_texture(int textureId, float x, float y, float w, float h) {
  if (!gState || !gState->builder)
    return;
  auto it = gState->textures.find(textureId);
  if (it == gState->textures.end())
    return;

  auto &textureData = it->second;
  if (!textureData.texture || !*textureData.texture)
    return;

  impeller::hpp::Paint paint;
  impeller::ImpellerColor color = {1.0f, 1.0f, 1.0f, 1.0f,
                                   impeller::kImpellerColorSpaceSRGB};
  paint.SetColor(color);

  impeller::ImpellerRect src_rect = {0, 0, (float)textureData.width,
                                     (float)textureData.height};
  impeller::ImpellerRect dst_rect = {x, y, w, h};

  gState->builder->DrawTextureRect(*textureData.texture, src_rect, dst_rect,
                                   kImpellerTextureSamplingLinear, paint);
}

int impeller_get_texture_width(int textureId) {
  if (!gState)
    return 0;
  auto it = gState->textures.find(textureId);
  if (it == gState->textures.end())
    return 0;
  return it->second.width;
}

int impeller_get_texture_height(int textureId) {
  if (!gState)
    return 0;
  auto it = gState->textures.find(textureId);
  if (it == gState->textures.end())
    return 0;
  return it->second.height;
}

void impeller_swap_buffers() {
  if (!gState || !gState->window || !gState->surface)
    return;
  auto display_list = gState->builder->Build();
  gState->surface->Draw(display_list);
  glfwSwapBuffers(gState->window);
  gState->builder = std::make_unique<impeller::hpp::DisplayListBuilder>();
}

void impeller_shutdown() {
  if (gState) {
    gState->textures.clear();
    gState->texturePathCache.clear();
    gState.reset();
  }
}

// --- FPS Overlay ---
static double lastFrameTime = 0.0;
static double fps = 0.0;
static double fpsUpdateTimer = 0.0;
static int frameCount = 0;

void impeller_draw_fps_overlay() {
  if (!gState || !gState->builder || !gState->type_context)
    return;

  // Calculate FPS using GLFW time
  double currentTime = glfwGetTime();
  double deltaTime = currentTime - lastFrameTime;
  lastFrameTime = currentTime;

  frameCount++;
  fpsUpdateTimer += deltaTime;

  // Update FPS every 0.5 seconds for stable display
  if (fpsUpdateTimer >= 0.5) {
    fps = frameCount / fpsUpdateTimer;
    frameCount = 0;
    fpsUpdateTimer = 0.0;
  }

  // Format FPS string
  char fpsText[32];
  snprintf(fpsText, sizeof(fpsText), "%.0f FPS", fps);

  // Measure text to position at top-right
  float fontSize = 14.0f;
  auto paragraph =
      BuildParagraph(fpsText, fontSize, 0.0f, 0.0f, 0.0f, 1.0f, "Sans");
  float textWidth = paragraph.GetMinIntrinsicWidth() + 4.0f;
  float textHeight = paragraph.GetHeight();

  // Position: top-right with 10px margin
  float x = gState->width - textWidth - 10.0f;
  float y = 10.0f;

  // Draw background pill
  float padding = 6.0f;
  float bgRadius = 8.0f;
  impeller::ImpellerRect bgRect = {
      x - padding, y - 2.0f, textWidth + padding * 2.0f, textHeight + 4.0f};
  impeller::hpp::Paint bgPaint;
  bgPaint.SetColor({0.0f, 0.0f, 0.0f, 0.6f, impeller::kImpellerColorSpaceSRGB});
  ImpellerRoundingRadii radii = {{bgRadius, bgRadius},
                                 {bgRadius, bgRadius},
                                 {bgRadius, bgRadius},
                                 {bgRadius, bgRadius}};
  gState->builder->DrawRoundedRect(bgRect, radii, bgPaint);

  // Draw FPS text (white)
  impeller::ImpellerPoint point = {x, y};
  auto textParagraph =
      BuildParagraph(fpsText, fontSize, 1.0f, 1.0f, 1.0f, 1.0f, "Sans");
  gState->builder->DrawParagraph(textParagraph, point);
}

// --- Clipping & Saving ---

void impeller_save() {
  if (!gState || !gState->builder)
    return;
  gState->builder->Save();
}

void impeller_restore() {
  if (!gState || !gState->builder)
    return;
  gState->builder->Restore();
}

void impeller_clip_rect(float x, float y, float w, float h) {
  if (!gState || !gState->builder)
    return;
  impeller::ImpellerRect rect = {x, y, w, h};
  gState->builder->ClipRect(rect, kImpellerClipOperationIntersect);
}

// --- Scroll Input ---

void impeller_get_scroll_delta(double *x, double *y) {
  *x = gScrollX;
  *y = gScrollY;
  // Reset delta after reading (polling style)
  gScrollX = 0;
  gScrollY = 0;
}

// --- Keyboard Input ---

uint32_t impeller_get_next_char() {
  if (gCharQueue.empty())
    return 0;
  uint32_t c = gCharQueue.front();
  gCharQueue.erase(gCharQueue.begin());
  return c;
}

bool impeller_is_key_down(int key) {
  if (!gState || !gState->window)
    return false;
  return glfwGetKey(gState->window, key) == GLFW_PRESS;
}

} // extern "C"