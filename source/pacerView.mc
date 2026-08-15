import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

// The one and only screen: the time, three tap-editable settings and the build
// version. The cue is haptic, so nothing here paces you and nothing animates --
// the clock is the only thing on the screen that moves, and it moves once a
// minute.
//
// The pen is set white once and never changes, because there is no longer any
// screen state to render. Palm safety is the watch's own Lock Screen now, so the
// app has no lock of its own to dim the controls for -- see AGENTS.md.
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

    function onUpdate(dc as Dc) as Void {
        var app = getApp();
        var now = System.getClockTime();

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);

        drawCentered(
            dc, _clockY, FONT_CLOCK,
            ClockText.formatTime(now.hour, now.min, System.getDeviceSettings().is24Hour));

        drawEditorRow(dc, 0, Display.LABEL_PACE, app.getPaceText());
        drawEditorRow(dc, 1, Display.LABEL_STRENGTH, app.getStrengthText());
        drawEditorRow(dc, 2, Display.LABEL_LENGTH, app.getDurationText());

        drawCentered(dc, _versionY, FONT_TEXT, Display.version(app.APP_VERSION));
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
        value as String
    ) as Void {
        drawCentered(dc, Layout.editorLabelY(index), FONT_TEXT, label);
        drawCentered(dc, Layout.editorValueY(index), FONT_TEXT, value);

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
