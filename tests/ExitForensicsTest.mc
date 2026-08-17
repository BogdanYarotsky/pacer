import Toybox.Application.Storage;
import Toybox.Lang;
import Toybox.Test;

// The exit breadcrumb, exercised through the same debug implementations the
// sideload runs (tests compile with -t, which is a debug build). This is the
// fourth test allowed to write to Storage -- the breadcrumb is observable
// nowhere else -- and it restores the diagnostic key in a `finally` like the
// other three. Note the one-way latch: noteExit fires once per app run, so
// everything about it has to be proven inside this single test.
(:test)
function exitForensicsChainsAndPersists(logger as Test.Logger) as Boolean {
    var saved = Storage.getValue(ExitForensics.STORAGE_KEY);
    try {
        // Three events through a two-slot ring: the oldest falls off, and the
        // chain reads oldest-to-newest with the exit tag last -- the phantom
        // swipe fingerprint, exactly as the module header documents it.
        ExitForensics.recordEvent("Bs");
        ExitForensics.recordEvent("T");
        ExitForensics.recordEvent("P5");
        ExitForensics.noteExit("B!");
        Test.assertEqualMessage(
            Storage.getValue(ExitForensics.STORAGE_KEY) as String, "T.P5>B!",
            "the breadcrumb must keep the last two events and the exit tag");

        // First call wins: the onStop that follows every exit must not
        // overwrite the chain onBack already noted.
        ExitForensics.noteExit("S");
        Test.assertEqualMessage(
            Storage.getValue(ExitForensics.STORAGE_KEY) as String, "T.P5>B!",
            "a later noteExit must not overwrite the first");

        // The suffix the debug bottom line appends: a leading space, then the
        // stored chain, so a missing breadcrumb costs the line nothing.
        Test.assertEqualMessage(
            ExitForensics.debugSuffix(), " T.P5>B!",
            "the bottom-line suffix must carry the stored breadcrumb");
    } finally {
        if (saved instanceof String) {
            Storage.setValue(ExitForensics.STORAGE_KEY, saved);
        } else {
            Storage.deleteValue(ExitForensics.STORAGE_KEY);
        }
    }
    return true;
}
