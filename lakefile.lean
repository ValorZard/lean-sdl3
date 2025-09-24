import Lake
open System Lake DSL

package SDL3

def sdlGitRepo : String := "https://github.com/libsdl-org/SDL.git"
def sdlImageGitRepo : String := "https://github.com/libsdl-org/SDL_image.git"
def sdlTtfGitRepo : String := "https://github.com/libsdl-org/SDL_ttf.git"
-- clone from a stable branch to avoid breakages
def sdlBranch : String := "release-3.2.x"
-- TODO: at some point, we should figure out a better way to set the C compiler
def compiler := if Platform.isWindows then "gcc" else "cc"

input_file sdl.c where
  path := "c" / "sdl.c"
  text := true

target sdlDir pkg : FilePath := do
  return .pure (pkg.dir / "vendor" / "SDL")

target sdlImageDir pkg : FilePath := do
  return .pure (pkg.dir / "vendor" / "SDL_image")

target sdlTtfDir pkg : FilePath := do
  return .pure (pkg.dir / "vendor" / "SDL_ttf")

target sdl.o pkg : FilePath := do
  let srcJob ← sdl.c.fetch
  let oFile := pkg.buildDir / "c" / "sdl.o"

  let leanInclude := (<- getLeanIncludeDir).toString

  let sdlRepoDir : FilePath ← (← sdlDir.fetch).await
  let sdlImageDir : FilePath ← (← sdlImageDir.fetch).await
  let sdlTtfDir : FilePath ← (← sdlTtfDir.fetch).await
  let sdlInclude := sdlRepoDir / "include/"
  let sdlImageInclude := sdlImageDir / "include/"
  let sdlTtfInclude := sdlTtfDir / "include/"

  buildO oFile srcJob #[] #["-fPIC", s!"-I{sdlInclude}", s!"-I{sdlImageInclude}", s!"-I{sdlTtfInclude}", "-D_REENTRANT", s!"-I{leanInclude}"] compiler

