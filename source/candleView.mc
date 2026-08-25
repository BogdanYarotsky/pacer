import Toybox.Attention;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

// Candle's screens. There are two, and this one class draws both.
//
// MAIN is what the app opens on: the time, the two settings a session reaches
// for, and the build version. SETTINGS is pushed over it by the upper button
// and carries the interval, which is measured once and then left alone -- so it
// gets a screen of its own and the main screen gets its room back. That extra
// room is the whole point: two rows instead of three is what pays for controls
// this size, at the same 4 px of air from the glass edge the old three-row
// layout was tuned to.
//
// One class rather than two, because the difference between the screens is one
// list of rows and whether the clock and the bottom line come with them. Two
// classes would have shared the row drawing, the control drawing, the resolved
// anchors and the font choices, and differed in four lines.
//
// The cue is haptic, so nothing here paces you and nothing animates. Two things
// on the main screen change on their own -- the clock and the battery -- and
// both ride the same minute-gated redraw, so the screen still repaints about
// once a minute rather than once per cue. Neither says anything about the
// breath. There is no bitmap on either screen and no (:release) rendering fork
// left in this file.
//
// The pen leaves white in exactly one place: inside a control, where the ring
// and the glyph are white over the black of the cleared screen. There is no
// screen state to render beyond that -- palm safety is the watch's own Lock
// Screen, so the app has no lock of its own to dim the controls for. See
// AGENTS.md.
//
// Every coordinate comes from Layout, every string from Display, and every row
// order from Rows. Neither a pixel offset nor a literal caption nor a hand-
// written row order belongs in this file -- all three are covered by unit tests
// that can only test what they can also see.
class candleView extends WatchUi.View {

    const FONT_CLOCK = Graphics.FONT_MEDIUM;
    const FONT_TEXT = Graphics.FONT_XTINY;

    // The "-" / "+" glyphs get a font of their own: XTINY reads as a speck in
    // the middle of a 76 px circle. LARGE keeps the glyph ink at the same
    // fraction of the circle it held when the circles were smaller and the face
    // was SMALL -- checked by eye on the shot, which is the only instrument
    // that can see it.
    const FONT_GLYPH = Graphics.FONT_LARGE;

    // Which screen this instance is, and the rows it carries. Both are fixed
    // for the life of the view; Rows.forScreen is resolved once here rather
    // than on every draw.
    private var _screen as Number;
    private var _rows as Array<Number>;

    // Resolved once in onLayout. Screen size and font metrics cannot change
    // while the app runs, so recomputing them per draw would be pure waste.
    private var _centerX as Number = 0;
    private var _controlLeftX as Number = 0;
    private var _controlRightX as Number = 0;
    private var _screenHeight as Number = 0;
    private var _clockY as Number = 0;
    private var _versionY as Number = 0;
    private var _breadcrumbY as Number = 0;

    function initialize(screen as Number) {
        View.initialize();
        _screen = screen;
        _rows = Rows.forScreen(screen);
    }

    // The entry point for the View, called before it is first shown. The clock
    // and version anchors depend on measured font heights, which need a Dc.
    function onLayout(dc as Dc) as Void {
        var width = dc.getWidth();
        var height = dc.getHeight();
        _centerX = Layout.centerX(width);
        _screenHeight = height;
        _controlLeftX = Layout.editorControlX(width, false);
        _controlRightX = Layout.editorControlX(width, true);

        // The clock sits in the band above this screen's own row block, which
        // on the only screen that draws a clock is the main screen's. Resolved
        // for both because the arithmetic is cheaper than the branch, and
        // because a settings screen that ever grows a clock should get a
        // correct anchor rather than the other screen's.
        _clockY = Layout.clockY(
            dc.getFontHeight(FONT_CLOCK), Layout.editorRowsTop(_rows.size(), height));
        _versionY = Layout.versionY(height, dc.getFontHeight(FONT_TEXT));
        _breadcrumbY = Layout.breadcrumbY(height, dc.getFontHeight(FONT_TEXT));
    }

