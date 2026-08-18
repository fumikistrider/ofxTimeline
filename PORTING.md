# Porting notes — openFrameworks 0.12 / macOS / Apple Silicon

ofxTimeline and every addon it depends on stopped being maintained years ago.
This branch is the work to make them build and run again on openFrameworks
0.12.0, the macOS 26 SDK, and arm64 Macs.

## Status

| | |
|---|---|
| `example-allTracks` | builds and runs (Debug and Release), audio and video tracks included |
| other examples | not tried yet |
| Xcode projects (`*.xcodeproj`) | **not ported** — use the makefiles |
| Linux / Windows | untouched; every change is behind a platform guard |

## Building

```bash
make -C example-allTracks Debug -j8
```

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

## Known remaining work

- The Xcode projects still reference AGL, the dead libsndfile archives, and lack
  the `TIMELINE_*` defines.
- `clone_addons.sh` clones dependency versions that do not build.
- The `OLD/` directory (14 MB of superseded examples) is still carried along.
- OpenAL itself is deprecated on macOS; the sound player will need an
  AVAudioEngine backend eventually.