target libSDL3 : Dynlib := Job.async do
  let sdlRepoDir : FilePath ← (← sdlDir.fetch).await
  let sdlExists ← System.FilePath.pathExists sdlRepoDir
  if !sdlExists then
    logInfo "Cloning SDL"
    let sdlClone ← IO.Process.output { cmd := "git", args := #["clone", "-b", sdlBranch, "--single-branch", "--depth", "1", "--recursive", sdlGitRepo, sdlRepoDir.toString] }
    if sdlClone.exitCode != 0 then
      logError s!"Error cloning SDL: {sdlClone.stderr}"
    else
      logInfo "SDL cloned successfully"
      logInfo sdlClone.stdout
  logInfo "Building SDL"
  -- Create build directory if it doesn't exist
  let sdlBuildDirExists ← System.FilePath.pathExists (sdlRepoDir / "build")
  if !sdlBuildDirExists then
    let configureSdlBuild ← IO.Process.output { cmd := "cmake", args := #["-S", sdlRepoDir.toString, "-B", (sdlRepoDir / "build").toString, "-DBUILD_SHARED_LIBS=ON", "-DCMAKE_BUILD_TYPE=Release", s!"-DCMAKE_C_COMPILER={compiler}"] }
    if configureSdlBuild.exitCode != 0 then
      logError s!"Error configuring SDL: {configureSdlBuild.stderr}"
    else
      logInfo "SDL configured successfully"
      logInfo configureSdlBuild.stdout
  else
    logInfo "SDL build directory already exists, skipping configuration step"
  -- now actually build SDL once we've configured it
  let buildSdl ← IO.Process.output { cmd := "cmake", args :=  #["--build", (sdlRepoDir / "build").toString, "--config", "Release"] }
  if buildSdl.exitCode != 0 then
    logError s!"Error building SDL: {buildSdl.exitCode}"
    logError buildSdl.stderr
  else
    logInfo "SDL built successfully"
    logInfo buildSdl.stdout
  -- Return built dynlib
  return {
    name := "SDL3"
    path := sdlRepoDir / "build" / nameToSharedLib "SDL3"
  }

target libSDL3Image : Dynlib := Job.async do
  let sdlRepoDir : FilePath ← (<- sdlDir.fetch).await
  let sdlImageRepoDir : FilePath ← (<- sdlImageDir.fetch).await
  let sdlImageExists ← System.FilePath.pathExists sdlImageRepoDir
  if !sdlImageExists then
    logInfo "Cloning SDL_image"
    let sdlImageClone ← IO.Process.output { cmd := "git", args := #["clone", "-b", sdlBranch, "--single-branch", "--depth", "1", "--recursive", sdlImageGitRepo, sdlImageRepoDir.toString] }
    if sdlImageClone.exitCode != 0 then
      logError s!"Error cloning SDL_image: {sdlImageClone.stderr}"
    else
      logInfo "SDL_image cloned successfully"
      logInfo sdlImageClone.stdout
  logInfo "Building SDL_image"
  -- Create build directory if it doesn't exist
  let sdlImageBuildDirExists ← System.FilePath.pathExists (sdlImageRepoDir / "build")
  if !sdlImageBuildDirExists then
    let configureSdlImageBuild ← IO.Process.output { cmd := "cmake", args :=  #["-S", sdlImageRepoDir.toString, "-B", (sdlImageRepoDir / "build").toString, s!"-DSDL3_DIR={sdlRepoDir / "build"}", "-DBUILD_SHARED_LIBS=ON", "-DCMAKE_BUILD_TYPE=Release", s!"-DCMAKE_C_COMPILER={compiler}"] }
    if configureSdlImageBuild.exitCode != 0 then
      logError s!"Error configuring SDL_image: {configureSdlImageBuild.stderr}"
    else
      logInfo "SDL_image configured successfully"
      logInfo configureSdlImageBuild.stdout
  else
    logInfo "SDL_image build directory already exists, skipping configuration step"
  -- now actually build SDL_image once we've configured it
  let buildSdlImage ← IO.Process.output { cmd := "cmake", args :=  #["--build", (sdlImageRepoDir / "build").toString, "--config", "Release"] }
  if buildSdlImage.exitCode != 0 then
    logError s!"Error building SDL_image: {buildSdlImage.exitCode}"
    logError buildSdlImage.stderr
  else
    logInfo "SDL_image built successfully"
    logInfo buildSdlImage.stdout
  -- Return built dynlib
  return {
    name := "SDL3_image"
    path := sdlImageRepoDir / "build" / nameToSharedLib "SDL3_image"
  }

target libSDL3Ttf : Dynlib := Job.async do
  let sdlRepoDir : FilePath ← (<- sdlDir.fetch).await
  let sdlTtfRepoDir : FilePath ← (<- sdlTtfDir.fetch).await
  let sdlTtfExists ← System.FilePath.pathExists sdlTtfRepoDir
  if !sdlTtfExists then
    logInfo "Cloning SDL_ttf"
    let sdlTtfClone ← IO.Process.output { cmd := "git", args := #["clone", "-b", sdlBranch, "--single-branch", "--depth", "1", "--recursive", sdlTtfGitRepo, sdlTtfRepoDir.toString] }
    if sdlTtfClone.exitCode != 0 then
      logError s!"Error cloning SDL_ttf: {sdlTtfClone.stderr}"
    else
      logInfo "SDL_ttf cloned successfully"
      logInfo sdlTtfClone.stdout
  logInfo "Building SDL_ttf"
  -- Create build directory if it doesn't exist
  let sdlTtfBuildDirExists ← System.FilePath.pathExists (sdlTtfRepoDir / "build")
  if !sdlTtfBuildDirExists then
    -- tell SDL_ttf to vendor its own dependencies
    let configureSdlTtfBuild ← IO.Process.output { cmd := "cmake", args :=  #["-S", sdlTtfRepoDir.toString, "-B", (sdlTtfRepoDir / "build").toString, s!"-DSDL3_DIR={sdlRepoDir / "build"}", "-DBUILD_SHARED_LIBS=ON", "-DCMAKE_BUILD_TYPE=Release", s!"-DCMAKE_C_COMPILER={compiler}", s!"-DSDLTTF_VENDORED=true"] }
    if configureSdlTtfBuild.exitCode != 0 then
      logError s!"Error configuring SDL_ttf: {configureSdlTtfBuild.stderr}"
    else
      logInfo "SDL_ttf configured successfully"
      logInfo configureSdlTtfBuild.stdout
  else
    logInfo "SDL_ttf build directory already exists, skipping configuration step"
  -- now actually build SDL_ttf once we've configured it
  let buildSdlTtf ← IO.Process.output { cmd := "cmake", args :=  #["--build", (sdlTtfRepoDir / "build").toString, "--config", "Release"] }
  if buildSdlTtf.exitCode != 0 then
    logError s!"Error building SDL_ttf: {buildSdlTtf.exitCode}"
    logError buildSdlTtf.stderr
  else
    logInfo "SDL_ttf built successfully"
    logInfo buildSdlTtf.stdout
  -- Return built dynlib
  return {
    name := "SDL3_ttf"
    path := sdlTtfRepoDir / "build" / nameToSharedLib "SDL3_ttf"
  }

def copyBinaries (sourceDir : FilePath) : FetchM (Job Unit) := do
  -- manually copy the DLLs we need to .lake/build/bin/ in the root directory for the game to work
  let dstDir := ((<- getRootPackage).binDir)
  IO.FS.createDirAll dstDir
  let binariesDir : FilePath := sourceDir / "build"
  for entry in (← binariesDir.readDir) do
    if entry.path.extension != none then
      copyFile entry.path (dstDir / entry.path.fileName.get!)
  return pure ()

target libleansdl pkg : FilePath := do
  discard (← libSDL3.fetch).await
  discard (← libSDL3Image.fetch).await
  discard (← libSDL3Ttf.fetch).await

  -- copy binaries to the bin directory
  let sdlDirPath ← (← sdlDir.fetch).await
  let sdlImageDirPath ← (← sdlImageDir.fetch).await
  let sdlTtfDirPath ← (← sdlTtfDir.fetch).await
  discard (<- copyBinaries sdlDirPath).await
  discard (<- copyBinaries sdlImageDirPath).await
  discard (<- copyBinaries sdlTtfDirPath).await

  let sdlO ← sdl.o.fetch
  let name := nameToStaticLib "leansdl"
  buildStaticLib (pkg.staticLibDir / name) #[sdlO]

def libList : TargetArray Dynlib := #[libSDL3, libSDL3Image, libSDL3Ttf]

@[default_target]
lean_lib SDL where
  moreLinkObjs := #[libleansdl]
  moreLinkLibs := libList
  -- make sure to copy these link args into whatever project is using this library in order for it to work
  -- This is because without "-rpath=$ORIGIN", the Linux executable will not load dynlibs next to the executable (i.e., the SDL ones you've copied there).
  moreLinkArgs := if !Platform.isWindows then #["-Wl,--allow-shlib-undefined", "-Wl,-rpath=$ORIGIN"] else #[]

lean_exe «test-app» where
  root := `TestApp
  moreLinkObjs := #[libleansdl]
  moreLinkLibs := libList
  moreLinkArgs := if !Platform.isWindows then #["-Wl,--allow-shlib-undefined", "-Wl,-rpath=$ORIGIN"] else #[]
