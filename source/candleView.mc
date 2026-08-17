import Toybox.Attention;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

// The one and only screen: the time, three tap-editable settings and the build
// version. The cue is haptic, so nothing here paces you and nothing animates --
// the clock is the only thing on the screen that moves, and it moves once a
// minute.
//
// The pen leaves white in exactly one place: inside a filled control, where
// the glyph is drawn in black and the pen is restored before returning. There
// is no screen state to render beyond that -- palm safety is the watch's own
// Lock Screen, so the app has no lock of its own to dim the controls for. See
// AGENTS.md.
//
// Every coordinate comes from Layout and every string from Display. Neither a
// pixel offset nor a literal caption belongs in this file -- both are covered by
// unit tests that can only test what they can also see.
class candleView extends WatchUi.View {

    const FONT_CLOCK = Graphics.FONT_MEDIUM;
    const FONT_TEXT = Graphics.FONT_XTINY;

    // The "-" / "+" glyphs get a font of their own: XTINY reads as a speck in
    // the middle of a 64 px circle. SMALL is the largest face whose glyph ink
    // still sits comfortably inside the fill -- checked by eye on the shot,
    // which is the only instrument that can see it.
    const FONT_GLYPH = Graphics.FONT_SMALL;

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
        var settings = System.getDeviceSettings();

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);

        drawCentered(
            dc, _clockY, FONT_CLOCK,
            ClockText.formatTime(now.hour, now.min, settings.is24Hour));

        // EVERY, PULSE, POWER -- the same order as the ACTION_ constants in
        // Layout, which is what maps a tap to the row under it.
        drawEditorRow(dc, 0, Display.LABEL_EVERY, app.getEveryText());
        drawEditorRow(dc, 1, Display.LABEL_PULSE, app.getDurationText());
        drawEditorRow(dc, 2, Display.LABEL_POWER, app.getStrengthText());

        // The same two conditions timerCallback needs for a cue to happen at
        // all. The cue path itself is left untouched: it still asks the OS to
        // vibrate and lets the OS decide, so this only reports, never gates.
        var willVibrate = (Attention has :vibrate) && settings.vibrateOn;
        var bottomLine =
            Display.bottomLine(app.APP_VERSION, Display.showsBuildVersion(), willVibrate);
        if (willVibrate) {
            // The previous run's exit breadcrumb, debug builds only. The VIBE
            // OFF warning owns the slot when it fires -- a warning nobody can
            // read because a diagnostic crowded it off the glass is worse
            // than either alone.
            bottomLine += ExitForensics.debugSuffix();
        }
        drawCentered(dc, _versionY, FONT_TEXT, bottomLine);
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
        var rowY = Layout.editorRowCenter(index);
        dc.drawText(
            _centerX, rowY, FONT_TEXT, Display.rowText(label, value),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );
        drawControl(dc, _controlLeftX, rowY, "-");
        drawControl(dc, _controlRightX, rowY, "+");
    }

    // Filled, not outlined: the drawn face should look like the target it is.
    // The old 1 px ring at half this radius read as decoration, and thumbs
    // aimed at it as if the hit zone were that small.
    private function drawControl(dc as Dc, x as Number, y as Number, glyph as String) as Void {
        dc.fillCircle(x, y, Layout.CONTROL_RADIUS);
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            x, y, FONT_GLYPH, glyph,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
    }

}
