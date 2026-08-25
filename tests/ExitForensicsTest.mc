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
        // Eight events through a six-slot ring: the two oldest fall off, and
        // the chain reads oldest-to-newest with the exit tag last. The codes
        // are a real chain -- a drag, the swipe the firmware raises for it, a
        // synthesized key press/release pair and a second press -- because a
        // ring test that walks made-up codes proves the ring and nothing about
        // what is being recorded.
        ExitForensics.recordEvent("Bs");
        ExitForensics.recordEvent("T");
        ExitForensics.recordEvent("D0");
        ExitForensics.recordEvent("D2");
        ExitForensics.recordEvent("S1");
        ExitForensics.recordEvent("P5");
        ExitForensics.recordEvent("R5");
        ExitForensics.recordEvent("P5");
        ExitForensics.noteExit("B!");
        Test.assertEqualMessage(
            Storage.getValue(ExitForensics.STORAGE_KEY) as String,
            "D0.D2.S1.P5.R5.P5>B!",
            "the breadcrumb must keep the last six events and the exit tag");

        // First call wins: the onStop that follows every exit must not
        // overwrite the chain onBack already noted.
        ExitForensics.noteExit("S");
        Test.assertEqualMessage(
            Storage.getValue(ExitForensics.STORAGE_KEY) as String,
            "D0.D2.S1.P5.R5.P5>B!",
            "a later noteExit must not overwrite the first");

        // What the settings screen draws on its own line: the bare stored
        // chain, with no leading space, because it shares with nothing now.
        Test.assertEqualMessage(
            ExitForensics.lastExitChain(), "D0.D2.S1.P5.R5.P5>B!",
            "the breadcrumb line must carry the stored chain verbatim");
    } finally {
        if (saved instanceof String) {
            Storage.setValue(ExitForensics.STORAGE_KEY, saved);
        } else {
            Storage.deleteValue(ExitForensics.STORAGE_KEY);
        }
    }
    return true;
}
