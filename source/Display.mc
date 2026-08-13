import Toybox.Lang;

// Every string the main screen draws, in one place.
//
// This is the string counterpart of Layout. The layout tests measure rendered
// text against the round-screen chord, and that measurement is only worth
// anything if it measures the strings the view actually draws. Both sides read
// them from here, so the two cannot drift apart.
//
// They already did once: the fit test asserted "v0.22  UNLOCKED" long after the
// view had switched to drawing "v0.22  EDIT". The test stayed green while
// measuring a string that no longer existed.
module Display {

    const LABEL_PACE     = "PACE";
    const LABEL_STRENGTH = "STRENGTH";
    const LABEL_LENGTH   = "LENGTH";

    const HINT_LOCKED   = "TOP: EDIT";
    const HINT_UNLOCKED = "TOP: LOCK";

    // "v0.22  LOCKED" / "v0.22  EDIT". The version is on screen because reading
    // it off the watch is the only proof of which build a sideload installed --
    // see the deploy notes in AGENTS.md.
    function status(version as String, locked as Boolean) as String {
        return "v" + version + (locked ? "  LOCKED" : "  EDIT");
    }

    // The footer names what the upper button will do next, and nothing else
    // competes for that line. It used to also carry a "Back again to exit"
    // prompt; Back now unlocks rather than arming a confirmation, and the row
    // controls brightening is the feedback that used to need words.
    function footer(locked as Boolean) as String {
        return locked ? HINT_LOCKED : HINT_UNLOCKED;
    }
}
