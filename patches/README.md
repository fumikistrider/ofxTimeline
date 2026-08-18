# openFrameworks core patches

Two files in the openFrameworks 0.12.0 osx release have to be changed before
ofxTimeline links on a modern Mac. They live in the openFrameworks tree, not in
this addon, so they are kept here as a patch — **reinstalling or re-downloading
openFrameworks silently reverts them**, and the symptoms are confusing.

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
