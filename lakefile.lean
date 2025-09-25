import Lake
open System Lake DSL

package SDL3

def sdlGitRepo : String := "https://github.com/libsdl-org/SDL.git"
-- pin to a specific commit to avoid breakages
def sdlGitRev : String := "f3a9f66292d49322652be01ee93412d0e9b74f0b"
def sdlImageGitRepo : String := "https://github.com/libsdl-org/SDL_image.git"
def sdlImageGitRev : String := "d354e3d5146117f8b2f14096800965e56f9f7bfc"
def sdlTtfGitRepo : String := "https://github.com/libsdl-org/SDL_ttf.git"
def sdlTtfGitRev : String := "6b6bd588e8646360b08f624fb601cc2ec75c6ada"
def sdlMixerGitRepo : String := "https://github.com/libsdl-org/SDL_mixer.git"
def sdlMixerGitRev : String := "5cdf029bae982df1d6c210f915fc151a616d982f"
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

target sdlMixerDir pkg : FilePath := do
  return .pure (pkg.dir / "vendor" / "SDL_mixer")

def cloneGitRepo (repo : String) (rev : String) (dstDir : FilePath) : FetchM (Unit) := do
  let doesExist ← dstDir.pathExists
  if !doesExist then
    logInfo s!"Cloning {repo} into {dstDir}"
    let clone ← IO.Process.output { cmd := "git", args := #["clone", "--revision", rev, "--single-branch", "--depth", "1", "--recursive", repo, dstDir.toString] }
    if clone.exitCode != 0 then
      logError s!"Error cloning {repo}: {clone.stderr}"
    else
      logInfo s!"{repo} cloned successfully"
      logInfo clone.stdout
  else
    logInfo s!"Directory {dstDir} already exists, skipping clone"
  pure ()

def copyBinaries (sourceDir : FilePath) : FetchM (Unit) := do
  -- manually copy the DLLs we need to .lake/build/bin/ in the root directory for the game to work
  let dstDir := ((<- getRootPackage).binDir)
  IO.FS.createDirAll dstDir
  logInfo s!"Copying binaries from {sourceDir} to {dstDir}"
  let binariesDir : FilePath := sourceDir / "build"
  for entry in (← binariesDir.readDir) do
    if entry.path.extension != none then
      copyFile entry.path (dstDir / entry.path.fileName.get!)
  pure ()

target sdl.o pkg : FilePath := do
  let srcJob ← sdl.c.fetch
  let oFile := pkg.buildDir / "c" / "sdl.o"

  let leanInclude := (<- getLeanIncludeDir).toString

  let sdlRepoDir : FilePath ← (← sdlDir.fetch).await
  let sdlImageDir : FilePath ← (← sdlImageDir.fetch).await
  let sdlTtfDir : FilePath ← (← sdlTtfDir.fetch).await
  let sdlMixerDir : FilePath ← (← sdlMixerDir.fetch).await

  let sdlInclude := sdlRepoDir / "include/"
  let sdlImageInclude := sdlImageDir / "include/"
  let sdlTtfInclude := sdlTtfDir / "include/"
  let sdlMixerInclude := sdlMixerDir / "include/"

  buildO oFile srcJob #[] #["-fPIC", s!"-I{sdlInclude}", s!"-I{sdlImageInclude}", s!"-I{sdlTtfInclude}", s!"-I{sdlMixerInclude}", "-D_REENTRANT", s!"-I{leanInclude}"] compiler

def buildSDL3 : FetchM (Unit) := do
  let sdlRepoDir : FilePath ← (← sdlDir.fetch).await
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
  logInfo "SDL built successfully, copying binaries"
  pure ()

target libSDL3 : Dynlib := Job.async do
  let sdlRepoDir : FilePath ← (← sdlDir.fetch).await
  return {
    name := "SDL3"
    path := sdlRepoDir / "build" / nameToSharedLib "SDL3"
  }

def buildSDL3Image : FetchM (Unit) := do
  let sdlRepoDir : FilePath ← (<- sdlDir.fetch).await
  let sdlImageRepoDir : FilePath ← (<- sdlImageDir.fetch).await
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
  logInfo "SDL_image built successfully"

target libSDL3Image : Dynlib := Job.async do
  let sdlImageRepoDir : FilePath ← (← sdlImageDir.fetch).await
  return {
    name := "SDL3_image"
    path := sdlImageRepoDir / "build" / nameToSharedLib "SDL3_image"
  }

def buildSDL3Ttf : FetchM (Unit) := do
  let sdlRepoDir : FilePath ← (<- sdlDir.fetch).await
  let sdlTtfRepoDir : FilePath ← (<- sdlTtfDir.fetch).await
  logInfo "Building SDL_ttf"
  -- Create build directory if it doesn't exist
  let sdlTtfBuildDirExists ← System.FilePath.pathExists (sdlTtfRepoDir / "build")
  if !sdlTtfBuildDirExists then
    -- tell SDL_ttf to vendor its own dependencies
    let configureSdlTtfBuild ← IO.Process.output {
        cmd := "cmake",
        args :=  #[
          "-S",
          sdlTtfRepoDir.toString,
          "-B",
          (sdlTtfRepoDir / "build").toString,
          s!"-DSDL3_DIR={sdlRepoDir / "build"}",
          "-DBUILD_SHARED_LIBS=ON",
          "-DCMAKE_BUILD_TYPE=Release",
          s!"-DCMAKE_C_COMPILER={compiler}",
          s!"-DSDLTTF_VENDORED=true"
        ]
      }
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
  logInfo "SDL_ttf built successfully"

