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
//
// Both of those strings are gone now, along with the "TOP: LOCK" hint. The
// screen said the lock state twice in words while the row controls were already
// showing it by dimming, and named a button that is right there under a thumb.
// What is left is the time, the three settings and the build.
module Display {

    // Captions are display strings and nothing else. Two of the three no longer
    // match the code underneath them -- POWER over _vibeStrength, BUZZ over
    // _vibeDuration -- and that is deliberate: a caption can be re-worded in this
    // file alone, while the keys those settings are saved under
    // (vibrationStrength, vibrationDuration) are on the watch's disk and cannot
    // be re-worded at all. Renaming a key would silently reset that setting on
    // every watch running Pacer.
    //
    // Units stay beside the values rather than moving up into the captions.
    //
    // The order below is the order on screen, and it is also the order of the
    // ACTION_ constants in Layout. Change one without the other and every tap
    // edits the wrong setting.
    const LABEL_POWER = "POWER";
    const LABEL_PACE  = "PACE";
    const LABEL_BUZZ  = "BUZZ";

    // The bottom line. The version is on screen because reading it off the watch
    // is the only proof of which build a sideload installed -- see the deploy
    // notes in AGENTS.md.
    function version(appVersion as String) as String {
        return "v" + appVersion;
    }
}
