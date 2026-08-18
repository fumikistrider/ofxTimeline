# openFrameworks core patches

Three files in the openFrameworks 0.12.0 osx release have to be changed before
ofxTimeline builds and links on a modern Mac — two for the makefile build, one
for the Xcode build. They live in the openFrameworks tree, not in this addon, so
they are kept here as a patch — **reinstalling or re-downloading openFrameworks
silently reverts them**, and the symptoms are confusing.

None of this is specific to ofxTimeline: every openFrameworks project on the
machine needs the same changes.

## Applying

From the root of your openFrameworks install (the directory containing `libs/`
and `addons/`):

```bash
git apply -p1 addons/ofxTimeline/patches/openFrameworks-0.12.0-macos-arm64.patch
```

`patch -p1 < …` works too. To check before applying:

```bash
git apply --check -p1 addons/ofxTimeline/patches/openFrameworks-0.12.0-macos-arm64.patch
```

If that check fails with "patch does not apply", the patch is most likely
already applied — confirm with `-R --check`, which succeeds when the tree is
already in the patched state.

## What each hunk does and why

### `config.osx.default.mk` — stop linking the AGL framework

AGL was deprecated in macOS 10.14 and is **gone from the macOS 26 SDK**.
openFrameworks 0.12.0 still lists it in `PLATFORM_FRAMEWORKS`, so every link
fails with:

```
ld: framework 'AGL' not found
```

Nothing in openFrameworks calls into AGL any more, so the entry is simply
commented out. This affects every openFrameworks project on this machine, not
just ofxTimeline.

### `config.addons.mk` — reset `PARSED_ADDONS_LIBS` per addon

`parse_addons_libraries` only assigns `PARSED_ADDONS_LIBS` inside
`$(if $(PARSED_ALL_PLATFORM_LIBS), …)`. An addon with no platform libraries of
its own therefore keeps whatever the *previously parsed* addon left in that
variable, and those libraries get attributed to it as well.

In stock openFrameworks the leak is invisible: the duplicates are removed again
by the `uniq` call further down. It stops being invisible as soon as an addon
deliberately clears `ADDON_LIBS` for a platform — which is exactly what
ofxTimeline's `addon_config.mk` now does on osx to keep the x86_64-only
`libsndfile.a` away from the linker. Without this hunk the archive comes back
via ofxTween and ofxXmlSettings, and the link warns:

```
ld: warning: ignoring file …/libsndfile.a: fat file missing arch 'arm64'
```

The fix clears the three accumulator variables at the top of the macro. This is
an upstream bug and worth reporting to openFrameworks.

### `CoreOF.xcconfig` — make the Xcode build match the makefile build

This one only affects Xcode; the makefiles never read it. Four settings were
stale, and the first is the serious one:

- `CLANG_CXX_LANGUAGE_STANDARD = c++11` → `c++17`. The openFrameworks 0.12 core
  itself does not compile as C++11: `ofRandomDistributions.h` uses
  `std::enable_if_t` and `std::is_same_v`, `ofRandomEngine.h` uses deduced
  return types, `ofSingleton.hpp` uses class template argument deduction. The
  makefiles have always built with `-std=c++17` (`MAC_OS_CPP_VER` in
  `config.osx.default.mk`), so the shipped xcconfig simply disagrees with the
  code next to it. Any Xcode project in this release fails with dozens of
  "no template named 'enable_if_t' in namespace 'std'" errors until this is
  changed.
- `MACOSX_DEPLOYMENT_TARGET = 10.9` → `10.15`, matching `MAC_OS_MIN_VERSION`
  in `config.osx.default.mk`.
- `-framework AGL` dropped from `OF_CORE_FRAMEWORKS`, same reason as above.
- `GCC_ENABLE_SSE3_EXTENSIONS` and `GCC_ENABLE_SUPPLEMENTAL_SSE3_INSTRUCTIONS`
  removed — x86-only codegen settings that have no meaning on Apple Silicon.
