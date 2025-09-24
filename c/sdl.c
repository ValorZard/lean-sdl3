#include <stdint.h>
#include <SDL3/SDL.h>
#include <SDL3_image/SDL_image.h>
#include <SDL3_ttf/SDL_ttf.h>
#include <lean/lean.h>

static SDL_Window* g_window = NULL;
static SDL_Renderer* g_renderer = NULL;
static SDL_Texture* g_texture = NULL;
static TTF_Font* font = NULL;

lean_obj_res sdl_init(uint32_t flags, lean_obj_arg w) {
    int32_t result = SDL_Init(flags);
    return lean_io_result_mk_ok(lean_box_uint32(result));
}

lean_obj_res sdl_ttf_init(lean_obj_arg w) {
    bool result = TTF_Init();
    return lean_io_result_mk_ok(lean_box_uint32(result));
}

lean_obj_res sdl_quit(lean_obj_arg w) {
    if (g_texture) {
        SDL_DestroyTexture(g_texture);
        g_texture = NULL;
    }
    if (g_renderer) {
        SDL_DestroyRenderer(g_renderer);
        g_renderer = NULL;
    }
    if (g_window) {
        SDL_DestroyWindow(g_window);
        g_window = NULL;
    }
    SDL_Quit();
    return lean_io_result_mk_ok(lean_box(0));
}

lean_obj_res sdl_create_window(lean_obj_arg title, uint32_t w, uint32_t h, uint32_t flags, lean_obj_arg world) {
    const char* title_str = lean_string_cstr(title);
    g_window = SDL_CreateWindow(title_str, (int)w, (int)h, flags);
    if (g_window == NULL) {
        return lean_io_result_mk_ok(lean_box(0));
    }
    return lean_io_result_mk_ok(lean_box(1));
}

lean_obj_res sdl_create_renderer(lean_obj_arg w) {
    if (g_window == NULL) {
        SDL_Log("C: No window available for renderer creation\n");
        return lean_io_result_mk_ok(lean_box(0));
    }
    g_renderer = SDL_CreateRenderer(g_window, NULL);
    if (g_renderer == NULL) {
        const char* error = SDL_GetError();
        SDL_Log("C: SDL_CreateRenderer failed: %s\n", error);
        return lean_io_result_mk_ok(lean_box(0));
    }
    return lean_io_result_mk_ok(lean_box(1));
}

lean_obj_res sdl_set_render_draw_color(uint8_t r, uint8_t g, uint8_t b, uint8_t a, lean_obj_arg w) {
    if (g_renderer == NULL) return lean_io_result_mk_ok(lean_box_uint32(-1));
    int32_t result = SDL_SetRenderDrawColor(g_renderer, r, g, b, a);
    return lean_io_result_mk_ok(lean_box_uint32(result));
}

lean_obj_res sdl_render_clear(lean_obj_arg w) {
    if (g_renderer == NULL) return lean_io_result_mk_ok(lean_box_uint32(-1));
    int32_t result = SDL_RenderClear(g_renderer);
    return lean_io_result_mk_ok(lean_box_uint32(result));
}

lean_obj_res sdl_render_present(lean_obj_arg w) {
    if (g_renderer == NULL) return lean_io_result_mk_ok(lean_box(0));
    SDL_RenderPresent(g_renderer);
    return lean_io_result_mk_ok(lean_box(0));
}

lean_obj_res sdl_render_fill_rect(uint32_t x, uint32_t y, uint32_t w, uint32_t h, lean_obj_arg world) {
    if (g_renderer == NULL) return lean_io_result_mk_ok(lean_box_uint32(-1));
    SDL_FRect rect = {(float)x, (float)y, (float)w, (float)h};
    int32_t result = SDL_RenderFillRect(g_renderer, &rect);
    return lean_io_result_mk_ok(lean_box_uint32(result));
}

lean_obj_res sdl_delay(uint32_t ms, lean_obj_arg w) {
    SDL_Delay(ms);
    return lean_io_result_mk_ok(lean_box(0));
}

lean_obj_res sdl_poll_event(lean_obj_arg w) {
    SDL_Event event;
    int has_event = SDL_PollEvent(&event);
    return lean_io_result_mk_ok(lean_box_uint32(has_event ? event.type : 0));
}

lean_obj_res sdl_get_ticks(lean_obj_arg w) {
    uint32_t ticks = SDL_GetTicks();
    return lean_io_result_mk_ok(lean_box_uint32(ticks));
}

lean_obj_res sdl_get_key_state(uint32_t scancode, lean_obj_arg w) {
    const uint8_t* state = (const uint8_t*)SDL_GetKeyboardState(NULL);
    uint8_t pressed = state[scancode];
    return lean_io_result_mk_ok(lean_box(pressed));
}

