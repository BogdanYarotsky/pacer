#!/usr/bin/env bash
#
# Bump the on-screen app version, rebuild for the vivoactive 5, and stage the
# PRG for side-loading. The version shown on the main screen is the only way to
# confirm which build is actually running on the watch, so it is bumped before
# every build unless --no-bump is passed.
#
# Usage:
#   ./publish.sh                 bump the patch version and build
#   ./publish.sh --no-bump       rebuild the current version unchanged
#   ./publish.sh --set 0.20      build as an explicit version
#
# The signing key is read from $PACER_DEVELOPER_KEY, falling back to
# ~/Music/developer_key.

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
app_file="$repo_root/source/pacerApp.mc"
output="$repo_root/bin/pacer-vivoactive5.prg"
device="vivoactive5"
developer_key="${PACER_DEVELOPER_KEY:-$HOME/Music/developer_key}"

bump="patch"
explicit_version=""

while [ $# -gt 0 ]; do
    case "$1" in
        --no-bump) bump="none"; shift ;;
        --set)
            if [ $# -lt 2 ]; then
                echo "publish.sh: --set requires a version, e.g. --set 0.20" >&2
                exit 1
            fi
            bump="explicit"; explicit_version="$2"; shift 2 ;;
        -h|--help) sed -n '2,16p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *) echo "publish.sh: unknown argument '$1'" >&2; exit 1 ;;
    esac
done

# --- locate the toolchain -----------------------------------------------------

if ! command -v java >/dev/null 2>&1; then
    echo "publish.sh: java was not found on PATH. Install a 64-bit JRE or JDK 11+." >&2
    exit 1
fi

sdk_config="$HOME/Library/Application Support/Garmin/ConnectIQ/current-sdk.cfg"
if [ ! -f "$sdk_config" ]; then
    echo "publish.sh: no active Connect IQ SDK found. Install one with Garmin SDK Manager." >&2
    echo "  expected: $sdk_config" >&2
    exit 1
fi

# Trim surrounding whitespace only. The path itself contains a space
# ("Application Support"), so stripping all whitespace would corrupt it.
sdk_root="$(sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' "$sdk_config")"
if [ ! -d "$sdk_root" ]; then
    echo "publish.sh: the SDK path in current-sdk.cfg does not exist: $sdk_root" >&2
    exit 1
fi

compiler="$sdk_root/bin/monkeyc"
if [ ! -x "$compiler" ]; then
    echo "publish.sh: monkeyc was not found below the active SDK: $sdk_root" >&2
    exit 1
fi

if [ ! -f "$developer_key" ]; then
    echo "publish.sh: developer key not found: $developer_key" >&2
    echo "  set PACER_DEVELOPER_KEY to point at your key." >&2
    exit 1
fi

# --- resolve the version ------------------------------------------------------

current_version="$(grep -oE 'APP_VERSION = "[0-9]+\.[0-9]+"' "$app_file" \
    | grep -oE '[0-9]+\.[0-9]+' || true)"

if [ -z "$current_version" ]; then
    echo "publish.sh: could not find 'const APP_VERSION = \"X.Y\";' in $app_file" >&2
    exit 1
fi

case "$bump" in
    none)     next_version="$current_version" ;;
    explicit) next_version="$explicit_version" ;;
    patch)
        major="${current_version%%.*}"
        minor="${current_version##*.}"
        # 10# forces base 10 so a leading zero (0.08) is not read as octal, and
        # the printf keeps that padding so 0.08 becomes 0.09 rather than 0.9.
        next_version="$major.$(printf "%0${#minor}d" "$((10#$minor + 1))")"
        ;;
esac

if [ "$next_version" != "$current_version" ]; then
    perl -pi -e "s/APP_VERSION = \"\Q$current_version\E\"/APP_VERSION = \"$next_version\"/" "$app_file"
    echo "version  $current_version -> $next_version"
else
    echo "version  $current_version (unchanged)"
fi

# --- build --------------------------------------------------------------------

mkdir -p "$(dirname "$output")"

"$compiler" \
    -d "$device" \
    -f "$repo_root/monkey.jungle" \
    -o "$output" \
    -y "$developer_key" \
    -w

echo "built    $output"

# --- stage for the watch ------------------------------------------------------
#
# Newer Garmin watches expose storage over MTP rather than USB mass storage, so
# the volume is often not mounted on macOS. Copy it when we can, otherwise say
# what to do by hand.

watch_apps="/Volumes/GARMIN/GARMIN/APPS"
if [ -d "$watch_apps" ]; then
    cp "$output" "$watch_apps/pacer.prg"
    echo "copied   $watch_apps/pacer.prg"
    echo "eject the watch, then launch Pacer and confirm it shows v$next_version"
else
    echo
    echo "watch not mounted at /Volumes/GARMIN."
    echo "connect it with a data-capable USB cable, then copy by hand:"
    echo "  cp \"$output\" /Volumes/GARMIN/GARMIN/APPS/pacer.prg"
    echo "after launching, confirm the main screen shows v$next_version"
fi
