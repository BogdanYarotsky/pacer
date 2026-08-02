import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

// Owns Pacer's use of the watch-global touch master switch. Restoring touch is
// a safety condition for exit: callers must not close the app when this returns
// false, because the disabled setting can survive the app and require a reboot.
module TouchControl {

    function setEnabled(enabled as Boolean) as Boolean {
        // On devices without the API there is no global setting to restore.
        var success = enabled;

        if (WatchUi has :configureTouchEvents) {
            try {
                success = WatchUi.configureTouchEvents({
                    :enabled => enabled
                });

                // A redundant enable may be reported as false. The live state
                // is the safety condition that matters before exit.
                if (enabled && !success &&
                        WatchUi has :getTouchEventsConfiguration) {
                    var configuration = WatchUi.getTouchEventsConfiguration();
                    success = configuration[:enabled] == true;
                }
            } catch (error) {
                // The API throws outside foreground mode. Lifecycle fallbacks
                // must never turn cleanup into an app crash.
                success = false;
            }
        }

        traceConfiguration(enabled, success);
        return success;
    }

    (:debug)
    function traceConfiguration(enabled as Boolean, success as Boolean) as Void {
        System.println("[input] touch enabled=" + enabled + " success=" + success);
    }

    (:release)
    function traceConfiguration(enabled as Boolean, success as Boolean) as Void {
    }
}
