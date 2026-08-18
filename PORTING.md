# Porting notes — openFrameworks 0.12 / macOS / Apple Silicon

ofxTimeline and every addon it depends on stopped being maintained years ago.
This branch is the work to make them build and run again on openFrameworks
0.12.0, the macOS 26 SDK, and arm64 Macs.

## Status

| | |
|---|---|
| `example-allTracks` | builds and runs (Debug and Release), audio and video tracks included |
| `example-allTracks.xcodeproj` | builds and runs (Debug and Release) |
| other examples | not tried yet — their Xcode projects still have the problems listed below |
| Linux / Windows | untouched; every change is behind a platform guard |

## Building

```bash
make -C example-allTracks Debug -j8
```

or open `example-allTracks/example-allTracks.xcodeproj` and build.

Run the binary from inside `bin/`, not from the project root — the app resolves
`data/` relative to its bundle.

## What this needs that a plain checkout does not give you

### 1. Two patches to the openFrameworks core

See [`patches/README.md`](patches/README.md). Without them the link fails with
`ld: framework 'AGL' not found`. **A reinstall of openFrameworks reverts them
silently.**

### 2. Ported dependency addons

`ofxTween` and `ofxAudioDecoder` do not build as shipped either, and both needed
changes of their own — Poco removal and CoreAudio fixes respectively. Use the
`of-0.12-arm64` branch of each. `clone_addons.sh` still points at the original
upstream repositories, which give you versions that do not compile.

`ofxTimecode`, `ofxTextInputField`, `ofxMSATimer`, `ofxRange` and
`ofxXmlSettings` needed no changes.

### 3. `TIMELINE_AUDIO_INCLUDED` / `TIMELINE_VIDEO_INCLUDED`

The audio and video tracks are wrapped in these macros. If a project does not
define them, the tracks silently vanish and nothing warns you.
`example-allTracks/config.make` sets both via `PROJECT_DEFINES`; copy that into
any project that wants those tracks.

## Behaviour changes worth knowing

**Streaming audio playback is not available on macOS/iOS.** The libsndfile
bundled with this addon is an x86_64/i386 binary that cannot link on Apple
Silicon, so Apple platforms decode through CoreAudio (via ofxAudioDecoder)
instead, which covers wav / aiff / mp3 / m4a in one path. `load(path, true)`
logs a warning and loads into memory. `ofxTLAudioTrack` never streams, so
nothing regressed — but a project calling the sound player directly should know.

Everything else is guarded by `OFX_TIMELINE_USE_SNDFILE`, so Linux and Windows
keep using libsndfile exactly as before.

## Porting another example's Xcode project

Only `example-allTracks.xcodeproj` has been done. The others need the same four
changes, all of which were made by hand in `project.pbxproj`:

1. Delete the two `libs/{openal,sndfile}/lib/osx/libsndfile.a` entries from
   `OTHER_LDFLAGS` (they are x86_64/i386 only).
2. Repoint every `addons/ofxAudioDecoder/libs/{include,src}` path at
   `addons/ofxAudioDecoder/libs/audiodecoder/{include,src}`, and drop the
   references to `libs/include/apple/` — that directory no longer exists.
3. Replace the post-build Run Script — it copies `libfmodex.dylib` and
   `GLUT.framework` from paths openFrameworks dropped years ago — with
   `"$OF_PATH/scripts/osx/xcode_project.sh"`, which is what 0.12's own project
   template runs.
4. Remove `GCC_ENABLE_SSE3_EXTENSIONS`, `GCC_ENABLE_SUPPLEMENTAL_SSE3_INSTRUCTIONS`,
   `-mtune=native` and `MACOSX_DEPLOYMENT_TARGET = 10.8`, none of which mean
   anything on Apple Silicon.

Add `TIMELINE_AUDIO_INCLUDED=1` / `TIMELINE_VIDEO_INCLUDED=1` to
`GCC_PREPROCESSOR_DEFINITIONS` too, if that example wants those tracks.

Run `plutil -lint` on the file after editing — it catches a broken pbxproj
before Xcode does.

## Known remaining work

- Only `example-allTracks` has been ported; the other nine are untried.
- The `OLD/` directory (14 MB of superseded examples) is still carried along.
- OpenAL itself is deprecated on macOS; the sound player will need an
  AVAudioEngine backend eventually.
