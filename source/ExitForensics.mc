import Toybox.Application.Storage;
import Toybox.Lang;

// Debug-only exit forensics: which input chain closed the app?
//
// THE QUESTION THIS ANSWERS: on the wrist, the app sometimes exits during
// settings changes even though swipe-back is swallowed. The two known Connect
// IQ explanations fingerprint differently, but only from inside the app, and
// only if the app writes the evidence down before it dies -- the exit kills
// the trace console a sideload never had. So the deciding input chain is
// persisted to Storage on the way out, and the NEXT debug launch appends it
// to the bottom line, where a wrist can read it.
//
// Reading a breadcrumb (ring of the last two events, then the exit tag):
//
//   "P5>B!"      onBack exited after a latched KEY_ESC press. From the lower
//                button, correct. If it appears after a SWIPE the wearer
//                never pressed, the firmware synthesized a real KEY_ESC for
//                the gesture -- the gate was legitimately fooled, and the fix
//                is designed from this chain, not guessed.
//   "T.P5>B!"    a tap, then a KEY_ESC chain -- the fingerprint of a phantom
//                exit mid-adjustment via a synthesized key.
//   "Bs...>S"    a swipe-back was swallowed, then the platform stopped the
//                app WITHOUT consulting onBack again: firmware-level exit.
//                Only the watch's native Lock Screen prevents that; the
//                configureTouchEvents ban stands (AGENTS.md rule 3, and the
//                watch-global-state incident behind it).
//   ">S"         stopped with no preceding input at all -- system kill,
//                glance timeout, or the like.
//
// Codes: P<k>/R<k> physical key press/release (KEY_ENTER=4, KEY_ESC=5),
// T tap, H hold, L hold released, Bs back-swallowed, M menu. Tags: B! the
// onBack exit path, S onStop with nothing noted.
//
// Everything here is a debug instrument, annotated to nothing in release
// builds (the showsBuildVersion pattern: annotate the leaves, keep the call
// sites unconditional), and the whole module is removable once the phantom
// exit is understood.
module ExitForensics {

    // A diagnostic key, not a setting: renaming or deleting it costs nothing
    // but the previous run's breadcrumb.
    const STORAGE_KEY = "lastExitTrace";

    // Two events of history keep the worst bottom line inside the chord --
    // "v0.99 Bs.P5>B!" -- where three pushed it past the glass.
    (:debug) var _newest as String = "";
    (:debug) var _previous as String = "";
    (:debug) var _noted as Boolean = false;

    (:debug)
    function recordEvent(code as String) as Void {
        _previous = _newest;
        _newest = code;
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

        var chain = _previous;
        if (chain.length() > 0 && _newest.length() > 0) {
            chain += ".";
        }
        chain += _newest;
        Storage.setValue(STORAGE_KEY, chain + ">" + tag);
    }

    (:release)
    function noteExit(tag as String) as Void {
    }

    // The previous run's breadcrumb, as a bottom-line suffix. Empty until an
    // exit has been recorded; the view keeps it off the line whenever the
    // VIBE OFF warning needs the slot.
    (:debug)
    function debugSuffix() as String {
        var stored = Storage.getValue(STORAGE_KEY);
        if (stored instanceof String && stored.length() > 0) {
            return " " + stored;
        }
        return "";
    }

    (:release)
    function debugSuffix() as String {
        return "";
    }
}
