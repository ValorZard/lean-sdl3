#include <stdint.h>
#include <SDL3/SDL.h>
#include <SDL3_image/SDL_image.h>
#include <SDL3_ttf/SDL_ttf.h>
#include <SDL3_mixer/SDL_mixer.h>
#include <lean/lean.h>

static lean_external_class * sdl_texture_external_class = NULL;

// finalizer is basically the destructor for the external object
static void sdl_texture_finalizer(void * h) {
    // destroy the texture on finalization
    SDL_DestroyTexture((SDL_Texture*)h);
}

// this is not needed for our use case, but must be defined
static void sdl_texture_foreach(void * val, lean_obj_arg fn) {

}

static lean_external_class * sdl_window_external_class = NULL;

// finalizer is basically the destructor for the external object
static void sdl_window_finalizer(void * h) {
    // destroy the window on finalization
    SDL_DestroyWindow((SDL_Window*)h);
}


static void sdl_window_foreach(void * val, lean_obj_arg fn) {

}

static lean_external_class * sdl_renderer_external_class = NULL;

// finalizer is basically the destructor for the external object
static void sdl_renderer_finalizer(void * h) {
    // destroy the renderer on finalization
    SDL_DestroyRenderer((SDL_Renderer*)h);
}


static void sdl_renderer_foreach(void * val, lean_obj_arg fn) {

}

static lean_external_class * sdl_surface_external_class = NULL;

// finalizer is basically the destructor for the external object
static void sdl_surface_finalizer(void * h) {
    // destroy the surface on finalization
    SDL_DestroySurface((SDL_Surface*)h);
}


static void sdl_surface_foreach(void * val, lean_obj_arg fn) {

}

static lean_external_class * sdl_ttf_font_external_class = NULL;

static void sdl_ttf_font_finalizer(void * h) {
    TTF_CloseFont((TTF_Font*)h);
}

static void sdl_ttf_font_foreach(void * val, lean_obj_arg fn) {

}

static lean_external_class * sdl_mixer_external_class = NULL;

static void sdl_mixer_finalizer(void * h) {
    MIX_DestroyMixer((MIX_Mixer*)h);
}

static void sdl_mixer_foreach(void * val, lean_obj_arg fn) {

}

static lean_external_class * sdl_mixer_track_external_class = NULL;

static void sdl_mixer_track_finalizer(void * h) {
    MIX_DestroyTrack((MIX_Track*)h);
}

static void sdl_mixer_track_foreach(void * val, lean_obj_arg fn) {

}

static lean_external_class * sdl_mixer_audio_external_class = NULL;

static void sdl_mixer_audio_finalizer(void * h) {
    MIX_DestroyAudio((MIX_Audio*)h);
}

static void sdl_mixer_audio_foreach(void * val, lean_obj_arg fn) {

}

lean_obj_res sdl_init(uint32_t flags, lean_obj_arg w) {
    int32_t result = SDL_Init(flags);

    // create reference to external class for SDL_Texture
    sdl_texture_external_class = lean_register_external_class(sdl_texture_finalizer, sdl_texture_foreach);
    sdl_window_external_class = lean_register_external_class(sdl_window_finalizer, sdl_window_foreach);
    sdl_renderer_external_class = lean_register_external_class(sdl_renderer_finalizer, sdl_renderer_foreach);
    sdl_surface_external_class = lean_register_external_class(sdl_surface_finalizer, sdl_surface_foreach);

    return lean_io_result_mk_ok(lean_box_uint32(result));
}

lean_obj_res sdl_ttf_init(lean_obj_arg w) {
    bool result = TTF_Init();

    sdl_ttf_font_external_class = lean_register_external_class(sdl_ttf_font_finalizer, sdl_ttf_font_foreach);

    return lean_io_result_mk_ok(lean_box_uint32(result));
}

lean_obj_res sdl_mixer_init(lean_obj_arg w) {
    bool result = MIX_Init();

    sdl_mixer_external_class = lean_register_external_class(sdl_mixer_finalizer, sdl_mixer_foreach);
    sdl_mixer_track_external_class = lean_register_external_class(sdl_mixer_track_finalizer, sdl_mixer_track_foreach);
    sdl_mixer_audio_external_class = lean_register_external_class(sdl_mixer_audio_finalizer, sdl_mixer_audio_foreach);

    return lean_io_result_mk_ok(lean_box_uint32(result));
}

