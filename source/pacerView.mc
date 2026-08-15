import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

// The one and only screen: the time, three tap-editable settings and the build
// version. The cue is haptic, so nothing here paces you and nothing animates --
// the clock is the only thing on the screen that moves, and it moves once a
// minute.
//
// Every coordinate comes from Layout and every string from Display. Neither a
// pixel offset nor a literal caption belongs in this file -- both are covered by
// unit tests that can only test what they can also see.
class pacerView extends WatchUi.View {

    const FONT_CLOCK = Graphics.FONT_MEDIUM;
    const FONT_TEXT = Graphics.FONT_XTINY;

    // Resolved once in onLayout. Screen size and font metrics cannot change
    // while the app runs, so recomputing them per draw would be pure waste.
    private var _centerX as Number = 0;
    private var _controlLeftX as Number = 0;
    private var _controlRightX as Number = 0;
    private var _clockY as Number = 0;
    private var _versionY as Number = 0;

    function initialize() {
        View.initialize();
    }

    // The entry point for the View, called before it is first shown. The clock
    // and version anchors depend on measured font heights, which need a Dc.
    function onLayout(dc as Dc) as Void {
        var width = dc.getWidth();
        _centerX = Layout.centerX(width);
        _controlLeftX = Layout.editorControlX(width, false);
        _controlRightX = Layout.editorControlX(width, true);
        _clockY = Layout.clockY(dc.getFontHeight(FONT_CLOCK));
        _versionY = Layout.versionY(dc.getHeight(), dc.getFontHeight(FONT_TEXT));
    }

    // Touch locking is opt-in. Returning to this sole View reapplies the user's
    // current choice; a fresh app instance always starts unlocked.
    function onShow() as Void {
        getApp().applyTouchLock();
    }

    function onUpdate(dc as Dc) as Void {
        var app = getApp();
        var locked = app.isTouchLocked();
        var now = System.getClockTime();

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);

        drawCentered(
            dc, _clockY, FONT_CLOCK,
            ClockText.formatTime(now.hour, now.min, System.getDeviceSettings().is24Hour));

        drawEditorRow(dc, 0, Display.LABEL_PACE, app.getPaceText(), locked);
        drawEditorRow(dc, 1, Display.LABEL_STRENGTH, app.getStrengthText(), locked);
        drawEditorRow(dc, 2, Display.LABEL_LENGTH, app.getDurationText(), locked);

        // The rows leave the pen dimmed while locked. The version says nothing
        // about the lock, so it takes the pen back.
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        drawCentered(dc, _versionY, FONT_TEXT, Display.version(app.APP_VERSION));
    }

    // Best-effort lifecycle restoration. Controlled navigation and exit paths
    // restore earlier because this callback can be too late for the
    // foreground-only API.
    function onHide() as Void {
        TouchControl.setEnabled(true);
    }

    private function drawCentered(
        dc as Dc, y as Number, font as Graphics.FontType, text as String
    ) as Void {
        dc.drawText(_centerX, y, font, text, Graphics.TEXT_JUSTIFY_CENTER);
    }

    private function drawEditorRow(
        dc as Dc,
        index as Number,
        label as String,
        value as String,
        locked as Boolean
    ) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        drawCentered(dc, Layout.editorLabelY(index), FONT_TEXT, label);
        drawCentered(dc, Layout.editorValueY(index), FONT_TEXT, value);

        // Dimmed while locked, so the screen says which taps are live rather
        // than silently ignoring them.
        if (locked) {
            dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        }

        var controlY = Layout.editorRowCenter(index);
        drawControl(dc, _controlLeftX, controlY, "-");
        drawControl(dc, _controlRightX, controlY, "+");
    }

    private function drawControl(dc as Dc, x as Number, y as Number, glyph as String) as Void {
        dc.drawCircle(x, y, Layout.CONTROL_RADIUS);
        dc.drawText(
            x, y, FONT_TEXT, glyph,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );
    }

}
