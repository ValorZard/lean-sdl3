namespace SDL

-- All SDL errors are represented as strings, so we can just wrap them in a structure
structure SDLError where
  toString : String
  deriving Nonempty

instance : ToString SDLError := ⟨SDLError.toString⟩

abbrev SDLIO := EIO SDLError

@[inline, always_inline]
def SDLIO.toIO (x : SDLIO α) : IO α :=
  x.adapt fun e => IO.userError s!"SDL Error: {e}"

instance : MonadLift SDLIO IO := ⟨SDLIO.toIO⟩

-- see https://wiki.libsdl.org/SDL3/SDL_InitFlags
def SDL_INIT_VIDEO : UInt32 := 0x00000020
def SDL_INIT_CAMERA: UInt32 := 0x00010000
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

private opaque SDLWindow.nonemptyType : NonemptyType
def SDLWindow : Type := SDLWindow.nonemptyType.type
instance SDLWindow.instNonempty : Nonempty SDLWindow := SDLWindow.nonemptyType.property

@[extern "sdl_create_window"]
opaque createWindow : String → Int32 → Int32 → UInt32 → SDLIO SDLWindow

private opaque SDLRenderer.nonemptyType : NonemptyType
def SDLRenderer : Type := SDLRenderer.nonemptyType.type
instance SDLRenderer.instNonempty : Nonempty SDLRenderer := SDLRenderer.nonemptyType.property

@[extern "sdl_create_renderer"]
opaque createRenderer : @& SDLWindow → SDLIO SDLRenderer

@[extern "sdl_create_window_and_renderer"]
opaque createWindowAndRenderer : String -> Int32 -> Int32 -> UInt32 -> SDLIO (SDLWindow × SDLRenderer)

@[extern "sdl_set_render_draw_color"]
opaque setRenderDrawColor : @& SDLRenderer → UInt8 → UInt8 → UInt8 → UInt8 → SDLIO Int32

@[extern "sdl_render_clear"]
opaque renderClear : @& SDLRenderer → SDLIO Int32

@[extern "sdl_render_present"]
opaque renderPresent : @& SDLRenderer → IO Unit

@[extern "sdl_render_fill_rect"]
opaque renderFillRect : @& SDLRenderer → Int32 → Int32 → Int32 → Int32 → SDLIO Int32

@[extern "sdl_delay"]
opaque delay : UInt32 → IO Unit

@[extern "sdl_poll_event"]
opaque pollEvent : IO UInt32

@[extern "sdl_get_ticks"]
opaque getTicks : IO UInt64

@[extern "sdl_get_key_state"]
opaque getKeyState : UInt32 → IO Bool

-- make SDLTexture an opaque type, and make sure to tell Lean that it is nonempty
private opaque SDLTexture.nonemptyType : NonemptyType
def SDLTexture : Type := SDLTexture.nonemptyType.type
instance SDLTexture.instNonempty : Nonempty SDLTexture := SDLTexture.nonemptyType.property

private opaque SDLSurface.nonemptyType : NonemptyType
def SDLSurface : Type := SDLSurface.nonemptyType.type
instance SDLSurface.instNonempty : Nonempty SDLSurface := SDLSurface.nonemptyType.property
@[extern "sdl_image_load"]
-- @& means "by reference"
opaque loadImage :  (path : @& System.FilePath) → SDLIO SDLSurface

@[extern "sdl_create_texture_from_surface"]
opaque createTextureFromSurface
  (renderer : @& SDLRenderer) (surface : @& SDLSurface) : SDLIO SDLTexture

def loadImageTexture
  (renderer : SDLRenderer) (path : System.FilePath)
: SDLIO SDLTexture := do
  let surface <- SDL.loadImage path
  createTextureFromSurface renderer surface

private opaque SDLFont.nonemptyType : NonemptyType
def SDLFont : Type := SDLFont.nonemptyType.type
instance SDLFont.instNonempty : Nonempty SDLFont := SDLFont.nonemptyType.property