lean_obj_res sdl_create_mixer(lean_obj_arg w) {
    MIX_Mixer* mixer = MIX_CreateMixerDevice(SDL_AUDIO_DEVICE_DEFAULT_PLAYBACK, NULL);
    if (mixer == NULL) {
        return lean_io_result_mk_error(lean_mk_string(SDL_GetError()));
    }
    lean_object* external_mixer = lean_alloc_external(sdl_mixer_external_class, mixer);
    return lean_io_result_mk_ok(external_mixer);
}


lean_obj_res sdl_quit(lean_obj_arg w) {
    SDL_Quit();
    return lean_io_result_mk_ok(lean_box(0));
}

lean_obj_res sdl_create_window(lean_obj_arg title, uint32_t w, uint32_t h, uint32_t flags, lean_obj_arg world) {
    const char* title_str = lean_string_cstr(title);
    SDL_Window* g_window = SDL_CreateWindow(title_str, (int)w, (int)h, flags);
    if (g_window == NULL) {
        return lean_io_result_mk_error(lean_mk_io_user_error(lean_mk_string("C: SDL_CreateWindow failed")));
    }
    lean_object* external_window = lean_alloc_external(sdl_window_external_class, g_window);
    return lean_io_result_mk_ok(external_window);
}

lean_obj_res sdl_create_renderer(lean_object * g_window, lean_obj_arg w) {
    SDL_Window* window = (SDL_Window*)lean_get_external_data(g_window);
    SDL_Renderer* g_renderer = SDL_CreateRenderer(window, NULL);
    if (g_renderer == NULL) {
        return lean_io_result_mk_error(lean_mk_string(SDL_GetError()));
    }
    lean_object* external_renderer = lean_alloc_external(sdl_renderer_external_class, g_renderer);
    return lean_io_result_mk_ok(external_renderer);
}

// lean_obj_res sdl_create_window_and_renderer(lean_obj_arg title, uint32_t w, uint32_t h, uint32_t flags, lean_obj_arg world) {
// }

lean_obj_res sdl_set_render_draw_color(lean_object * g_renderer, uint8_t r, uint8_t g, uint8_t b, uint8_t a, lean_obj_arg w) {
    SDL_Renderer* renderer = (SDL_Renderer*)lean_get_external_data(g_renderer);
    if (renderer == NULL) return lean_io_result_mk_error(lean_mk_io_user_error(lean_mk_string("C: Renderer is NULL")));
    int32_t result = SDL_SetRenderDrawColor(renderer, r, g, b, a);
    return lean_io_result_mk_ok(lean_box_uint32(result));
}

lean_obj_res sdl_render_clear(lean_object * g_renderer, lean_obj_arg w) {
    SDL_Renderer* renderer = (SDL_Renderer*)lean_get_external_data(g_renderer);
    if (renderer == NULL) return lean_io_result_mk_error(lean_mk_io_user_error(lean_mk_string("C: Renderer is NULL")));
    int32_t result = SDL_RenderClear(renderer);
    return lean_io_result_mk_ok(lean_box_uint32(result));
}

lean_obj_res sdl_render_present(lean_object * g_renderer, lean_obj_arg w) {
    SDL_Renderer* renderer = (SDL_Renderer*)lean_get_external_data(g_renderer);
    if (renderer == NULL) return lean_io_result_mk_error(lean_mk_io_user_error(lean_mk_string("C: Renderer is NULL")));
    SDL_RenderPresent(renderer);
    return lean_io_result_mk_ok(lean_box(0));
}

lean_obj_res sdl_render_fill_rect(lean_object * g_renderer, uint32_t x, uint32_t y, uint32_t w, uint32_t h, lean_obj_arg world) {
    SDL_Renderer* renderer = (SDL_Renderer*)lean_get_external_data(g_renderer);
    if (renderer == NULL) return lean_io_result_mk_error(lean_mk_io_user_error(lean_mk_string("C: Renderer is NULL")));
    SDL_FRect rect = {(float)x, (float)y, (float)w, (float)h};
    int32_t result = SDL_RenderFillRect(renderer, &rect);
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
    uint64_t ticks = SDL_GetTicks();
    return lean_io_result_mk_ok(lean_box_uint64(ticks));
}

lean_obj_res sdl_get_key_state(uint32_t scancode, lean_obj_arg w) {
    const uint8_t* state = (const uint8_t*)SDL_GetKeyboardState(NULL);
    uint8_t pressed = state[scancode];
    return lean_io_result_mk_ok(lean_box(pressed));
}

