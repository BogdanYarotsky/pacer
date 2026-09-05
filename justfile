# Candle build/verify loop.
#
# Every recipe delegates to tools/*.ps1 so the logic is readable and debuggable
# outside just. All monkeyc/monkeydo flags were verified against `--help` on
# SDK 9.2.0 -- see AGENTS.md before changing any of them.

set windows-shell := ["pwsh.exe", "-NoProfile", "-Command"]

device := "vivoactive5"
typecheck := "3"

_default:
    @just --list

# Compile one device (strict typecheck by default)
build device=device typecheck=typecheck:
    pwsh -NoProfile -File tools/build.ps1 -Device {{device}} -Typecheck {{typecheck}}

# Compile every product declared in manifest.xml
all-devices typecheck=typecheck:
    pwsh -NoProfile -File tools/build.ps1 -Device all -Typecheck {{typecheck}}

# Launch the Connect IQ simulator and load the app
sim device=device typecheck=typecheck:
    pwsh -NoProfile -File tools/sim.ps1 -Device {{device}} -Typecheck {{typecheck}}

# Build with unit tests, run them in the simulator, fail on any failure
test device=device typecheck=typecheck test_name="":
    pwsh -NoProfile -File tools/test.ps1 -Device {{device}} -Typecheck {{typecheck}} -TestName "{{test_name}}"

# The unit suite on EVERY product in manifest.xml, one simulator run each. The
# suite measures the glass and fonts of the device it runs on, so a green run
# on one watch is not a verdict on another (ADR-0045).
test-all typecheck=typecheck:
    pwsh -NoProfile -File tools/test.ps1 -Device all -Typecheck {{typecheck}}

# Drive real taps/swipes/button presses into the simulator and assert which
# handler fires. Steals the mouse pointer while it runs. Kept out of `test`
# because it needs a simulator window and synthesises system-wide input.
input-test device=device:
    pwsh -NoProfile -File tests/input-behaviour.ps1 -Device {{device}}

# Bump the on-screen version, build, and push to the watch over MTP
deploy device=device:
    pwsh -NoProfile -File tools/deploy.ps1 -Device {{device}}

# Build without bumping the version, then push over MTP
deploy-nobump device=device:
    pwsh -NoProfile -File tools/deploy.ps1 -Device {{device}} -NoBump

# Run in the simulator and capture the window to shots/<device>.png
shot device=device typecheck=typecheck:
    pwsh -NoProfile -File tools/shot.ps1 -Device {{device}} -Typecheck {{typecheck}}

# Same as `shot` but leaves the simulator open. NOTE: will not return until you
# close the simulator -- a live simulator blocks the calling shell.
shot-keep device=device typecheck=typecheck:
    pwsh -NoProfile -File tools/shot.ps1 -Device {{device}} -Typecheck {{typecheck}} -KeepSim

# Capture the RELEASE build (monkeyc -r). The only way to see what a Store
# install draws: unit tests compile with -t, so (:release) code is invisible to
# them.
shot-release device=device typecheck=typecheck:
    pwsh -NoProfile -File tools/shot.ps1 -Device {{device}} -Typecheck {{typecheck}} -Release

# The RELEASE build's SETTINGS screen -> shots/<device>-settings.png. Presses the
# upper button to get there, which is the only way in (ADR-0036), so it takes
# the mouse pointer for a moment the way `just input-test` does.
shot-settings device=device typecheck=typecheck:
    pwsh -NoProfile -File tools/shot.ps1 -Device {{device}} -Typecheck {{typecheck}} -Release -Settings

# Photograph the simulator ALREADY RUNNING, exactly as it stands -> shots/<name>.png.
# Builds nothing, launches nothing, presses nothing, kills nothing.
#
# This is how to get a shot with a chosen battery level or clock: those live in
# the simulator's Simulation menu (shortcut `m`), are not persisted, and cannot
# be scripted -- and every other shot recipe relaunches the simulator, throwing
# away anything set by hand. So run `just sim`, set it up, then run this.
#
#   just capture main
#   just capture settings
capture name device=device:
    pwsh -NoProfile -File tools/shot.ps1 -Device {{device}} -CaptureOnly -Name "{{name}}"

# Finalise the version for a store release (1.3.12 -> 1.4) and stop. Builds
# nothing and touches no watch: the wrist pass comes next and cannot be
# automated, so this prints the commands rather than running them.
release:
    pwsh -NoProfile -File tools/release.ps1

# Crop the raw simulator captures in shots/ into square 500x500 listing images.
# The store stretches non-square images into square slots, which is why so many
# listings show oval watches. Run after the shot recipes, before uploading. The
# store keeps one set of screenshots per listing, so pick the device to show.
store-shots device=device:
    pwsh -NoProfile -File tools/store-shots.ps1 -Device {{device}}

# Build the signed store bundle: publish/Candle.iq (release, EVERY product in
# manifest.xml -- the store reads the device list off the bundle). REFUSES a
# three-segment dev version -- run `just release` first. The submission
# walk-through is docs/PUBLISHING.md.
package:
    pwsh -NoProfile -File tools/package.ps1

# Regenerate the candle mark at every size it is needed: the store icon, and one
# launcher icon per product in manifest.xml at the size that device declares
# (ADR-0046). Run after adding a device to the manifest.
icons:
    pwsh -NoProfile -File tools/make-icons.ps1

# Every product in manifest.xml against what the app needs from a watch: round,
# touch, Connect IQ level, a launcher icon at its own size (ADR-0047). Also runs
# at the start of `just test` and `just package`.
check-devices:
    pwsh -NoProfile -File tools/check-devices.ps1

# Re-point ./sdk-docs and ./sdk-samples at the currently active SDK
link-docs:
    pwsh -NoProfile -File tools/link-docs.ps1

# Remove build output
clean:
    pwsh -NoProfile -Command "Remove-Item -Recurse -Force bin, shots -ErrorAction SilentlyContinue; Write-Host 'cleaned'"

# ADR reference integrity: every ADR-NNNN resolves, every accepted ADR is used.
# Also runs at the start of `just test`.
check-adrs:
    pwsh -NoProfile -File tools/check-adrs.ps1