@[extern "sdl_load_font"]
opaque loadFont : System.FilePath → UInt32 → SDLIO SDLFont

@[extern "sdl_render_entire_texture"]
opaque renderEntireTexture (renderer : @& SDLRenderer) (texture : @& SDLTexture) (x : Int64) (y : Int64) (w : Int64) (h : Int64) : SDLIO Int32

@[extern "sdl_render_texture"]
opaque renderTexture (renderer : @& SDLRenderer) (texture : @& SDLTexture) (srcX : Int64) (srcY : Int64) (srcW : Int64) (srcH : Int64) (dstX : Int64) (dstY : Int64) (dstW : Int64) (dstH : Int64) : SDLIO Int32

@[extern "sdl_get_texture_width"]
opaque getTextureWidth (texture : @& SDLTexture) : SDLIO Int64

@[extern "sdl_get_texture_height"]
opaque getTextureHeight (texture : @& SDLTexture) : SDLIO Int64

@[extern "sdl_text_to_surface"]
opaque textToSurface (renderer : @& SDLRenderer) (font : @& SDLFont) (message : @& String) (x : Int32) (y : Int32) (red : UInt8) (green : UInt8) (blue : UInt8) (alpha : UInt8) : SDLIO SDLSurface

-- Mouse support
@[extern "sdl_get_mouse_state"]
opaque getMouseStateRaw : SDLIO UInt64

@[extern "sdl_set_relative_mouse_mode"]
opaque setRelativeMouseMode (window : SDLWindow) (enabled : Bool) : SDLIO UInt32

def getMousePos : SDLIO (Int32 × Int32) := do
  let packed ← getMouseStateRaw
  let x := (packed >>> 32).toUInt32.toInt32
  let y := ((packed >>> 16) &&& 0xFFFF).toUInt32.toInt32
  return (x, y)

def isMousePressed (button : UInt32) : SDLIO Bool := do
  let packed ← getMouseStateRaw
  let buttons := (packed &&& 0xFFFF).toUInt32
  return (buttons &&& button) != 0

def isLeftMousePressed : SDLIO Bool := isMousePressed SDL_BUTTON_LEFT
def isRightMousePressed : SDLIO Bool := isMousePressed SDL_BUTTON_RIGHT
def isMiddleMousePressed : SDLIO Bool := isMousePressed SDL_BUTTON_MIDDLE


-- SDL_mixer support

private opaque SDLMixer.nonemptyType : NonemptyType
def SDLMixer : Type := SDLMixer.nonemptyType.type
instance SDLMixer.instNonempty : Nonempty SDLMixer := SDLMixer.nonemptyType.property
@[extern "sdl_create_mixer"]
opaque createMixer : Unit → SDLIO SDLMixer

private opaque SDLTrack.nonemptyType : NonemptyType
def SDLTrack : Type := SDLTrack.nonemptyType.type
instance SDLTrack.instNonempty : Nonempty SDLTrack := SDLTrack.nonemptyType.property
@[extern "sdl_create_track"]
opaque createTrack : @& SDLMixer → SDLIO SDLTrack

private opaque SDLAudio.nonemptyType : NonemptyType
def SDLAudio : Type := SDLAudio.nonemptyType.type
instance SDLAudio.instNonempty : Nonempty SDLAudio := SDLAudio.nonemptyType.property
@[extern "sdl_load_audio"]
opaque loadAudio : @& SDLMixer → System.FilePath → SDLIO SDLAudio

@[extern "sdl_set_track_audio"]
opaque setTrackAudio : @& SDLTrack → @& SDLAudio → SDLIO Bool

@[extern "sdl_play_track"]
opaque playTrack : @& SDLTrack → SDLIO Bool

-- Webcam

@[extern "sdl_get_cameras"]
opaque getCameras : SDLIO (List UInt32)

end SDL
