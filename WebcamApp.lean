import SDL

structure Color where
  r : UInt8
  g : UInt8
  b : UInt8
  a : UInt8 := 255

structure EngineState where
  window : SDL.SDLWindow
  renderer : SDL.SDLRenderer
  deltaTime : Float
  lastTime : UInt64
  running : Bool
  playerX : Int32
  playerY : Int32
  texture : SDL.SDLTexture
  font : SDL.SDLFont
  mixer : SDL.SDLMixer
  track : SDL.SDLTrack
  audio : SDL.SDLAudio

def SCREEN_WIDTH : Int32 := 1280
def SCREEN_HEIGHT : Int32 := 720
def TEXTURE_SIZE : Float := 64.0

inductive Key where
  | W | A | S | D | Left | Right | Space | Escape

def keyToScancode : Key → UInt32
  | .W => SDL.SDL_SCANCODE_W | .A => SDL.SDL_SCANCODE_A | .S => SDL.SDL_SCANCODE_S
  | .D => SDL.SDL_SCANCODE_D | .Left => SDL.SDL_SCANCODE_LEFT | .Right => SDL.SDL_SCANCODE_RIGHT
  | .Space => SDL.SDL_SCANCODE_SPACE | .Escape => SDL.SDL_SCANCODE_ESCAPE

def isKeyDown (key : Key) : IO Bool := SDL.getKeyState (keyToScancode key)

def setColor (renderer : SDL.SDLRenderer) (color : Color) : IO Unit :=
  SDL.setRenderDrawColor renderer color.r color.g color.b color.a *> pure ()

def fillRect (renderer : SDL.SDLRenderer) (x y w h : Int32) : IO Unit :=
  SDL.renderFillRect renderer { x, y, w, h } *> pure ()

def renderScene (state : EngineState) : IO Unit := do
  setColor state.renderer { r := 0, g := 0, b := 235 }
  let _ ← SDL.renderClear state.renderer

  setColor state.renderer { r := 255, g := 0, b := 0 }
  fillRect state.renderer state.playerX state.playerY 100 100

  let _ ← SDL.renderEntireTexture state.renderer state.texture 500 150 64 64

  let _ ← SDL.renderTexture state.renderer state.texture 0 0 10 30 100 150 64 100

  let message := "Hello, Lean SDL!"
  let textSurface ← SDL.textToSurface state.renderer state.font message 50 50 255 255 255 255
  let textTexture ← SDL.createTextureFromSurface state.renderer textSurface
  let textWidth ← SDL.getTextureWidth textTexture
  let textHeight ← SDL.getTextureHeight textTexture
  let _ ← SDL.renderEntireTexture state.renderer textTexture 50 50 textWidth textHeight
  pure ()

private def updateEngineState (engineState : IO.Ref EngineState) : IO Unit := do
  let state ← engineState.get
  let currentTime ← SDL.getTicks
  let deltaTime := (currentTime - state.lastTime).toFloat / 1000.0

  let mut playerX := state.playerX
  let mut playerY := state.playerY
  if ← isKeyDown .A then playerX := playerX - 1
  if ← isKeyDown .D then playerX := playerX + 1
  if ← isKeyDown .W then playerY := playerY - 1
  if ← isKeyDown .S then playerY := playerY + 1
  engineState.set { state with deltaTime, lastTime := currentTime, playerX, playerY }


partial def webcamLoop
  (renderer: SDL.SDLRenderer)
  (camera: SDL.SDLCamera)
  (textureRef: IO.Ref $ Option SDL.SDLTexture): IO Unit := do

    let texture <- textureRef.get
    let cameraFrame <- SDL.acquireCameraFrame camera
    let w := cameraFrame.w.toUInt32
    let h := cameraFrame.h.toUInt32

    match texture with
    | none => 
      let cameraTexture <- SDL.createTexture renderer cameraFrame.format SDL.SDL_TEXTUREACCESS_STREAMING w h
    | some tx =>
      -- TODO update texture


    let () <- SDL.releaseCameraFrame camera cameraFrame

