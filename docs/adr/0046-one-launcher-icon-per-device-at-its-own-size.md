---
id: 0046
title: One launcher icon per device, at the size its own config declares
status: accepted
---

## Context

Each Garmin device declares its launcher icon size in its SDK config, and the
sizes differ — the two devices in the manifest already want two. The compiler
accepts an icon of the wrong size and scales it, with a warning, so a single
icon builds for every device and nothing fails.

Candle draws that same bitmap as the settings screen's logo (ADR-0040). A
scaled launcher icon is therefore a scaled logo, resampled by the compiler with
no say over how, on the one band the test suite measures a bitmap against.

## Decision

`just icons` emits **one icon per product in `manifest.xml`**, into
`resources-<device>/drawables/`, at the size that device's own `compiler.json`
declares. The base `resources/` folder carries no launcher icon at all.

The folders are keyed by **device id**, not by screen family. The resource
compiler offers `resources-round-260x260`, and it would be fewer folders — but
the launcher size is a per-device fact that does not follow the resolution, and
a family folder is a bet that two devices sharing a screen share an icon. The id
folder is never wrong; it is only more folders, and they are generated.

## Consequences

A product added to the manifest without running `just icons` fails to build:
there is no base icon to fall back on, so `Drawables.LauncherIcon` resolves to
nothing for it. That is deliberate. The old behaviour — a warning and a scaled
mark — was a silent degradation on the screen that is measured most carefully.
`tools/check-devices.ps1` names the missing folder before the compiler does.

The mark stays procedural in `make-icons.ps1`, drawn once at high resolution
and downscaled per size, so every device gets the same candle and none gets a
resample of another's.

`layoutSettingsLogoFitsItsBand` runs per device and measures the icon that
device actually loads, so a launcher size large enough to spill the settings
band's chord fails with the numbers rather than clipping on the wrist.

The generated `drawables.xml` beside each icon says it is generated. Editing
one by hand is the mistake the comment exists to prevent; the next `just icons`
overwrites it.
