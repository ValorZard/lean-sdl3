namespace SDL

def SDL_INIT_VIDEO : UInt32 := 0x00000020
def SDL_WINDOW_SHOWN : UInt32 := 0x00000004
def SDL_RENDERER_ACCELERATED : UInt32 := 0x00000002
def SDL_QUIT : UInt32 := 0x100

def SDL_SCANCODE_W : UInt32 := 26
def SDL_SCANCODE_A : UInt32 := 4
def SDL_SCANCODE_S : UInt32 := 22
def SDL_SCANCODE_D : UInt32 := 7
def SDL_SCANCODE_LEFT : UInt32 := 80
def SDL_SCANCODE_RIGHT : UInt32 := 79
def SDL_SCANCODE_SPACE : UInt32 := 44
def SDL_SCANCODE_ESCAPE : UInt32 := 41

def SDL_MOUSEBUTTONDOWN : UInt32 := 0x401
def SDL_MOUSEBUTTONUP : UInt32 := 0x402
def SDL_MOUSEMOTION : UInt32 := 0x400
def SDL_BUTTON_LEFT : UInt32 := 1
def SDL_BUTTON_MIDDLE : UInt32 := 2
def SDL_BUTTON_RIGHT : UInt32 := 4

@[extern "sdl_init"]
opaque init : UInt32 → IO UInt32

@[extern "sdl_ttf_init"]
opaque ttfInit : IO Bool

@[extern "sdl_mixer_init"]
opaque mixerInit : IO Bool

@[extern "sdl_quit"]
opaque quit : IO Unit

@[extern "sdl_create_window"]
opaque createWindow : String → Int32 → Int32 → UInt32 → IO UInt32

@[extern "sdl_create_renderer"]
opaque createRenderer : Unit → IO UInt32

@[extern "sdl_create_mixer"]
opaque createMixer : Unit → IO UInt32

@[extern "sdl_set_render_draw_color"]
opaque setRenderDrawColor : UInt8 → UInt8 → UInt8 → UInt8 → IO Int32

@[extern "sdl_render_clear"]
opaque renderClear : IO Int32

@[extern "sdl_render_present"]
opaque renderPresent : IO Unit

@[extern "sdl_render_fill_rect"]
opaque renderFillRect : Int32 → Int32 → Int32 → Int32 → IO Int32

@[extern "sdl_delay"]
opaque delay : UInt32 → IO Unit

@[extern "sdl_poll_event"]
opaque pollEvent : IO UInt32

@[extern "sdl_get_ticks"]
opaque getTicks : IO UInt32

@[extern "sdl_get_key_state"]
opaque getKeyState : UInt32 → IO Bool

private opaque SDLTexture.nonemptyType : NonemptyType

def SDLTexture : Type := SDLTexture.nonemptyType.type
instance SDLTexture.instNonempty : Nonempty SDLTexture := SDLTexture.nonemptyType.property

@[extern "sdl_load_texture"]
opaque loadTexture? : String → IO SDLTexture

@[extern "sdl_load_font"]
opaque loadFont : String → UInt32 → IO Bool

@[extern "sdl_load_track"]
opaque loadTrack : String → IO Bool

@[extern "sdl_render_texture"]
opaque renderTexture (texture : SDLTexture) (x : Int32) (y : Int32) (w : Int32) (h : Int32) : IO Int32

@[extern "sdl_render_text"]
opaque renderText (message : String) (x : Int32) (y : Int32) (red : UInt8) (green : UInt8) (blue : UInt8) (alpha : UInt8) : IO Int32

-- Mouse support
@[extern "sdl_get_mouse_state"]
opaque getMouseStateRaw : IO UInt64

@[extern "sdl_set_relative_mouse_mode"]
opaque setRelativeMouseMode (enabled : Bool) : IO UInt32

def getMousePos : IO (Int32 × Int32) := do
  let packed ← getMouseStateRaw
  let x := (packed >>> 32).toUInt32.toInt32
  let y := ((packed >>> 16) &&& 0xFFFF).toUInt32.toInt32
  return (x, y)

def isMousePressed (button : UInt32) : IO Bool := do
  let packed ← getMouseStateRaw
  let buttons := (packed &&& 0xFFFF).toUInt32
  return (buttons &&& button) != 0

def isLeftMousePressed : IO Bool := isMousePressed SDL_BUTTON_LEFT
def isRightMousePressed : IO Bool := isMousePressed SDL_BUTTON_RIGHT
def isMiddleMousePressed : IO Bool := isMousePressed SDL_BUTTON_MIDDLE

end SDL