// TEXTURE SUPPORT
// Assuming 64x64 texture
lean_obj_res sdl_load_texture(lean_obj_arg filename, lean_obj_arg w) {
    const char* filename_str = lean_string_cstr(filename);
    SDL_Surface* surface = IMG_Load(filename_str);
    if (!surface) {
        SDL_Log("C: Failed to load texture: %s\n", SDL_GetError());
        return lean_io_result_mk_ok(lean_box(0));
    }

    if (g_texture) SDL_DestroyTexture(g_texture);
    g_texture = SDL_CreateTextureFromSurface(g_renderer, surface);
    SDL_DestroySurface(surface);

    if (!g_texture) {
        SDL_Log("C: Failed to create texture: %s\n", SDL_GetError());
        return lean_io_result_mk_ok(lean_box(0));
    }

    return lean_io_result_mk_ok(lean_box(1));
}

lean_obj_res sdl_load_font(lean_obj_arg fontname, uint32_t font_size, lean_obj_arg w) {
    const char* fontname_str = lean_string_cstr(fontname);
    font = TTF_OpenFont(fontname_str, font_size);
    if (!font) {
        SDL_Log("C: Failed to load font: %s\n", SDL_GetError());
        return lean_io_result_mk_ok(lean_box(0));
    }

    return lean_io_result_mk_ok(lean_box(1));
}

// TODO: VERY inefficient text rendering, re-renders entire text each time
lean_obj_res sdl_render_text(lean_obj_arg text, uint32_t dst_x, uint32_t dst_y, uint8_t red, uint8_t green, uint8_t blue, uint8_t alpha, lean_obj_arg w) {
    if (!g_renderer || !font) return lean_io_result_mk_ok(lean_box_uint32(0));
    const char* text_str = lean_string_cstr(text);
    size_t text_len = lean_string_len(text);
    SDL_Color color = { red, green, blue, alpha };
    SDL_Surface* text_surface = TTF_RenderText_Blended(font, text_str, text_len, color);
    if (!text_surface) {
        SDL_Log("C: Failed to create text surface: %s\n", SDL_GetError());
        return lean_io_result_mk_ok(lean_box_uint32(0));
    }
    SDL_Texture* text_texture = SDL_CreateTextureFromSurface(g_renderer, text_surface);
    SDL_DestroySurface(text_surface);
    if (!text_texture) {
        SDL_Log("C: Failed to create text texture: %s\n", SDL_GetError());
        return lean_io_result_mk_ok(lean_box_uint32(0));
    }

    SDL_PropertiesID messageTexProps = SDL_GetTextureProperties(text_texture);

    SDL_FRect text_rect = {
            .x = (float)dst_x,
            .y = (float)dst_y,
            .w = (float)SDL_GetNumberProperty(messageTexProps, SDL_PROP_TEXTURE_WIDTH_NUMBER, 0),
            .h = (float)SDL_GetNumberProperty(messageTexProps, SDL_PROP_TEXTURE_HEIGHT_NUMBER, 0)
    };

    SDL_RenderTexture(g_renderer, text_texture, NULL, &text_rect);
    return lean_io_result_mk_ok(lean_box_uint32(1));
}


lean_obj_res sdl_render_texture(uint32_t dst_x, uint32_t dst_y, uint32_t dst_height, uint32_t dst_width, lean_obj_arg w) {
    if (!g_renderer || !g_texture) return lean_io_result_mk_ok(lean_box_uint32(-1));

    SDL_FRect dst_rect = { (float)dst_x, (float)dst_y, (float)dst_width, (float)dst_height };

    return lean_io_result_mk_ok(lean_box_uint32(SDL_RenderTexture(g_renderer, g_texture, NULL, &dst_rect)));
}

// Mouse support (caching avoids redundant SDL calls within the same frame)
static struct {
    float x, y;
    uint32_t buttons;
    bool relative_mode;
    uint32_t last_frame_tick;
} mouse_cache = {0, 0, 0, false, 0};

lean_obj_res sdl_get_mouse_state(lean_obj_arg w) {
    uint32_t current_tick = SDL_GetTicks();
    if (mouse_cache.last_frame_tick != current_tick) {
        if (mouse_cache.relative_mode) {
            mouse_cache.buttons = SDL_GetRelativeMouseState(&mouse_cache.x, &mouse_cache.y);
        } else {
            mouse_cache.buttons = SDL_GetMouseState(&mouse_cache.x, &mouse_cache.y);
        }
        mouse_cache.last_frame_tick = current_tick;
    }

    uint64_t packed = ((uint64_t)(uint32_t)(int32_t)mouse_cache.x << 32) | 
                      ((uint64_t)(uint32_t)(int32_t)mouse_cache.y << 16) |
                      (uint64_t)mouse_cache.buttons;
    return lean_io_result_mk_ok(lean_box_uint64(packed));
}

lean_obj_res sdl_set_relative_mouse_mode(bool enabled, lean_obj_arg w) {
    int32_t result = SDL_SetWindowRelativeMouseMode(g_window, enabled);
    mouse_cache.relative_mode = enabled;
    mouse_cache.last_frame_tick = 0; // Force refresh
    return lean_io_result_mk_ok(lean_box_uint32(result));
}