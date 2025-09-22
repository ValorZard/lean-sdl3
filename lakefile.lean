import Lake
open System Lake DSL

package SDL3

def sdlGitRepo : String := "https://github.com/libsdl-org/SDL.git"
def sdlImageGitRepo : String := "https://github.com/libsdl-org/SDL_image.git"

-- clone from a stable branch to avoid breakages
def sdlBranch : String := "release-3.2.x"

input_file sdl.c where
  path := "c" / "sdl.c"
  text := true

target sdl.o pkg : FilePath := do
  let srcJob ← sdl.c.fetch
  let oFile := pkg.buildDir / "c" / "sdl.o"
  let leanInclude := (<- getLeanIncludeDir).toString
  let sdlInclude := pkg.dir / "vendor" / "SDL/include/"
  let sdlImageInclude := pkg.dir / "vendor" / "SDL_image/include/"
  -- TODO: at some point, we should figure out a better way to set the C compiler
  let compiler := if Platform.isWindows then "gcc" else "cc"
  buildO oFile srcJob #[] #["-fPIC", s!"-I{sdlInclude}", s!"-I{sdlImageInclude}", "-D_REENTRANT", s!"-I{leanInclude}"] compiler

@[default_target]
target libleansdl pkg : FilePath := do
-- Helper function to run command and handle errors
-- Clone the repos if they don't exist
  let sdlRepoDir : FilePath := pkg.dir / "vendor" / "SDL"
  let sdlImageRepoDir : FilePath :=  pkg.dir / "vendor" / "SDL_image"
  let sdlExists ← System.FilePath.pathExists sdlRepoDir
  if !sdlExists then
    IO.println "Cloning SDL"
    let sdlClone ← IO.Process.output { cmd := "git", args := #["clone", "-b", sdlBranch, "--single-branch", "--depth", "1", "--recursive", sdlGitRepo, sdlRepoDir.toString] }
    if sdlClone.exitCode != 0 then
      IO.println s!"Error cloning SDL: {sdlClone.stderr}"
    else
      IO.println "SDL cloned successfully"
      IO.println sdlClone.stdout

  let sdlImageExists ← System.FilePath.pathExists sdlImageRepoDir
  if !sdlImageExists then
    IO.println "Cloning SDL_image"
    let sdlImageClone ← IO.Process.output { cmd := "git", args := #["clone", "-b", sdlBranch, "--single-branch", "--depth", "1", "--recursive", sdlImageGitRepo, sdlImageRepoDir.toString] }
    if sdlImageClone.exitCode != 0 then
      IO.println s!"Error cloning SDL_image: {sdlImageClone.stderr}"
    else
      IO.println "SDL_image cloned successfully"
      IO.println sdlImageClone.stdout

-- Build the repos with cmake
-- SDL itself needs to be built before SDL_image, as the latter depends on the former
-- We also need to make sure we are using a system provided C compiler, as the one that comes with Lean is missing important headers
  IO.println "Building SDL"
-- Create build directory if it doesn't exist
  let sdlBuildDirExists ← System.FilePath.pathExists (sdlRepoDir / "build")
  if !sdlBuildDirExists then
    let compiler := if Platform.isWindows then "gcc" else "cc"
    let configureSdlBuild ← IO.Process.output { cmd := "cmake", args := #["-S", sdlRepoDir.toString, "-B", (sdlRepoDir / "build").toString, "-DBUILD_SHARED_LIBS=ON", "-DCMAKE_BUILD_TYPE=Release", s!"-DCMAKE_C_COMPILER={compiler}"] }
    if configureSdlBuild.exitCode != 0 then
      IO.println s!"Error configuring SDL: {configureSdlBuild.stderr}"
    else
      IO.println "SDL configured successfully"
      IO.println configureSdlBuild.stdout
  else
    IO.println "SDL build directory already exists, skipping configuration step"
-- now actually build SDL once we've configured it
  let buildSdl ← IO.Process.output { cmd := "cmake", args :=  #["--build", (sdlRepoDir / "build").toString, "--config", "Release"] }
  if buildSdl.exitCode != 0 then
    IO.println s!"Error building SDL: {buildSdl.exitCode}"
    IO.println buildSdl.stderr
  else
    IO.println "SDL built successfully"
    IO.println buildSdl.stdout
-- Build SDL_Image
  IO.println "Building SDL_image"
-- Create SDL_Image build directory if it doesn't exist
  let sdlImageBuildDirExists ← System.FilePath.pathExists (sdlImageRepoDir / "build")
  if !sdlImageBuildDirExists then
    let sdlConfigPath := sdlRepoDir / "build"
    let compiler := if Platform.isWindows then "gcc" else "cc"
    let configureSdlImageBuild ← IO.Process.output { cmd := "cmake", args :=  #["-S", sdlImageRepoDir.toString, "-B", (sdlImageRepoDir / "build").toString, s!"-DSDL3_DIR={sdlConfigPath}", "-DBUILD_SHARED_LIBS=ON", "-DCMAKE_BUILD_TYPE=Release", s!"-DCMAKE_C_COMPILER={compiler}"] }
    if configureSdlImageBuild.exitCode != 0 then
      IO.println s!"Error configuring SDL_image: {configureSdlImageBuild.stderr}"
    else
      IO.println "SDL_image configured successfully"
      IO.println configureSdlImageBuild.stdout
  else
    IO.println "SDL_image build directory already exists, skipping configuration step"
-- now actually build SDL_image once we've configured it
  let buildSdlImage ← IO.Process.output { cmd := "cmake", args := #["--build", (sdlImageRepoDir / "build").toString, "--config", "Release"] }
  if buildSdlImage.exitCode != 0 then
    IO.println s!"Error building SDL_image: {buildSdlImage.stderr}"
  else
    IO.println "SDL_image built successfully"
    IO.println buildSdlImage.stdout

  let sdlO ← sdl.o.fetch
  let name := nameToStaticLib "leansdl"
  -- manually copy the DLLs we need to .lake/build/lib/ for the game to work
  IO.FS.createDirAll (pkg.dir / ".lake/build/lib/")
  let dstDir := pkg.dir / ".lake/build/lib/"
  let sdlBinariesDir : FilePath := pkg.dir / "vendor" / "SDL" / "build/"
  for entry in (← sdlBinariesDir.readDir) do
    if entry.path.extension != none then
      copyFile entry.path (dstDir / entry.path.fileName.get!)
  let sdlImageBinariesDir : FilePath := pkg.dir / "vendor" / "SDL_image" / "build/"
  for entry in (← sdlImageBinariesDir.readDir) do
    if entry.path.extension != none then
      copyFile entry.path (dstDir / entry.path.fileName.get!)
  if Platform.isWindows then
    -- binaries for Lean/Lake itself for the executable to run standalone
    let lakeBinariesDir := (← IO.appPath).parent.get!
    println! "Copying Lake DLLs from {lakeBinariesDir}"

    for entry in (← lakeBinariesDir.readDir) do
      if entry.path.extension == some "dll" then
       copyFile entry.path (pkg.dir / (".lake/build/lib/" / entry.path.fileName.get!))
  else
  -- binaries for Lean/Lake itself, like libgmp are on a different place on Linux
    let lakeBinariesDir := (← IO.appPath).parent.get!.parent.get! / "lib"
    println! "Copying Lake binaries from {lakeBinariesDir}"

    for entry in (← lakeBinariesDir.readDir) do
      if entry.path.extension != none then
       copyFile entry.path (pkg.dir / (".lake/build/lib/" / entry.path.fileName.get!))

  buildStaticLib (pkg.staticLibDir / name) #[sdlO]

target libSDL3 pkg : Dynlib := do
  return .pure {
    name := "SDL3"
    path := pkg.dir  / "vendor" / "SDL" / "build" / nameToSharedLib "SDL3"
  }

target libSDL3Image pkg : Dynlib := do
  return .pure {
    name := "SDL3_image"
    path := pkg.dir  / "vendor" / "SDL_image" / "build" / nameToSharedLib "SDL3_image"

  }

@[default_target]
lean_lib SDL where
  moreLinkObjs := #[libleansdl]
  moreLinkLibs := #[libSDL3, libSDL3Image]
