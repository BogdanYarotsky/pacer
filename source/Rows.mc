import Toybox.Lang;

// What each screen carries, in the order it carries it.
//
// THIS MODULE EXISTS TO KILL A COUPLING. The row order used to live in two
// places that had to agree by hand: the ACTION_ constants in Layout, which
// encoded a row's position and the setting under it in one number, and the
// drawEditorRow calls in candleView. When those two disagreed everything still
// compiled, every test that did not check the mapping still passed, and every
// tap silently edited a different setting than the one under the thumb.
//
// A second screen made that arrangement impossible anyway -- position 0 is a
// different setting on each screen -- so the order now lives in exactly one
// list per screen. The view draws that list and the delegate maps taps through
// the same list, in the same order, so the two cannot disagree: they are
// reading the same array.
module Rows {

    // A row's identity, which is also the identity of the setting under it: a
    // row is one setting and nothing else, so the two are one thing named once.
    //
    // These are identities and NOT positions. A row's position is its index in
    // the list forScreen returns, and nothing outside that list may assume one.
    // Layout still encodes position, but only as a position -- it never learns
    // which setting is standing there.
    const EVERY = 0;
    const PULSE = 1;
    const POWER = 2;

    // PACE is EVERY wearing the other unit, and it is the one place this
    // module's "a row is one setting" rule bends.
    //
    // It is a row identity because rows are what the view draws and what the
    // delegate maps taps through, and PACE needs both. It is NOT a fourth
    // setting: nothing is stored for it, it has no key, and a tap on it ends
    // in the interval setter like a tap on EVERY does. One setting, two rows,
    // two units -- seconds between cues, and breaths per minute.
    //
    // The reason it exists is that the tools which measure a resonance
    // frequency report bpm, and the arithmetic between the two units is a
    // reciprocal nobody should be doing on a wrist. See candleApp's range
    // constants for why the ranges are what they are.
    const PACE = 3;

    // The two screens. MAIN is what the app opens on; SETTINGS is pushed over
    // it by the upper button and popped by Back or by the same button again.
    const SCREEN_MAIN = 0;
    const SCREEN_SETTINGS = 1;

    // MAIN carries the two settings a session actually reaches for -- how hard
    // the cue is and how long -- and SETTINGS carries the one that is measured
    // once and then left alone. That split is the entire reason for a second
    // screen: two rows on the glass instead of three is what pays for controls
    // half again as large, on the settings a thumb is actually looking for.
    //
    // The interval is not hidden by this, it is parked. It is still one button
    // press away, and it is still the setting the whole app is built around --
    // it just stopped costing the two rows above it a third of their room.
    //
    // **POWER leads PULSE, and the line below is the only place that is
    // decided.** Swapping those two names moves the rows on the glass and moves
    // every tap with them, in the same edit, because candleView draws this list
    // and candleDelegate indexes it. That is the whole point of the list: under
    // the ACTION_ constants it replaced, the same change meant editing two
    // files that could silently disagree, and a screen that still compiled
    // while every tap edited the wrong setting.
    //
    // Callers resolve this once and hold the result: it is read on every draw
    // and on every tap, and the list never changes while a screen is alive.
    // EVERY leads PACE for the same reason POWER leads PULSE: this line is the
    // only place it is decided. They sit on one screen and must -- two views of
    // one number that a wearer cannot see at the same time would be a puzzle
    // rather than a convenience, since changing either moves the other.
    //
    // Their "+" controls move the stored interval in OPPOSITE directions, and
    // that is correct rather than a bug: more breaths per minute is a shorter
    // interval. Reciprocal units cannot agree on which way is up.
    function forScreen(screen as Number) as Array<Number> {
        if (screen == SCREEN_SETTINGS) {
            return [EVERY, PACE] as Array<Number>;
        }
        return [POWER, PULSE] as Array<Number>;
    }
}
