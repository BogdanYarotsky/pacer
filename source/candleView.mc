import Toybox.Attention;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

// Candle's two screens, drawn by one class. The difference between them is a
// row list and what fills the two bands above and below it. ADR-0028
//
// Nothing here animates and nothing paces you -- the cue is haptic. ADR-0001
//
// Every coordinate comes from Layout, every string from Display, every row
// order from Rows. A pixel offset, a literal caption or a hand-written row
// order in this file puts it beyond the tests that cover it. ADR-0029, ADR-0030
class candleView extends WatchUi.View {

    const FONT_CLOCK = Graphics.FONT_MEDIUM;
    const FONT_TEXT = Graphics.FONT_XTINY;
    // ...and no third: the "-" and "+" are drawn bars. ADR-0015

    private var _screen as Number;
    private var _rows as Array<Number>;

    // Resolved once in onLayout -- screen size and font metrics cannot change
    // while the app runs, so recomputing per draw would be pure waste.
    private var _centerX as Number = 0;
    private var _controlLeftX as Number = 0;
    private var _controlRightX as Number = 0;
    private var _screenHeight as Number = 0;
    private var _clockY as Number = 0;
    private var _bottomSlotY as Number = 0;

    // The settings screen's logo, and where it goes. Loaded once in onLayout
    // rather than per draw: loadResource decodes the PNG, and the cue timer
    // repaints this view every minute. ADR-0040
    private var _logo as WatchUi.BitmapResource? = null;
    private var _logoX as Number = 0;
    private var _logoY as Number = 0;

    function initialize(screen as Number) {
        View.initialize();
        _screen = screen;
        _rows = Rows.forScreen(screen);
    }

    // The anchors depend on measured font heights, which need a Dc. ADR-0011
    function onLayout(dc as Dc) as Void {
        var width = dc.getWidth();
        var height = dc.getHeight();
        _centerX = Layout.centerX(width);
        _screenHeight = height;
        _controlLeftX = Layout.editorControlX(width, false);
        _controlRightX = Layout.editorControlX(width, true);

        // The top band holds the clock on the main screen and the logo on the
        // settings screen -- so it is anchored twice, once per screen, and both
        // are resolved on both because the arithmetic is cheaper than the
        // branch. There used to be a third anchor here for the version as TEXT
        // in this band; it went with the text (ADR-0040), and the compiler
        // caught it sitting unused at -w.
        _clockY = Layout.topSlotY(
            dc.getFontHeight(FONT_CLOCK), Layout.editorRowsTop(_rows.size(), height));
        _bottomSlotY = Layout.bottomSlotY(height, dc.getFontHeight(FONT_TEXT));

        // The logo centres by the same arithmetic the clock does: topSlotY takes
        // a HEIGHT, and a bitmap has one just as a font does.
        var logo = WatchUi.loadResource(Rez.Drawables.LauncherIcon) as WatchUi.BitmapResource;
        _logo = logo;
        _logoX = _centerX - (logo.getWidth() / 2);
        _logoY = Layout.topSlotY(
            logo.getHeight(), Layout.editorRowsTop(_rows.size(), height));
    }

