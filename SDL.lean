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


-- see SDL_Render.h, SDL_TextureAccess
def SDL_TEXTUREACCESS_STATIC : UInt32 := 0x0
def SDL_TEXTUREACCESS_STREAMING : UInt32 := 0x1
def SDL_TEXTUREACCESS_TARGET :UInt32 := 0x2


def SDL_ALPHA_OPAQUE_FLOAT: Float := 1.0

structure SDLRect where
  x : Int32
  y : Int32
  w : Int32
  h : Int32
  deriving Repr

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

@[extern "sdl_set_render_draw_color_float"]
opaque setRenderDrawColorFloat : @& SDLRenderer → Float → Float → Float → Float → SDLIO Bool

@[extern "sdl_render_clear"]
opaque renderClear : @& SDLRenderer → SDLIO Int32

@[extern "sdl_render_present"]
opaque renderPresent : @& SDLRenderer → IO Unit

@[extern "sdl_render_fill_rect"]
opaque renderFillRect : @& SDLRenderer → @& SDLRect → SDLIO Int32

@[extern "sdl_delay"]
opaque delay : UInt32 → IO Unit

@[extern "sdl_poll_event"]
opaque pollEvent : IO UInt32

@[extern "sdl_get_ticks"]
opaque getTicks : IO UInt64

@[extern "sdl_get_key_state"]
opaque getKeyState : UInt32 → IO Bool

private opaque PixelFormat.nonemptyType : NonemptyType
def PixelFormat : Type := PixelFormat.nonemptyType.type
instance PixelFormat.instNonempty : Nonempty PixelFormat := PixelFormat.nonemptyType.property

-- make SDLTexture an opaque type, and make sure to tell Lean that it is nonempty
private opaque SDLTexture.nonemptyType : NonemptyType
def SDLTexture : Type := SDLTexture.nonemptyType.type
instance SDLTexture.instNonempty : Nonempty SDLTexture := SDLTexture.nonemptyType.property

private opaque SDLSurface.nonemptyType : NonemptyType
def SDLSurface : Type := SDLSurface.nonemptyType.type
instance SDLSurface.instNonempty : Nonempty SDLSurface := SDLSurface.nonemptyType.property

namespace SDLSurface

private opaque Pixels.nonemptyType : NonemptyType
def Pixels: Type := Pixels.nonemptyType.type
instance PIxels.instNonempty : Nonempty Pixels := Pixels.nonemptyType.property

@[extern "sdl_Surface_get_format"]
opaque format : @& SDLSurface -> UInt32

@[extern "sdl_Surface_get_w"]
opaque w : @& SDLSurface -> Int32

@[extern "sdl_Surface_get_h"]
opaque h : @& SDLSurface -> Int32

@[extern "sdl_Surface_get_pixels"]
opaque pixels : @& SDLSurface -> Pixels

@[extern "sdl_Surface_get_pitch"]
opaque pitch : @& SDLSurface -> Int32

end SDLSurface

@[extern "sdl_image_load"]
-- @& means "by reference"
opaque loadImage :  (path : @& System.FilePath) → SDLIO SDLSurface

@[extern "sdl_create_texture"]
opaque createTexture (renderer: @& SDLRenderer) (pixelFormat: UInt32) (textureAccess: UInt32) (w: UInt32) (h: UInt32): SDLIO SDLTexture

@[extern "sdl_create_texture_from_surface"]
opaque createTextureFromSurface
  (renderer : @& SDLRenderer) (surface : @& SDLSurface) : SDLIO SDLTexture


-- TODO handle SDLRect argument
@[extern "sdl_update_texture"]
opaque updateTexture (texture: @& SDLTexture) (pixels: @& SDLSurface.Pixels) (pitch: Int32): SDLIO Bool


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

-- TODO renderTexture should work in terms of rects, replace this with renderTextureRect
@[extern "sdl_render_texture"]
opaque renderTexture (renderer : @& SDLRenderer) (texture : @& SDLTexture) (srcX : Int64) (srcY : Int64) (srcW : Int64) (srcH : Int64) (dstX : Int64) (dstY : Int64) (dstW : Int64) (dstH : Int64) : SDLIO Int32

@[extern "sdl_render_texture_rect"]
opaque renderTextureRect (renderer : @& SDLRenderer) (texture : @& SDLTexture) (sourceRect : SDLRect) (destRect : SDLRect): SDLIO Bool

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

private opaque SDLCamera.nonemptyType : NonemptyType
def SDLCamera : Type := SDLCamera.nonemptyType.type
instance SDLCamera.instNonempty : Nonempty SDLCamera := SDLCamera.nonemptyType.property
@[extern "sdl_open_camera"]
opaque openCamera : UInt32 -> SDLIO SDLCamera

-- cameraspec stuff

private opaque Colorspace.nonemptyType : NonemptyType
def Colorspace : Type := Colorspace.nonemptyType.type
instance Colorspace.instNonempty : Nonempty Colorspace := Colorspace.nonemptyType.property

opaque CameraSpec.nonemptyType : NonemptyType
def CameraSpec : Type := CameraSpec.nonemptyType.type
instance CameraSpec.instNonempty : Nonempty CameraSpec := CameraSpec.nonemptyType.property

namespace CameraSpec

@[extern "sdl_CameraSpec_get_width"]
opaque width : @& CameraSpec -> UInt32

@[extern "sdl_CameraSpec_get_height"]
opaque height : @& CameraSpec -> UInt32

@[extern "sdl_CameraSpec_get_framerate_numerator"]
opaque framerateNumerator : @& CameraSpec -> UInt32

@[extern "sdl_CameraSpec_get_framerate_denominator"]
opaque framerateDenominator : @& CameraSpec -> UInt32

end CameraSpec


@[extern "sdl_get_camera_format"]
opaque getCameraFormat : @& SDLCamera -> SDLIO CameraSpec

@[extern "sdl_acquire_camera_frame"]
opaque acquireCameraFrame :  (camera : @& SDLCamera) → SDLIO SDLSurface
-- TODO: support returning the timestampNS too
/- @[extern "sdl_acquire_camera_frame"] -/
/- opaque acquireCameraFrame :  (camera : @& SDLCamera) → SDLIO (SDLSurface × UInt64) -/

@[extern "sdl_release_camera_frame"]
opaque releaseCameraFrame (camera : @& SDLCamera) (frame: SDLSurface): IO Unit

end SDL
