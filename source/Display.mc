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

    // Captions are display strings and nothing else. Two of the three do not
    // match the code underneath them -- PULSE over _vibeDuration, POWER over
    // _vibeStrength -- and that is deliberate: a caption can be re-worded in
    // this file alone, while the keys those settings are saved under
    // (vibrationStrength, vibrationDuration) are on the watch's disk and cannot
    // be re-worded at all. Renaming a key would silently reset that setting on
    // every watch running this app.
    //
    // All three captions are five characters, so the label column reads as a
    // column. Units stay beside the values rather than moving up into the
    // captions.
    //
    // The order below is the order on screen, and it is also the order of the
    // ACTION_ constants in Layout. Change one without the other and every tap
    // edits the wrong setting.
    const LABEL_EVERY = "EVERY";
    const LABEL_PULSE = "PULSE";
    const LABEL_POWER = "POWER";

    // A row is one line: caption, one space, value -- "EVERY 5s". Composed
    // here and nowhere else, so the view draws and the layout tests measure
    // the identical string; a second copy of this concatenation in either
    // place is the exact drift the module header warns about.
    function rowText(label as String, value as String) as String {
        return label + " " + value;
    }

    // The bottom line. The version is on screen because reading it off the watch
    // is the only proof of which build a sideload installed -- see the deploy
    // notes in AGENTS.md.
    //
    // It carries one warning, and only one: that no cue is going to arrive. A
    // watch with vibration switched off runs a flawless session and delivers
    // nothing, which is indistinguishable from a dead motor, a bad sideload or a
    // bug -- the app's single failure mode that the app itself could see and,
    // until now, said nothing about.
    //
    // This is not the visual cue AGENTS.md forbids, and the distinction is worth
    // stating because the line is easy to grow: it does not change between
    // pulses, carries no phase, and says nothing about breathing. It reports
    // whether the app can do its job at all, which is the same slot the version
    // occupies. Nothing else belongs here.
    // The build version is a development instrument, not a feature, so it ships
    // only in the builds that need it.
    //
    // A sideload cannot be verified from the host at all -- MTP exposes no sizes
    // and the directory listing lies in both directions -- so on a sideload the
    // on-screen version is the only proof of which build is running, and every
    // `just deploy` bumps it for exactly that reason. A Store install has no such
    // problem: the Connect IQ app reports the installed version, which makes
    // drawing it here the same duplication the delegation rule rejects
    // everywhere else in this app.
    //
    // Every sideload is already a debug build -- deploy.ps1 calls build.ps1
    // without -Release -- so the annotation falls exactly on that line.
    //
    // The predicate is annotated rather than bottomLine itself, and that is not
    // a style choice. Unit tests compile with -t, which is a debug build, so an
    // annotated bottomLine would leave the release string measured by nothing
    // and shipped to the only audience that cannot report it clipped.
    (:debug)
    function showsBuildVersion() as Boolean {
        return true;
    }

    (:release)
    function showsBuildVersion() as Boolean {
        return false;
    }

    // Empty in a release build with the watch in order -- and that empty
    // string is what hands the slot to the Candle mark: the view draws the
    // bitmap only when this returns nothing, so any text here, version or
    // warning, always wins the slot.
    function bottomLine(
        appVersion as String, showVersion as Boolean, willVibrate as Boolean
    ) as String {
        var version = showVersion ? "v" + appVersion : "";
        if (willVibrate) {
            return version;
        }
        return showVersion ? version + "  VIBE OFF" : "VIBE OFF";
    }
}