target libSDL3Ttf : Dynlib := Job.async do
  let sdlTtfRepoDir : FilePath ← (← sdlTtfDir.fetch).await
  return {
    name := "SDL3_ttf"
    path := sdlTtfRepoDir / "build" / nameToSharedLib "SDL3_ttf"
  }

def buildSDL3Mixer : FetchM (Unit) := do
  let sdlRepoDir : FilePath ← (← sdlDir.fetch).await
  let sdlMixerRepoDir : FilePath ← (← sdlMixerDir.fetch).await

  logInfo "Building SDL_mixer"

  let sdlMixerBuildDir := sdlMixerRepoDir / "build"
  let sdlMixerBuildDirExists ← sdlMixerBuildDir.pathExists

  if !sdlMixerBuildDirExists then
    let configureSdlMixerBuild ← IO.Process.output {
      cmd := "cmake",
      args := #[
        "-S", sdlMixerRepoDir.toString,
        "-B", sdlMixerBuildDir.toString,
        s!"-DSDL3_DIR={sdlRepoDir / "build"}",
        "-DBUILD_SHARED_LIBS=ON",
        "-DCMAKE_BUILD_TYPE=Release",
        s!"-DCMAKE_C_COMPILER={compiler}",
        s!"-DCMAKE_PREFIX_PATH={sdlRepoDir / "build"}",
        s!"-DSDLTTF_VENDORED=true"
      ]
    }

    if configureSdlMixerBuild.exitCode != 0 then
      logError s!"Error configuring SDL_mixer: {configureSdlMixerBuild.stderr}"
    logInfo "SDL_mixer configured successfully"
  else
    logInfo "SDL_mixer build directory already exists, skipping configuration step"

  let buildSdlMixer ← IO.Process.output { cmd := "cmake", args := #["--build", sdlMixerBuildDir.toString, "--config", "Release"] }
  if buildSdlMixer.exitCode != 0 then
    logError s!"Error building SDL_mixer: {buildSdlMixer.exitCode}"
    logError s!"SDL_mixer build stderr: {buildSdlMixer.stderr}"

  logInfo "SDL_mixer built successfully"

target libSDL3Mixer : Dynlib := Job.async do
  let sdlMixerRepoDir : FilePath ← (← sdlMixerDir.fetch).await
  return {
    name := "SDL3_mixer"
    path := sdlMixerRepoDir / "build" / nameToSharedLib "SDL3_mixer"
  }

target libleansdl pkg : FilePath := do
  -- clone the git repositories we need so we can build them later
  let sdlRepoDir ← (← sdlDir.fetch).await
  let sdlImageRepoDir ← (← sdlImageDir.fetch).await
  let sdlTtfRepoDir ← (← sdlTtfDir.fetch).await
  let sdlMixerRepoDir ← (← sdlMixerDir.fetch).await

  cloneGitRepo sdlGitRepo sdlGitRev sdlRepoDir
  cloneGitRepo sdlImageGitRepo sdlImageGitRev sdlImageRepoDir
  cloneGitRepo sdlTtfGitRepo sdlTtfGitRev sdlTtfRepoDir
  cloneGitRepo sdlMixerGitRepo sdlMixerGitRev sdlMixerRepoDir

  -- build all the libraries we need
  buildSDL3
  buildSDL3Image
  buildSDL3Ttf
  buildSDL3Mixer

  logInfo "All libraries built successfully"

  copyBinaries sdlRepoDir
  copyBinaries sdlImageRepoDir
  copyBinaries sdlTtfRepoDir
  copyBinaries sdlMixerRepoDir

  let sdlO ← sdl.o.fetch
  let name := nameToStaticLib "leansdl"
  buildStaticLib (pkg.staticLibDir / name) #[sdlO]

def libList : TargetArray Dynlib := #[libSDL3, libSDL3Image, libSDL3Ttf, libSDL3Mixer]

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
