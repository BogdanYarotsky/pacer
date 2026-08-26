import Toybox.Lang;

// Every string the screens draw, in one place.
//
// This is the string counterpart of Layout. The layout tests measure rendered
// text against the round-screen chord, and that measurement is only worth
// anything if it measures the strings the view actually draws. Both sides read
// them from here, so the two cannot drift apart.
//
// They already did once: the fit test asserted "v0.22  UNLOCKED" long after the
// view had switched to drawing "v0.22  EDIT". The test stayed green while
// measuring a string that no longer existed.
//
// Both of those strings are gone now, along with the "TOP: LOCK" hint. The
// screen said the lock state twice in words while the row controls were already
// showing it by dimming, and named a button that is right there under a thumb.
// What is left is the time, the settings and the build.
module Display {

    // Captions are display strings and nothing else. Two of the three do not
    // match the code underneath them -- PULSE over _vibeDuration, POWER over
    // _vibeStrength -- and that is deliberate: a caption can be re-worded in
    // this file alone, while the keys those settings are saved under
    // (vibrationStrength, vibrationDuration) are on the watch's disk and cannot
    // be re-worded at all. Renaming a key would silently reset that setting on
    // every watch running this app.
    //
    // The first three are five characters, so the label column reads as a
    // column. Units stay beside the values rather than moving up into the
    // captions.
    //
    // PACE is the one at four, and padding it would be worse than the ragged
    // edge: rows are centred, not left-aligned, so a leading space would shift
    // the whole line off centre to buy an alignment nobody can see. It is also
    // the only caption whose value carries a three-letter unit, and the row it
    // shares a screen with is EVERY -- "EVERY 5.26s" against "PACE 5.7bpm" is
    // near enough the same length that the column reads straight anyway.
    const LABEL_EVERY = "EVERY";
    const LABEL_PULSE = "PULSE";
    const LABEL_POWER = "POWER";
    const LABEL_PACE = "PACE";

    // Not a row caption -- the battery is not a setting and nothing taps it --
    // but it borrows the same grammar, because it is drawn two lines under
    // POWER and a bare "80%" there would read as another setting.
    //
    // Spelled out, where the captions above it are clipped to five characters.
    // They are clipped to line up as a column and because a row has two
    // circles eating its width; this line has neither constraint -- it is
    // alone on the widest thing in the slot and still leaves most of the chord
    // unused, so "BATT" was an abbreviation buying nothing. The one budget it
    // does have to answer to is the round screen down here, and
    // layoutRealLinesFitOnVivoactive5 measures all 101 readings against it.
    const LABEL_BATTERY = "BATTERY";

    // The caption for a row, keyed by the row's identity and never by its
    // position. Which screen a row is on, and where on it, is Rows.forScreen's
    // business and no caption's -- that separation is what let the EVERY row
    // move to a screen of its own without a single string changing.
    function rowLabel(row as Number) as String {
        if (row == Rows.EVERY) {
            return LABEL_EVERY;
        }
        if (row == Rows.PACE) {
            return LABEL_PACE;
        }
        if (row == Rows.PULSE) {
            return LABEL_PULSE;
        }
        return LABEL_POWER;
    }

    // A row is one line: caption, one space, value -- "EVERY 5s". Composed
    // here and nowhere else, so the view draws and the layout tests measure
    // the identical string; a second copy of this concatenation in either
    // place is the exact drift the module header warns about.
    //
    // It takes the row rather than the caption so the caption lookup is inside
    // the composition and not repeated at both call sites. The value is passed
    // in because the view wants the one a watch is holding and the layout sweep
    // wants all 1496 of them.
    function rowText(row as Number, value as String) as String {
        return rowLabel(row) + " " + value;
    }

    // --- the bottom slot, one per screen ------------------------------------
    //
    // Both screens have a slot along the bottom, and they no longer hold the
    // same kind of thing. The split is: **the main screen says whether the app
    // can do its job right now; the settings screen says what the app is.**
    //
    // The version used to share the main screen's slot with the warning, and
    // moving it out is what empties that slot during a session. It is a
    // development instrument and the main screen is where you breathe -- the
    // less on it the better, and the version is the one thing there that never
    // mattered while breathing.