// TEXTURE SUPPORT
// Assuming 64x64 texture
lean_obj_res sdl_image_load(lean_obj_arg filename, lean_obj_arg w) {
    const char* filename_str = lean_string_cstr(filename);
    SDL_Surface* surface = IMG_Load(filename_str);
    if (!surface) {
        return lean_io_result_mk_error(lean_mk_string(SDL_GetError()));
    }
    lean_object* external_surface = lean_alloc_external(sdl_surface_external_class, surface);
    return lean_io_result_mk_ok(external_surface);
}

lean_obj_res sdl_create_texture_from_surface(lean_object * g_renderer, lean_object * g_surface, lean_obj_arg w) {
    SDL_Renderer * renderer = (SDL_Renderer *)lean_get_external_data(g_renderer);
    SDL_Surface * surface = (SDL_Surface *)lean_get_external_data(g_surface);
    if (!renderer || !surface) 
    {
        return lean_io_result_mk_error(lean_mk_io_user_error(lean_mk_string("C: Invalid renderer or surface")));
    }
    SDL_Texture * g_texture = SDL_CreateTextureFromSurface(renderer, surface);

    if (!g_texture) {
        return lean_io_result_mk_error(lean_mk_string(SDL_GetError()));
    }

    lean_object* external_texture = lean_alloc_external(sdl_texture_external_class, g_texture);

    return lean_io_result_mk_ok(external_texture);
}

lean_obj_res sdl_load_font(lean_obj_arg fontname, uint32_t font_size, lean_obj_arg w) {
    const char* fontname_str = lean_string_cstr(fontname);
    TTF_Font* font = TTF_OpenFont(fontname_str, font_size);
    if (!font) {
        return lean_io_result_mk_error(lean_mk_string(SDL_GetError()));
    }

    lean_object* external_font = lean_alloc_external(sdl_ttf_font_external_class, font);

    return lean_io_result_mk_ok(external_font);
}

lean_obj_res sdl_create_track(lean_object* g_mixer, lean_obj_arg w) {
    MIX_Mixer* mixer = (MIX_Mixer*)lean_get_external_data(g_mixer);
    MIX_Track* mixerTrack = MIX_CreateTrack(mixer);
    if (!mixerTrack) {
         return lean_io_result_mk_error(lean_mk_string(SDL_GetError()));
    }

    lean_object* external_track = lean_alloc_external(sdl_mixer_track_external_class, mixerTrack);

    return lean_io_result_mk_ok(external_track);
}


lean_obj_res sdl_load_audio(lean_object* g_mixer, lean_obj_arg filename, lean_obj_arg w) {
    MIX_Mixer* mixer = (MIX_Mixer*)lean_get_external_data(g_mixer);
    const char* filename_str = lean_string_cstr(filename);
    MIX_Audio* audio = MIX_LoadAudio(mixer, filename_str, false);
    if (!audio) {
        return lean_io_result_mk_error(lean_mk_string(SDL_GetError()));
    }

    lean_object* external_audio = lean_alloc_external(sdl_mixer_audio_external_class, audio);

    return lean_io_result_mk_ok(external_audio);
}

lean_obj_res sdl_set_track_audio(lean_object* g_track, lean_object* g_audio, lean_obj_arg w) {
    MIX_Track* track = (MIX_Track*)lean_get_external_data(g_track);
    MIX_Audio* audio = (MIX_Audio*)lean_get_external_data(g_audio);
    if (!track || !audio) {
        return lean_io_result_mk_error(lean_mk_io_user_error(lean_mk_string("C: Invalid track or audio")));
    }
    bool result = MIX_SetTrackAudio(track, audio);
    return lean_io_result_mk_ok(lean_box_uint32(result));
}

lean_obj_res sdl_play_track(lean_object* g_track, lean_obj_arg w) {
    MIX_Track* track = (MIX_Track*)lean_get_external_data(g_track);
    if (!track) {
        return lean_io_result_mk_error(lean_mk_io_user_error(lean_mk_string("C: Invalid track or audio")));
    }
    bool result = MIX_PlayTrack(track, 0);
    return lean_io_result_mk_ok(lean_box_uint32(result));
}

