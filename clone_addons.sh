#!/bin/bash

# Dependencies for ofxTimeline
#
# The addons land next to ofxTimeline in addons/, whatever directory you run
# this from. Pass any argument to clone over SSH instead of HTTPS.
#
# ofxTween and ofxAudioDecoder do NOT build against openFrameworks 0.12 on a
# modern Mac as their upstreams stand, so this clones the ported forks and
# checks out the branch that carries the fixes. See PORTING.md.

set -e

# Resolve addons/ from this script's own location. The old version did a bare
# "cd ../", so running it from anywhere but this directory cloned the addons
# into whatever happened to be the parent of the working directory.
cd "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [ -z "$1" ]; then
    HOST="https://github.com/"
else
    HOST="git@github.com:"
fi

# clone_addon <owner/repo> [branch]
clone_addon() {
    local repo="$1"
    local branch="$2"
    local name="${repo#*/}"

    if [ -d "$name" ]; then
        echo "== $name already present, skipping"
        return
    fi

    if [ -n "$branch" ]; then
        echo "== cloning $repo ($branch)"
        git clone --branch "$branch" "${HOST}${repo}.git"
    else
        echo "== cloning $repo"
        git clone "${HOST}${repo}.git"
    fi
}

# Unchanged upstreams
clone_addon YCAMInterlab/ofxTimecode
clone_addon obviousjim/ofxMSATimer
clone_addon elliotwoods/ofxTextInputField
clone_addon Flightphase/ofxRange

# Ported forks - upstream does not compile against openFrameworks 0.12
clone_addon fumikistrider/ofxTween of-0.12-arm64
clone_addon fumikistrider/ofxAudioDecoder of-0.12-arm64

echo
echo "If you're using linux, please make sure you checkout the develop branch of ofxTextInputField"
echo
echo "ofxXmlSettings ships with openFrameworks, nothing to clone."
echo "On macOS, also apply the openFrameworks core patches before building:"
echo "  git apply -p1 addons/ofxTimeline/patches/openFrameworks-0.12.0-macos-arm64.patch"
