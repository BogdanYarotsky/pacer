import Toybox.Application.Storage;
import Toybox.Lang;

// Debug-only exit forensics: which input chain closed the app?
//
// THE QUESTION THIS ANSWERS: on the wrist, the app sometimes exits during
// settings changes even though swipe-back is swallowed. The explanation has to
// be read from inside the app, and only if the app writes the evidence down
// before it dies -- the exit kills the trace console a sideload never had. So
// the deciding input chain is persisted to Storage on the way out, and the NEXT
// debug launch draws it on the settings screen, where a wrist can read it.
//
// WHAT IT HAS ALREADY ANSWERED (2026-08-25, on the wrist, after a right swipe
// the wearer made and no button press): **"R5.P5>B!"**. The B! tag is only
// reachable when MainInputGate.consume(KEY_ESC) returns true, and the only
// thing that ever latches that gate is onKeyPressed(KEY_ESC). So the firmware
// synthesized a REAL KEY_ESC key event for the swipe gesture. The gate was not
// buggy; it was lied to.
//
// That kills the premise written on MainInputGate: "touch gestures never call
// press()". True in the simulator -- a right swipe there raises onDrag x5 then
// onBack and no key event at all, measured 2026-08-24 -- and false on the
// watch. It is why this never reproduced on a desk.
//
// WHAT IS STILL OPEN: where the touch events sit relative to that synthesized
// key. A fix has to gate on something the firmware is not faking, and the
// candidates are the drag stream and onSwipe. Both are recorded now; neither
// has been seen on hardware yet.
//
// Reading a breadcrumb (ring of the last six events, then the exit tag):
//
//   "P5>B!"      onBack exited after a latched KEY_ESC press. From the lower
//                button, correct. After a SWIPE the wearer never pressed, it
//                is the synthesized key above.
//   "D0.P5>B!"   a drag began, then the key. THIS IS THE ONE TO LOOK FOR: it
//                puts a finger on the glass before the key arrived, which is
//                what a drag-based gate would need to be true.
//   "P5.R5.P5>B!"  a press/release pair that raised no onBack, then a second
//                press that did. Reads as the firmware synthesizing the key
//                for swipe ATTEMPTS, not only for ones that qualify as Back.
//   "S1..."      onSwipe(SWIPE_RIGHT) reached the app. The simulator never
//                raises it for a right swipe; if the wrist does, that is a
//                cleaner discriminator than any of the above.
//   "Bs...>S"    a swipe-back was swallowed, then the platform stopped the
//                app WITHOUT consulting onBack again: firmware-level exit.
//                Only the watch's native Lock Screen prevents that; the
//                configureTouchEvents ban stands (AGENTS.md rule 3, and the
//                watch-global-state incident behind it).
//   ">S"         stopped with no preceding input at all -- system kill,
//                glance timeout, or the like.
//
// Codes: P<k>/R<k> physical key press/release (KEY_ENTER=4, KEY_ESC=5),
// D0/D2 drag start/stop (the CONTINUE stream is dropped -- one swipe raises
// several and would flood the ring), S<d> onSwipe by direction (SWIPE_UP=0,
// SWIPE_RIGHT=1, SWIPE_DOWN=2, SWIPE_LEFT=3), T tap, H hold, L hold released,
// Bs back-swallowed, M menu. Tags: M! the held-lower-button exit, the only one
// the app takes deliberately now; B! the retired onBack exit path, which cannot
// be written any more and in an old chain means a build from before 2026-08-25;
// S onStop with nothing noted.
//
// Everything here is a debug instrument, annotated to nothing in release
// builds (the showsBuildVersion pattern: annotate the leaves, keep the call
// sites unconditional), and the whole module is removable once the phantom
// exit is understood.
module ExitForensics {

    // A diagnostic key, not a setting: renaming or deleting it costs nothing
    // but the previous run's breadcrumb.
    const STORAGE_KEY = "lastExitTrace";

    // Six events of history.
    //
    // It was two, and two was a width limit rather than a judgement: the chain
    // shared the main screen's bottom line with the version, and "v0.99
    // Bs.P5>B!" was already at the chord. A third code pushed it off the glass.
    //
    // That limit is gone. The breadcrumb moved to the settings screen on
    // 2026-08-24 and now has a line of its own, in the empty band between the
    // EVERY row and the version -- ~305 px of chord against the ~180 px it used
    // to share. Six two-character codes with their separators is 20 characters,
    // which layoutExitBreadcrumbFits measures against that band.
    //
    // Two was also not enough to answer the question this module exists for.
    // The wrist returned "R5.P5>B!" on 2026-08-25 after a right swipe: proof
    // that a real KEY_ESC reached the app, and no way to see what came before
    // it, because the ring had already dropped it.
    const HISTORY = 6;

    (:debug) var _chain as Array<String> = [] as Array<String>;
    (:debug) var _noted as Boolean = false;

    (:debug)
    function recordEvent(code as String) as Void {
        _chain.add(code);
        if (_chain.size() > HISTORY) {
            _chain = _chain.slice(1, null) as Array<String>;
        }
    }

    (:release)
    function recordEvent(code as String) as Void {
    }

    // First call wins: onBack's exit path notes "B!", and the onStop that
    // follows every exit finds _noted already set. An onStop that gets here
    // first IS the finding -- nothing in the delegate saw the exit coming.
    (:debug)
    function noteExit(tag as String) as Void {
        if (_noted) {
            return;
        }
        _noted = true;

        var chain = "";
        for (var i = 0; i < _chain.size(); i += 1) {
            if (i > 0) {
                chain += ".";
            }
            chain += _chain[i];
        }
        Storage.setValue(STORAGE_KEY, chain + ">" + tag);
    }

    (:release)
    function noteExit(tag as String) as Void {
    }

    // The previous run's breadcrumb, as its own line on the settings screen.
    // Empty until an exit has been recorded, and empty in release builds, so
    // the line simply is not drawn on either.
    //
    // It used to be a suffix on the version line and returned a leading space
    // to sit behind it. It no longer shares with anything, so it no longer
    // carries the space.
    (:debug)
    function lastExitChain() as String {
        var stored = Storage.getValue(STORAGE_KEY);
        if (stored instanceof String) {
            return stored;
        }
        return "";
    }

    (:release)
    function lastExitChain() as String {
        return "";
    }
}