partial def webcamSetup
  (renderer: SDL.SDLRenderer)
  (camera: SDL.SDLCamera): IO Unit := do
  let textureRef: IO.Ref (Option SDL.SDLTexture) <- IO.mkRef none

  webcamLoop renderer camera textureRef

partial def gameLoop (engineState : IO.Ref EngineState) : IO Unit := do
  updateEngineState engineState

  let eventType ← SDL.pollEvent
  if eventType == SDL.SDL_QUIT || (← isKeyDown .Escape) then
    engineState.modify (fun s => { s with running := false })

  if eventType == SDL.SDL_MOUSEBUTTONDOWN then
    let (mouseX, mouseY) ← SDL.getMousePos
    if ← SDL.isLeftMousePressed then
      IO.println s!"Left click at ({mouseX}, {mouseY})"
    if ← SDL.isRightMousePressed then
      IO.println s!"Right click at ({mouseX}, {mouseY})"
    if ← SDL.isMiddleMousePressed then
      IO.println s!"Middle click at ({mouseX}, {mouseY})"

  let state ← engineState.get
  if state.running then
    renderScene state
    SDL.renderPresent state.renderer
    gameLoop engineState

partial def run : IO Unit := do
  unless (← SDL.init (SDL.SDL_INIT_VIDEO ||| SDL.SDL_INIT_CAMERA)) == 1 do
    IO.println "Failed to initialize SDL"
    return

  let (window, renderer) ← try
    SDL.createWindowAndRenderer "WebcamTest" SCREEN_WIDTH SCREEN_HEIGHT SDL.SDL_WINDOW_SHOWN
  catch sdlError =>
    IO.println sdlError
    SDL.quit
    return

  let texture ← try
    SDL.loadImageTexture renderer "assets/wall.png"
  catch sdlError =>
    IO.println sdlError
    SDL.quit
    return

  unless (← SDL.ttfInit) do
    IO.println "Failed to initialize SDL_ttf"
    SDL.quit
    return

  let font ← try
    SDL.loadFont "assets/Inter-VariableFont.ttf" 24
  catch sdlError =>
    IO.println sdlError
    SDL.quit
    return

  unless (← SDL.mixerInit) do
    IO.println "Failed to initialize SDL_mixer"
    SDL.quit
    return

  let mixer ← try
    SDL.createMixer ()
  catch sdlError =>
    IO.println sdlError
    SDL.quit
    return

  let track ← try
    SDL.createTrack mixer
  catch sdlError =>
    IO.println sdlError
    SDL.quit
    return

  let audio ← try
    SDL.loadAudio mixer "assets/In_The_Dark_Flashes.mp3"
  catch sdlError =>
    IO.println sdlError
    SDL.quit
    return

  match (← SDL.setTrackAudio track audio) with
  | true => pure ()
  | false =>
    IO.println s!"Failed to set track audio"
    SDL.quit
    return

  /- match (← SDL.playTrack track) with -/
  /- | true => pure () -/
  /- | false => -/
  /-   IO.println s!"Failed to play track" -/
  /-   SDL.quit -/
  /-   return -/

  let cameraCount <- SDL.getCameras
  IO.println s!"Camera count: {cameraCount}"

  let idx := cameraCount[0]!
  let camera <- SDL.openCamera idx

  let spec <- SDL.getCameraFormat camera

  let msg :=
    let width := spec.width
    let height := spec.height
    let n := spec.framerateNumerator
    let d := spec.framerateDenominator
    s!"Framerate: {n}/{d} FPS width: {width}, height: {height}"
  IO.println msg

  let initialState : EngineState := {
    window := window, renderer := renderer
    deltaTime := 0.0, lastTime := 0, running := true
    playerX := (SCREEN_WIDTH / 2), playerY := (SCREEN_HEIGHT / 2)
    texture := texture, mixer := mixer, track := track, audio := audio, font := font
  }

  let engineState ← IO.mkRef initialState
  IO.println "Starting game loop..."
  gameLoop engineState
  SDL.quit

def EngineState.setRunning (state : EngineState) (running : Bool) : EngineState :=
  { state with running }

def main : IO Unit :=
  run