// TODO: VERY inefficient text rendering, re-renders entire text each time
lean_obj_res sdl_text_to_surface(lean_object* g_renderer, lean_object* g_font, lean_obj_arg text, uint32_t dst_x, uint32_t dst_y, uint8_t red, uint8_t green, uint8_t blue, uint8_t alpha, lean_obj_arg w) {
    if (!g_renderer || !g_font) return lean_io_result_mk_error(lean_mk_string("C: Renderer or Font is NULL"));
    SDL_Renderer* renderer = (SDL_Renderer*)lean_get_external_data(g_renderer);
    TTF_Font* font = (TTF_Font*)lean_get_external_data(g_font);
    const char* text_str = lean_string_cstr(text);
    size_t text_len = lean_string_len(text);
    SDL_Color color = { red, green, blue, alpha };
    SDL_Surface* text_surface = TTF_RenderText_Blended(font, text_str, text_len, color);
    if (!text_surface) {
        return lean_io_result_mk_error(lean_mk_string(SDL_GetError()));
    }

    lean_object* external_text_surface = lean_alloc_external(sdl_surface_external_class, text_surface);

    return lean_io_result_mk_ok(external_text_surface);
}


lean_obj_res sdl_get_texture_width(lean_object * g_texture, lean_obj_arg w) {
    SDL_Texture* texture = (SDL_Texture*)lean_get_external_data(g_texture);

    SDL_PropertiesID messageTexProps = SDL_GetTextureProperties(texture);

    // get number property always returns a signed 64-bit integer
    int64_t width = SDL_GetNumberProperty(messageTexProps, SDL_PROP_TEXTURE_WIDTH_NUMBER, 0);
    
    // however, there seems to be no way to return int64_t directly to Lean
    // so we box it as uint64_t instead
    // TODO: figure out a way to return int64_t directly
    return lean_io_result_mk_ok(lean_box_uint64(width));
}

lean_obj_res sdl_get_texture_height(lean_object * g_texture, lean_obj_arg w) {
    SDL_Texture* texture = (SDL_Texture*)lean_get_external_data(g_texture);

    SDL_PropertiesID messageTexProps = SDL_GetTextureProperties(texture);

    int64_t height = SDL_GetNumberProperty(messageTexProps, SDL_PROP_TEXTURE_HEIGHT_NUMBER, 0);
    return lean_io_result_mk_ok(lean_box_uint64(height));
}

lean_obj_res sdl_render_texture(lean_object* g_renderer, lean_object * g_texture, int64_t src_x, int64_t src_y, int64_t src_width, int64_t src_height, int64_t dst_x, int64_t dst_y, int64_t dst_width, int64_t dst_height, lean_obj_arg w) {
    if (!g_renderer || !g_texture) return lean_io_result_mk_ok(lean_box_uint32(-1));

    SDL_Renderer* renderer = (SDL_Renderer*)lean_get_external_data(g_renderer);
    SDL_Texture* texture = (SDL_Texture*)lean_get_external_data(g_texture);

    SDL_FRect src_rect = { (float)src_x, (float)src_y, (float)src_width, (float)src_height };

    SDL_FRect dst_rect = { (float)dst_x, (float)dst_y, (float)dst_width, (float)dst_height };

    return lean_io_result_mk_ok(lean_box_uint32(SDL_RenderTexture(renderer, texture, &src_rect, &dst_rect)));
}

lean_obj_res sdl_render_entire_texture(lean_object* g_renderer, lean_object * g_texture, int64_t dst_x, int64_t dst_y, int64_t dst_width, int64_t dst_height, lean_obj_arg w) {
    if (!g_renderer || !g_texture) return lean_io_result_mk_ok(lean_box_uint32(-1));

    SDL_Renderer* renderer = (SDL_Renderer*)lean_get_external_data(g_renderer);
    SDL_Texture* texture = (SDL_Texture*)lean_get_external_data(g_texture);

    SDL_FRect dst_rect = { (float)dst_x, (float)dst_y, (float)dst_width, (float)dst_height };

    return lean_io_result_mk_ok(lean_box_uint32(SDL_RenderTexture(renderer, texture, NULL, &dst_rect)));
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

lean_obj_res sdl_set_relative_mouse_mode(lean_object* g_window, bool enabled, lean_obj_arg w) {
    SDL_Window* window = (SDL_Window*)lean_get_external_data(g_window);
    if (window == NULL) return lean_io_result_mk_error(lean_mk_io_user_error(lean_mk_string("C: Window is NULL")));
    int32_t result = SDL_SetWindowRelativeMouseMode(window, enabled);
    mouse_cache.relative_mode = enabled;
    mouse_cache.last_frame_tick = 0; // Force refresh
    return lean_io_result_mk_ok(lean_box_uint32(result));
}