    // Also called when the settings screen above is popped, which is measured
    // rather than assumed -- and is what keeps the clock current on the way
    // back, since the cue timer's minute check may have fired while this view
    // was not on screen to hear it. ADR-0006
    function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);

        // In the order Rows gives them -- the same order the delegate maps taps
        // in, because it is the same list. ADR-0028
        for (var i = 0; i < _rows.size(); i += 1) {
            drawEditorRow(dc, i, _rows[i] as Number);
        }

        if (_screen == Rows.SCREEN_MAIN) {
            drawClock(dc);
            drawMainBottomSlot(dc);
        } else {
            drawSettingsTopSlot(dc);
            drawSettingsBottomSlot(dc);
        }
    }

    private function drawClock(dc as Dc) as Void {
        var now = System.getClockTime();
        drawCentered(
            dc, _clockY, FONT_CLOCK,
            ClockText.formatTime(now.hour, now.min, System.getDeviceSettings().is24Hour));
    }

    // Hint, then warning, then the battery -- strict precedence, one line, no
    // sharing. ADR-0005
    private function drawMainBottomSlot(dc as Dc) as Void {
        var app = getApp();
        var line = "";

        if (app.showsExitHint()) {
            line = Display.exitHint();
        } else {
            // The same two conditions timerCallback needs for a cue to happen
            // at all. The cue path itself is untouched: it still asks the OS to
            // vibrate and lets the OS decide, so this only reports.
            var settings = System.getDeviceSettings();
            line = Display.vibeWarning((Attention has :vibrate) && settings.vibrateOn);
            if (line.length() == 0) {
                line = Display.batteryLine(
                    CandleMath.batteryPercent(System.getSystemStats().battery));
            }
        }

        drawCentered(dc, _bottomSlotY, FONT_TEXT, line);
    }

    // The settings screen's top band: the candle mark, in EVERY build.
    //
    // A logo and not a name. The band held "Candle v1.0" as text until the two
    // bands were made to balance -- a small thing at the top, a small thing at
    // the bottom, the rows between -- and writing the app's name beside its own
    // mark would be saying it twice. ADR-0040
    private function drawSettingsTopSlot(dc as Dc) as Void {
        var logo = _logo;
        if (logo != null) {
            dc.drawBitmap(_logoX, _logoY, logo);
        }
    }

    // The settings screen's bottom band: the exit hint, else the version.
    //
    // Strict precedence, one line, no sharing -- the same shape as the main
    // screen's bottom slot (ADR-0005), and for the same reason. A swallowed
    // Back has two seconds to say what does work, and an input that changes
    // nothing on screen otherwise reads as a frozen app. The version is the
    // resting state and can wait.
    //
    // TRIPWIRE: the marker line below is READ by tools/deploy.ps1 and printed as
    // the last thing a sideload says. That sentence is the whole verification
    // procedure (ADR-0034) -- it is what someone follows while holding the
    // watch -- and it has rotted once already: it went on naming the bottom
    // band after the version moved to the top, sending a wearer to look at a
    // slot that had never shown one. The version has now moved back down here
    // (ADR-0040) and this line moved with it, in the same commit, which is
    // exactly what it exists to force. deploy.ps1 refuses to run without it.
    // DEPLOY-VERIFY: the BOTTOM of the settings screen, BELOW the EVERY and BPM rows
    private function drawSettingsBottomSlot(dc as Dc) as Void {
        var line = getApp().showsExitHint()
            ? Display.exitHint()
            : Display.settingsVersion(getApp().APP_VERSION);
        drawCentered(dc, _bottomSlotY, FONT_TEXT, line);
    }

    private function drawCentered(
        dc as Dc, y as Number, font as Graphics.FontType, text as String
    ) as Void {
        dc.drawText(_centerX, y, font, text, Graphics.TEXT_JUSTIFY_CENTER);
    }

    private function drawEditorRow(dc as Dc, index as Number, row as Number) as Void {
        var rowY = Layout.editorRowCenter(index, _rows.size(), _screenHeight);
        dc.drawText(
            _centerX, rowY, FONT_TEXT,
            Display.rowText(row, getApp().rowValueText(row)),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );
        drawControl(dc, _controlLeftX, rowY, false);
        drawControl(dc, _controlRightX, rowY, true);
    }

    // A white glyph on a black face inside a white ring. The face is filled
    // rather than left to the cleared screen so the control is an object in the
    // code and not a coincidence of what happens to be behind it. ADR-0012
    private function drawControl(dc as Dc, x as Number, y as Number, increase as Boolean) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(x, y, Layout.CONTROL_RADIUS);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(Layout.CONTROL_PEN);
        dc.drawCircle(x, y, Layout.CONTROL_RADIUS);

        // The pen goes back to 1: it is state on the Dc, and the next thing
        // drawn is not a border.
        dc.setPenWidth(1);

        drawGlyph(dc, x, y, increase);
    }

    // One bar, and for the "+" the same bar stood on end. It takes the same
    // boolean the hit encoding and the setter take, so the glyph a control
    // wears and what a tap on it does are one fact spelled one way. ADR-0015
    private function drawGlyph(dc as Dc, x as Number, y as Number, increase as Boolean) as Void {
        dc.fillRectangle(
            Layout.glyphArmStart(x, Layout.GLYPH_LENGTH),
            Layout.glyphArmStart(y, Layout.GLYPH_THICKNESS),
            Layout.GLYPH_LENGTH, Layout.GLYPH_THICKNESS);

        if (increase) {
            dc.fillRectangle(
                Layout.glyphArmStart(x, Layout.GLYPH_THICKNESS),
                Layout.glyphArmStart(y, Layout.GLYPH_LENGTH),
                Layout.GLYPH_THICKNESS, Layout.GLYPH_LENGTH);
        }
    }

}