    // What the main screen's slot says for two seconds after a Back.
    //
    // Back does not exit any more, so without this a press produces nothing at
    // all on screen and the app reads as frozen. It names the gesture that does
    // work rather than just refusing the one that does not.
    //
    // "HOLD" means the lower button held, which raises onMenu -- confirmed on
    // the wrist 2026-08-25, and the one gesture the firmware has never been
    // caught synthesizing.
    function exitHint() as String {
        return "HOLD TO EXIT";
    }

    // The main screen's slot: one warning, and only one -- that no cue is
    // going to arrive. A watch with vibration switched off runs a flawless
    // session and delivers nothing, which is indistinguishable from a dead
    // motor, a bad sideload or a bug. It is the app's single failure mode that
    // the app itself can see.
    //
    // This is not the visual cue AGENTS.md forbids, and the distinction is
    // worth stating because the slot is easy to grow: it does not change
    // between pulses, carries no phase, and says nothing about breathing.
    // Nothing that changes with the breath may ever go here.
    //
    // Empty when the watch is in order, and that empty string is what hands the
    // slot to the battery: the view draws the charge only when this returns
    // nothing, so the warning can never be crowded out by a routine reading.
    function vibeWarning(willVibrate as Boolean) as String {
        return willVibrate ? "" : "VIBE OFF";
    }

    // What the main screen's slot says when nothing is wrong: the charge left.
    //
    // It is there for the same reason the clock is, and the argument is the one
    // that kept the clock when deleting it was proposed -- knowing the watch
    // will last the session, without breaking off the session to find out, IS
    // the job. The delegation rule would otherwise send you to the watch's own
    // controls menu, which is a button hold and a screen away from the breath.
    //
    // It does not put the slot back where it was before the version left. The
    // charge is a fact about the session you are in; a build number was a fact
    // about the install, and that is the one the main screen is better without.
    //
    // Rule 1 is safe and it is worth writing down why: this changes about once
    // an hour, never between two cues, and carries nothing about the breath. It
    // costs no repaint at all -- it rides the clock's minute-gated redraw, so
    // the reading is at most a minute stale and the screen still repaints once
    // a minute rather than eleven times.
    //
    // Same grammar as a row -- caption, one space, value with the unit tight
    // against the number -- because it is drawn under two lines that read that
    // way and an exception would only look like a mistake.
    function batteryLine(percent as Number) as String {
        return LABEL_BATTERY + " " + percent.toString() + "%";
    }

    // The settings screen's way out, drawn along its bottom band.
    //
    // A visible control rather than a gesture, and that is the whole point:
    // this screen used to be popped by Back, which the firmware forges for a
    // right swipe, so a sleeve across the glass would close it mid-adjustment.
    // Back is swallowed here now, exactly as on the main screen, and this word
    // is what replaces it. The main screen could answer a swallowed Back with a
    // hint naming a held button; there is no held gesture for "go back", so
    // this screen answers with a target instead.
    //
    // It is drawn in every build. The version above it is a debug instrument
    // and vanishes on a Store install; this does not, because on a Store
    // install it is the only way out anybody can see.
    function backLabel() as String {
        return "BACK";
    }

    // The settings screen's top slot: which build this is.
    //
    // A sideload cannot be verified from the host at all -- MTP exposes no
    // sizes and the directory listing lies in both directions -- so on a
    // sideload the on-screen version is the only proof of which build is
    // running, and every `just deploy` bumps it for exactly that reason. It is
    // one button press away rather than in front of you all session, which is
    // the right trade for something you read once after a deploy.
    //
    // A Store install has no such problem: the Connect IQ app reports the
    // installed version, which makes drawing it there the same duplication the
    // delegation rule rejects everywhere else in this app. So it ships only in
    // the builds that need it, and every sideload is already a debug build --
    // deploy.ps1 calls build.ps1 without -Release.
    function buildLine(appVersion as String, showVersion as Boolean) as String {
        return showVersion ? "v" + appVersion : "";
    }

    // The predicate is annotated rather than buildLine itself, and that is not
    // a style choice. Unit tests compile with -t, which is a debug build, so an
    // annotated buildLine would leave the release string measured by nothing
    // and shipped to the only audience that cannot report it clipped.
    (:debug)
    function showsBuildVersion() as Boolean {
        return true;
    }

    (:release)
    function showsBuildVersion() as Boolean {
        return false;
    }
}
