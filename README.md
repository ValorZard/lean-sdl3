# Lean SDL3 Bindings

How to use:
Add this library as a dependency in your lakefile.lean (Not .toml)

In your default target in your project, make sure you do something like this

```lean
@[default_target]
lean_exe «lean-sdl-test» where
  root := `Main
  -- this is necessary because on Linux, binaries don't automatically get picked up by the executable unless you set the rpath
  -- also, moreLinkArgs doesn't get inherited by the parent project
  moreLinkArgs := if !System.Platform.isWindows then #["-Wl,--allow-shlib-undefined", "-Wl,-rpath=$ORIGIN"] else #[]
```

If you want to see an example project that uses these bindings, check this out:

https://github.com/ValorZard/lean-sdl-test

## License & Attribution

MIT