import SDL

structure Color where
  r : UInt8
  g : UInt8
  b : UInt8
  a : UInt8 := 255

structure EngineState where
  deltaTime : Float
  lastTime : UInt32
  running : Bool
  playerX : Int32
  playerY : Int32

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

def setColor (color : Color) : IO Unit :=
  SDL.setRenderDrawColor color.r color.g color.b color.a *> pure ()

def fillRect (x y w h : Int32) : IO Unit :=
  SDL.renderFillRect x y w h *> pure ()

def renderScene (state : EngineState) : IO Unit := do
  setColor { r := 135, g := 206, b := 235 }
  let _ ← SDL.renderClear

  setColor { r := 255, g := 0, b := 0 }
  fillRect state.playerX state.playerY 100 100

  let _ ← SDL.renderTexture 500 150 64 64

  let message := "Hello, Lean SDL!"
  let _ ← SDL.renderText message 50 50 255 255 255 255
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
    SDL.renderPresent
    gameLoop engineState

partial def run : IO Unit := do
  unless (← SDL.init SDL.SDL_INIT_VIDEO) == 1 do
    IO.println "Failed to initialize SDL"
    return

  unless (← SDL.createWindow "LeanDoomed" SCREEN_WIDTH SCREEN_HEIGHT SDL.SDL_WINDOW_SHOWN) != 0 do
    IO.println "Failed to create window"
    SDL.quit
    return

  unless (← SDL.createRenderer ()) != 0 do
    IO.println "Failed to create renderer"
    SDL.quit
    return

  unless (← SDL.loadTexture "assets/wall.png") != 0 do
    IO.println "Failed to load texture, using solid colors"

  unless (← SDL.ttfInit) do
    IO.println "Failed to initialize SDL_ttf"
    SDL.quit
    return

  unless (← SDL.loadFont "assets/Inter-VariableFont.ttf" 24) do
    IO.println "Failed to load font"
    SDL.quit
    return

  let initialState : EngineState := {
    deltaTime := 0.0, lastTime := 0, running := true
    playerX := (SCREEN_WIDTH / 2), playerY := (SCREEN_HEIGHT / 2)
  }

  let engineState ← IO.mkRef initialState
  IO.println "Starting game loop..."
  gameLoop engineState
  SDL.quit

def EngineState.setRunning (state : EngineState) (running : Bool) : EngineState :=
  { state with running }

def main : IO Unit :=
  run