    // Called on every requestUpdate, and by the framework whenever this view
    // becomes visible -- including when the settings screen above it is popped,
    // which is measured, not assumed. That is what keeps the clock current on
    // the way back: the cue timer's minute check may well have fired while the
    // settings screen was on top, with this view not on screen to hear it.
    function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);

        // The rows, in the order Rows.forScreen gives them -- which is the same
        // order candleDelegate maps taps in, because it is the same list.
        for (var i = 0; i < _rows.size(); i += 1) {
            drawEditorRow(dc, i, _rows[i] as Number);
        }

        // The clock belongs to the screen you breathe on; the settings screen
        // is a place you visit to change one number and leave. Both screens
        // have a bottom slot, but they hold different things -- see Display.
        if (_screen == Rows.SCREEN_MAIN) {
            drawClock(dc);
            drawMainBottomSlot(dc);
        } else {
            drawSettingsBottomSlot(dc);
        }
    }

    private function drawClock(dc as Dc) as Void {
        var now = System.getClockTime();
        drawCentered(
            dc, _clockY, FONT_CLOCK,
            ClockText.formatTime(now.hour, now.min, System.getDeviceSettings().is24Hour));
    }

    // The main screen's slot, in strict precedence:
    //
    //   1. transient input feedback -- the HOLD TO EXIT hint, for two seconds
    //   2. the standing warning     -- VIBE OFF
    //   3. the routine reading      -- the battery
    //
    // The hint outranking the warning is deliberate and it is not the warning
    // being crowded out; it is the warning deferred by two seconds. Back no
    // longer exits, so the hint is the only feedback a Back produces at all,
    // and an input that changes nothing on screen reads as a frozen app --
    // which is a worse thing to hand someone than a two-second wait for a
    // warning they have already been looking at.
    //
    // Nothing here shares a line. "BATT 100%  VIBE OFF" measures 265 px against
    // a 220 px chord this near the bottom of a round screen, so a combined line
    // would be clipped at both ends, and a clipped warning is the one failure
    // this slot exists to prevent. layoutRealLinesFitOnVivoactive5 pins that.
    //
    // Two things have held this slot and lost it outright: the build version,
    // which moved to the settings screen, and the Candle mark, which was
    // deleted. Both were facts about the install. The other three are facts
    // about the session in front of you, which is the difference.
    private function drawMainBottomSlot(dc as Dc) as Void {
        var app = getApp();
        var line = "";

        if (app.showsExitHint()) {
            line = Display.exitHint();
        } else {
            // The same two conditions timerCallback needs for a cue to happen
            // at all. The cue path itself is left untouched: it still asks the
            // OS to vibrate and lets the OS decide, so this only reports.
            var settings = System.getDeviceSettings();
            line = Display.vibeWarning((Attention has :vibrate) && settings.vibrateOn);
            if (line.length() == 0) {
                line = Display.batteryLine(
                    CandleMath.batteryPercent(System.getSystemStats().battery));
            }
        }

        drawCentered(dc, _versionY, FONT_TEXT, line);
    }

    // The settings screen's lower half: which build this is, and above it the
    // previous run's exit breadcrumb. Both are debug-only and both are empty in
    // a release build, so neither line is drawn on a Store install and the
    // screen is its one row and nothing else.
    //
    // They are two lines now, not one string. The breadcrumb used to ride
    // behind the version as a suffix and was capped at two events to keep the
    // combined line inside the chord; on this screen it has a line of its own
    // in an otherwise empty band, which is what let the ring grow to six.
    private function drawSettingsBottomSlot(dc as Dc) as Void {
        var version = Display.buildLine(getApp().APP_VERSION, Display.showsBuildVersion());
        if (version.length() > 0) {
            drawCentered(dc, _versionY, FONT_TEXT, version);
        }

        var chain = ExitForensics.lastExitChain();
        if (chain.length() > 0) {
            drawCentered(dc, _breadcrumbY, FONT_TEXT, chain);
        }
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
        drawControl(dc, _controlLeftX, rowY, "-");
        drawControl(dc, _controlRightX, rowY, "+");
    }

    // A white glyph on a black face inside a white ring.
    //
    // The face is filled black rather than left to the cleared screen so the
    // control is an object in the code and not a coincidence of what happens to
    // be behind it. The ring is wide enough to read as a border: a 1 px stroke
    // at this radius is a hairline, which is what made the old small outlined
    // circle read as decoration and had thumbs aiming at it as if the hit zone
    // were that small. The zone is far larger than the ring, and always was.
    //
    // The pen goes back to 1 before the glyph, because it is state on the Dc
    // and the next thing drawn is not a border.
    private function drawControl(dc as Dc, x as Number, y as Number, glyph as String) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(x, y, Layout.CONTROL_RADIUS);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(Layout.CONTROL_PEN);
        dc.drawCircle(x, y, Layout.CONTROL_RADIUS);
        dc.setPenWidth(1);

        dc.drawText(
            x, y, FONT_GLYPH, glyph,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );
    }

}
