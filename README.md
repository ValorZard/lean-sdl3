# Lean SDL3 Bindings

## Note
This repository is still maintained, but I've moved onto other projects. 
However, someone else in the Lean community has been carrying on with their own fork of this repo: 
https://code.everydayimshuflin.com/greg/lean-sdl3
If you'd like to learn more, check out the Zulip thread here: https://leanprover.zulipchat.com/#narrow/channel/113488-general/topic/Fun.20with.20SDL3/

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

## Acknowledgements
MASSIVE thanks to Oliver Dressler (@oOo0oOo) and Mac Malone (@tydeu) for all the help they gave!

## License & Attribution

MIT
