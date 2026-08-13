import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

// The one and only screen: a clock, a status line, three tap-editable settings
// and a footer hint.
//
// Every coordinate comes from Layout and every string from Display. Neither a
// pixel offset nor a literal caption belongs in this file -- both are covered by
// unit tests that can only test what they can also see.
class pacerView extends WatchUi.View {

    function initialize() {
        View.initialize();
    }

    // Touch locking is opt-in. Returning to this sole View reapplies the user's
    // current choice; a fresh app instance always starts unlocked.
    function onShow() as Void {
        getApp().applyTouchLock();
    }

    function onUpdate(dc as Dc) as Void {
        var width = dc.getWidth();
        var height = dc.getHeight();
        var center = Layout.centerX(width);
        var app = getApp();
        var locked = app.isTouchLocked();

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        var now = System.getClockTime();
        dc.drawText(
            center,
            Layout.clockY(),
            Graphics.FONT_MEDIUM,
            ClockText.formatTime(now.hour, now.min, System.getDeviceSettings().is24Hour),
            Graphics.TEXT_JUSTIFY_CENTER
        );
        dc.drawText(
            center,
            Layout.statusY(),
            Graphics.FONT_XTINY,
            Display.status(app.APP_VERSION, locked),
            Graphics.TEXT_JUSTIFY_CENTER
        );

        drawEditorRow(dc, width, 0, Display.LABEL_PACE, app.getPaceText(), locked);
        drawEditorRow(dc, width, 1, Display.LABEL_STRENGTH, app.getStrengthText(), locked);
        drawEditorRow(dc, width, 2, Display.LABEL_LENGTH, app.getDurationText(), locked);

        var footerFont = Graphics.FONT_XTINY;
        var footerYs = Layout.stackFromBottom(height, [
            dc.getFontHeight(footerFont)
        ]);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            center,
            footerYs[0],
            footerFont,
            Display.footer(locked, app.isExitPromptVisible()),
            Graphics.TEXT_JUSTIFY_CENTER
        );
    }

    // Best-effort lifecycle restoration. Controlled navigation and exit paths
    // restore earlier because this callback can be too late for the
    // foreground-only API.
    function onHide() as Void {
        TouchControl.setEnabled(true);
    }

    private function drawEditorRow(
        dc as Dc,
        width as Number,
        index as Number,
        label as String,
        value as String,
        locked as Boolean
    ) as Void {
        var center = Layout.centerX(width);
        var leftX = Layout.editorControlX(width, false);
        var rightX = Layout.editorControlX(width, true);
        var controlY = Layout.editorRowCenter(index);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            center,
            Layout.editorLabelY(index),
            Graphics.FONT_XTINY,
            label,
            Graphics.TEXT_JUSTIFY_CENTER
        );
        dc.drawText(
            center,
            Layout.editorValueY(index),
            Graphics.FONT_XTINY,
            value,
            Graphics.TEXT_JUSTIFY_CENTER
        );

        // Dimmed while locked, so the screen says which taps are live rather
        // than silently ignoring them.
        if (locked) {
            dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        }
        dc.drawCircle(leftX, controlY, Layout.CONTROL_RADIUS);
        dc.drawCircle(rightX, controlY, Layout.CONTROL_RADIUS);
        dc.drawText(
            leftX,
            controlY,
            Graphics.FONT_XTINY,
            "-",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );
        dc.drawText(
            rightX,
            controlY,
            Graphics.FONT_XTINY,
            "+",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );
    }

}
