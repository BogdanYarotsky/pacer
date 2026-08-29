---
id: 0044
title: The UI is custom rather than Garmin's, and it fights the platform's input model
status: accepted
---

## Context

Written **after** v1.0 shipped, which is late for an ADR and is also the reason
it is worth having. The decision was never made in one sitting — the UI simply
grew custom — so there was nothing to read when the question came back, and it
came back on submission day: *"why didn't I use Garmin's default style? I could
implement the default settings screen. And make numbers adjustable with vertical
swipes like the built-in timer does. This would prevent accidental closing of
the app and many other Garmin quirks."*

Everything below is known from having used the thing, not from predicting it.

## Decision

Both screens are custom `View`s with hand-drawn rows and tap zones. No `Menu2`,
no `Picker`, no native settings page.

**The reason is the premise, not the aesthetics.** Candle is used with the eyes
closed, in a meeting, mid-session (ADR-0001). A native menu's density and target
sizes assume you are looking at the watch. Four labelled rows with large `−`/`+`
circles are one tap each; `Menu2` → scroll → select → picker is four
interactions to change a number you adjust while breathing.

The stated goal at the time was **utmost minimalism, the absolute bare
minimum**, and the drawing side delivered it: an inert screen that never signals
the breath.

## Consequences

**The minimalism fights the device on INPUT, and only on input.** Stripping the
platform's navigation idioms meant re-deriving what Back and a hold mean, while
the firmware kept its own opinion regardless — it forges `KEY_ESC` for a right
swipe (ADR-0008), which is what cost this app the exit gesture (ADR-0009) and a
long hunt before that.

**What going native would genuinely have bought:** `MainInputGate` would not
exist — it is there only to tell a physical `KEY_ENTER` from a tap-derived
`onSelect`, which is a problem you have because both screens are yours — and the
queued-upper-button bug lives in it. Back would have a harmless meaning on a
menu, so a forged `KEY_ESC` there would pop a menu rather than end a session.

**What it would not have bought, and this is the load-bearing half:** the
accidental-exit cost lives on the **session screen**, and that screen cannot be
a menu. It stays a custom `View` either way, the firmware forges `KEY_ESC` on it
either way, and Back would still have needed swallowing and an exit inventing.
Native settings solve the half where an accidental close costs nothing and leave
the half where it ends someone's practice.

**Where the intuition cost actually landed.** Not in adjusting values — that is
the part a stranger works out fastest. It is concentrated in two places, both
button gestures with nothing drawn to announce them: *how do I reach the other
screen* and *how do I quit*. The store listing has to spell both out, which is
the honest measure of the cost.

**Vertical swipes to adjust, as the built-in timer does**, were considered and
not taken. That timer swipes a single **focused** field. Both screens here show
two rows, so a vertical swipe is ambiguous about which one it moves — you would
have to introduce focus, then draw it, move it, and explain it. That is a lot of
new surface to replace a tap that already works, and vertical swipes are
currently swallowed on purpose so a session cannot be paged away.

**The known flaw shipped deliberately**: the lower button's press does nothing
and its hold quits, separated only by duration, so a lingering thumb ends a
session. It was hit repeatedly in real use and left unfixed on purpose. If it
ever needs fixing, `WatchUi.Confirmation` is native, roughly ten lines, and a
delegation rather than a rebuild (ADR-0003).

**The signal that would reverse this decision** is not taste, it is strangers:
if store feedback asks *how do I quit*, that is a narrow fix. If it asks *where
are the settings*, the navigation model is wrong and this ADR is the thing to
argue with.
