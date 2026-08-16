import Toybox.Lang;
import Toybox.Test;
import Toybox.Graphics;
import Toybox.System;

// Layout tests for the vivoactive 5.
//
// 390x390 round is not a guess: it comes from the SDK device config at
// %APPDATA%\Garmin\ConnectIQ\Devices\vivoactive5\compiler.json
// ("resolution": 390x390, "deviceFamily": "round-390x390").
module LayoutTestConst {
    const VA5_W = 390;
    const VA5_H = 390;
}

(:test)
function layoutCenterXIsHalfWidth(logger as Test.Logger) as Boolean {
    Test.assertEqualMessage(
        Layout.centerX(LayoutTestConst.VA5_W), 195,
        "centerX(390) should be 195"
    );
    return true;
}

// pacerDelegate maps taps with Layout.DISPLAY_WIDTH while pacerView draws with
// dc.getWidth(). If those two ever disagree, the hit zones drift away from the
// controls they are drawn under and every tap lands on the wrong thing. The
// device itself is the arbiter.
(:test)
function layoutDisplayWidthMatchesTheDevice(logger as Test.Logger) as Boolean {
    var settings = System.getDeviceSettings();
    logger.debug("device screen = " + settings.screenWidth + "x" + settings.screenHeight);
    Test.assertEqualMessage(
        Layout.DISPLAY_WIDTH, settings.screenWidth,
        "Layout.DISPLAY_WIDTH (" + Layout.DISPLAY_WIDTH +
            ") must match the device screen width (" + settings.screenWidth + ")"
    );
    Test.assertEqualMessage(
        settings.screenWidth, settings.screenHeight,
        "the round-screen chord maths assumes a square bounding box"
    );
    return true;
}

// The clock is anchored off the first editor row by the height of the font it
// will be drawn in, so it cannot fall off the top edge or grow down into the
// row below whatever that font turns out to be.
(:test)
function layoutAnchorsAreOnScreen(logger as Test.Logger) as Boolean {
    var h = LayoutTestConst.VA5_H;
    var heights = [20, 26, 35, 48, 54];

    for (var i = 0; i < heights.size(); i += 1) {
        var fontHeight = heights[i] as Number;
        var y = Layout.clockY(fontHeight);
        logger.debug("font " + fontHeight + "px -> clock y=" + y + " bottom=" + (y + fontHeight));

        Test.assertMessage(y >= 0, "clock for a " + fontHeight + "px font is off the top: " + y);
        Test.assertMessage(
            y + fontHeight <= Layout.editorRowTop(0),
            "clock for a " + fontHeight + "px font runs into the first editor row"
        );
    }

    // A taller font must grow the clock upwards, never down into the rows.
    Test.assertMessage(
        Layout.clockY(54) < Layout.clockY(20),
        "a taller font must raise the clock anchor"
    );
    Test.assertMessage(
        Layout.editorRowTop(2) + Layout.EDITOR_ROW_HEIGHT < h,
        "editor rows extend below the screen"
    );
    return true;
}

// The version line is anchored off the bottom edge by the height of the font it
// will actually be drawn in, so it cannot run off the screen whatever that font
// is. Fixed per-line offsets are the exact defect that shipped in the original
// layout: 74/46/24 px from the bottom for fonts 48-54 px tall, so every line
// overlapped the one above it.
(:test)
function layoutVersionClearsTheBottomEdgeForAnyFont(logger as Test.Logger) as Boolean {
    var h = LayoutTestConst.VA5_H;
    var heights = [20, 26, 35, 48, 54];

    for (var i = 0; i < heights.size(); i += 1) {
        var fontHeight = heights[i] as Number;
        var y = Layout.versionY(h, fontHeight);
        var bottom = y + fontHeight;
        logger.debug("font " + fontHeight + "px -> version y=" + y + " bottom=" + bottom);

        Test.assertMessage(y >= 0, "version for a " + fontHeight + "px font is off the top: " + y);
        Test.assertMessage(
            bottom <= h,
            "version for a " + fontHeight + "px font runs off the bottom: " + bottom + " > " + h
        );
        Test.assertMessage(
            bottom <= h - Layout.VERSION_BOTTOM_MARGIN,
            "version for a " + fontHeight + "px font eats into the bottom margin"
        );
    }

    // A taller font must move the line up, never push it down into the edge.
    Test.assertMessage(
        Layout.versionY(h, 54) < Layout.versionY(h, 20),
        "a taller font must raise the version anchor"
    );
    return true;
}

// A round screen is widest at its vertical centre and narrows to nothing at the
// poles. These are the properties every fit check depends on.
(:test)
function layoutHalfChordShapeIsCircular(logger as Test.Logger) as Boolean {
    var w = LayoutTestConst.VA5_W;
    var h = LayoutTestConst.VA5_H;

    Test.assertEqualMessage(
        Layout.halfChordAt(h / 2, w, h), w / 2,
        "at the vertical centre the half-chord should be the full radius"
    );
    Test.assertEqualMessage(
        Layout.halfChordAt(0, w, h), 0,
        "at the very top the half-chord should be 0"
    );
    Test.assertEqualMessage(
        Layout.halfChordAt(h, w, h), 0,
        "at the very bottom the half-chord should be 0"
    );
    Test.assertMessage(
        Layout.halfChordAt(h / 4, w, h) < Layout.halfChordAt(h / 2, w, h),
        "the screen must be narrower above the centre than at it"
    );
    return true;
}

// Anything outside the circle is off screen regardless of how wide the text is.
(:test)
function layoutRejectsTextOutsideTheCircle(logger as Test.Logger) as Boolean {
    var w = LayoutTestConst.VA5_W;
    var h = LayoutTestConst.VA5_H;

    Test.assertMessage(
        !Layout.fitsOnRoundScreen(-5, 10, 20, w, h),
        "text above the top edge must not be reported as fitting"
    );
    Test.assertMessage(
        !Layout.fitsOnRoundScreen(h - 2, 10, 20, w, h),
        "text running past the bottom edge must not be reported as fitting"
    );
    Test.assertMessage(
        !Layout.fitsOnRoundScreen(h - 40, w, 20, w, h),
        "full-width text near the bottom cannot fit on a round screen"
    );
    return true;
}

// The fit boundary must be exact, not approximate: text exactly as wide as the
// available chord fits, and anything wider does not. Pure arithmetic, so this
// holds regardless of which fonts the device ships.
(:test)
function layoutFitIsExactAtTheChordBoundary(logger as Test.Logger) as Boolean {
    var w = LayoutTestConst.VA5_W;
    var h = LayoutTestConst.VA5_H;
    var fontHeight = 20;
    var y = h - 100;

    var topHalf = Layout.halfChordAt(y, w, h);
    var botHalf = Layout.halfChordAt(y + fontHeight, w, h);
    var tightest = topHalf;
    if (botHalf < tightest) { tightest = botHalf; }
    logger.debug("tightest half-chord at y=" + y + " is " + tightest);

    Test.assertMessage(
        Layout.fitsOnRoundScreen(y, tightest * 2, fontHeight, w, h),
        "text exactly as wide as the chord should fit"
    );
    Test.assertMessage(
        !Layout.fitsOnRoundScreen(y, (tightest * 2) + 4, fontHeight, w, h),
        "text wider than the chord must not be reported as fitting"
    );
    return true;
}

// Measure one real string at one real anchor and fail with numbers, not a
// yes/no. Graphics.getFontHeight cannot be called bare in the test runner -- it
// raises "Invalid Font Specified" because there is no graphics context -- so
// callers pass a Dc taken from a buffered bitmap.
function assertLineFits(
    dc as Graphics.Dc,
    y as Number,
    text as String,
    font as Graphics.FontType,
    what as String
) as Void {
    var w = LayoutTestConst.VA5_W;
    var h = LayoutTestConst.VA5_H;
    var textWidth = dc.getTextWidthInPixels(text, font);
    var fontHeight = dc.getFontHeight(font);
    var lower = y + fontHeight;
    var chord = Layout.halfChordAt(y, w, h) * 2;
    var lowerChord = Layout.halfChordAt(lower, w, h) * 2;
    if (lowerChord < chord) { chord = lowerChord; }

    Test.assertMessage(
        Layout.fitsOnRoundScreen(y, textWidth, fontHeight, w, h),
        what + ": \"" + text + "\" is " + textWidth + "px wide at y=" + y +
            " where the usable chord is only " + chord + "px"
    );
}

// The second budget every editor row has to live inside, and the one the chord
// maths cannot see: the row is centred between two circles, so a line wide
// enough to reach them draws straight through them. "5.22 sec (5.75 bpm)" did
// exactly that -- 239px against the 232px between the controls -- while passing
// every fit check on the screen, because it was well inside the chord the whole
// time. Widths come from the device's own font metrics, same as assertLineFits.
function assertClearsControls(
    dc as Graphics.Dc,
    text as String,
    font as Graphics.FontType,
    what as String
) as Void {
    var budget = Layout.editorTextMaxWidth(LayoutTestConst.VA5_W);
    var textWidth = dc.getTextWidthInPixels(text, font);

    Test.assertMessage(
        textWidth <= budget,
        what + ": \"" + text + "\" is " + textWidth + "px wide, and only " + budget +
            "px is clear of the -/+ controls"
    );
}

// The real check, against metrics measured from the device's own font set.
//
// Every string here comes from Display or from the same formatter the app uses,
// so this measures what the view actually draws. Hardcoding the strings here is
// how the test came to be checking "v0.22  UNLOCKED" for a screen that had said
// "v0.22  EDIT" for several commits.
(:test)
function layoutRealLinesFitOnVivoactive5(logger as Test.Logger) as Boolean {
    var w = LayoutTestConst.VA5_W;
    var h = LayoutTestConst.VA5_H;

    var ref = Graphics.createBufferedBitmap({:width => w, :height => h});
    var bmp = ref.get();
    Test.assertMessage(bmp != null, "could not create a buffered bitmap to measure text with");
    var dc = (bmp as Graphics.BufferedBitmap).getDc();

    var clockFont = Graphics.FONT_MEDIUM;
    var textFont = Graphics.FONT_XTINY;
    var clockHeight = dc.getFontHeight(clockFont);
    var textHeight = dc.getFontHeight(textFont);
    logger.debug("measured font heights: clock " + clockHeight + "px, text " + textHeight + "px");

    // 24-hour is the wider of the two clock formats, and 23:59 the widest hour.
    // layoutEveryClockMinuteFits is the exhaustive version of this line.
    assertLineFits(
        dc, Layout.clockY(clockHeight), ClockText.formatTime(23, 59, true), clockFont, "clock");

    var labels = [ Display.LABEL_POWER, Display.LABEL_PACE, Display.LABEL_BUZZ ];
    for (var i = 0; i < labels.size(); i += 1) {
        assertLineFits(dc, Layout.editorLabelY(i), labels[i] as String, textFont, "label " + i);
        assertClearsControls(dc, labels[i] as String, textFont, "label " + i);

        // The controls are circles, not text: check both extremes of each one
        // against the chord at the row's own height.
        var cy = Layout.editorRowCenter(i);
        var radius = Layout.CONTROL_RADIUS;
        var topHalf = Layout.halfChordAt(cy - radius, w, h);
        var bottomHalf = Layout.halfChordAt(cy + radius, w, h);
        var half = topHalf < bottomHalf ? topHalf : bottomHalf;
        Test.assertMessage(
            Layout.editorControlX(w, false) - radius >= (w / 2) - half &&
            Layout.editorControlX(w, true) + radius <= (w / 2) + half,
            "editor controls " + i + " extend outside the round screen"
        );
    }

    // All four forms of the bottom line, because it sits where the round screen
    // is at its tightest -- the chord under this anchor is roughly half the
    // display width -- and a warning nobody can read because it is clipped at
    // both ends is worse than no warning.
    //
    // Both showVersion states are passed explicitly rather than through
    // Display.showsBuildVersion(), which always answers true here: tests compile
    // with -t and that is a debug build. Passing the flag is what keeps the
    // release strings measured by something.
    var versionY = Layout.versionY(h, textHeight);
    var appVersion = getApp().APP_VERSION;
    var shows = [ true, false ];
    var vibes = [ true, false ];
    for (var s = 0; s < shows.size(); s += 1) {
        for (var v = 0; v < vibes.size(); v += 1) {
            var showVersion = shows[s] as Boolean;
            var willVibrate = vibes[v] as Boolean;
            var line = Display.bottomLine(appVersion, showVersion, willVibrate);
            logger.debug(
                "bottom line: version=" + showVersion + " vibrate=" + willVibrate +
                " -> \"" + line + "\"");
            assertLineFits(
                dc, versionY, line, textFont,
                "bottom line (version=" + showVersion + ", vibrate=" + willVibrate + ")");
        }
    }

    // The other end of the same question layoutAnchorsAreOnScreen asks at the
    // top: the version line is anchored to the bottom edge and the last row's
    // value to the row grid, so nothing but a measured font height stands
    // between them. Both are XTINY, and only what is drawn is compared -- a
    // font box is taller than its glyphs, so touching boxes are not a collision.
    var lastValueBottom = Layout.editorValueY(2) + textHeight;
    Test.assertMessage(
        versionY >= lastValueBottom,
        "the version line overlaps the last editor value: version at " + versionY +
            ", the value ends at " + lastValueBottom
    );

    return true;
}

// Every minute of the day, in both clock formats. The clock is set in the
// largest font on the screen and sits nearest the top edge, where the round
// chord is tightest, so "23:59 fits" is worth proving rather than assuming.
(:test)
function layoutEveryClockMinuteFits(logger as Test.Logger) as Boolean {
    var w = LayoutTestConst.VA5_W;
    var h = LayoutTestConst.VA5_H;

    var ref = Graphics.createBufferedBitmap({:width => w, :height => h});
    var bmp = ref.get();
    Test.assertMessage(bmp != null, "could not create a buffered bitmap to measure text with");
    var dc = (bmp as Graphics.BufferedBitmap).getDc();

    var clockFont = Graphics.FONT_MEDIUM;
    var y = Layout.clockY(dc.getFontHeight(clockFont));
    var formats = [ true, false ];

    for (var f = 0; f < formats.size(); f += 1) {
        var is24Hour = formats[f] as Boolean;
        for (var hour = 0; hour < 24; hour += 1) {
            for (var minute = 0; minute < 60; minute += 1) {
                assertLineFits(
                    dc, y, ClockText.formatTime(hour, minute, is24Hour), clockFont,
                    "clock " + hour + ":" + minute + (is24Hour ? " 24h" : " 12h"));
            }
        }
    }
    return true;
}

// Not a sample of plausible values -- every value the tap editor can reach.
// A string that only overflows at a three-digit length, or at one end of the
// pace range and not the other, is exactly what a handful of hand-picked worst
// cases misses. The interval row carries two numbers and their units now, so it
// is the widest line on the screen and the one this sweep is really for.
(:test)
function layoutEveryReachableValueFits(logger as Test.Logger) as Boolean {
    var w = LayoutTestConst.VA5_W;
    var h = LayoutTestConst.VA5_H;
    var app = getApp();

    var ref = Graphics.createBufferedBitmap({:width => w, :height => h});
    var bmp = ref.get();
    Test.assertMessage(bmp != null, "could not create a buffered bitmap to measure text with");
    var dc = (bmp as Graphics.BufferedBitmap).getDc();
    var textFont = Graphics.FONT_XTINY;

    // Stepping by 1 rather than by the control's own step: clamping means the
    // endpoint is reachable even from a value that is off the ladder, so every
    // integer in the band is a value the row can end up displaying.
    //
    // Both budgets are checked for every one of them -- the chord above and
    // below the line, and the clear width between the two controls. The second
    // is the one the pace row spends: it is the widest line on the screen, and
    // the strength and buzz rows have well over 100px to spare against it.
    //
    // The row indices are the on-screen order, POWER then PACE then BUZZ. They
    // are not interchangeable: editorValueY(0) is nearer the top of the glass
    // than editorValueY(1), so sweeping a row's values at another row's anchor
    // measures the wrong chord.
    for (var v = app.MIN_VIBE_STRENGTH; v <= app.MAX_VIBE_STRENGTH; v += 1) {
        var strength = PacerMath.formatStrength(v);
        assertLineFits(dc, Layout.editorValueY(0), strength, textFont, "strength " + v);
        assertClearsControls(dc, strength, textFont, "strength " + v);
    }
    for (var v = app.MIN_PACE_HUNDREDTHS; v <= app.MAX_PACE_HUNDREDTHS; v += 1) {
        var pace = PacerMath.formatPaceSummary(v);
        assertLineFits(dc, Layout.editorValueY(1), pace, textFont, "pace " + v);
        assertClearsControls(dc, pace, textFont, "pace " + v);
    }
    for (var v = app.MIN_VIBE_DURATION; v <= app.MAX_VIBE_DURATION; v += 1) {
        var duration = PacerMath.formatDuration(v);
        assertLineFits(dc, Layout.editorValueY(2), duration, textFont, "duration " + v);
        assertClearsControls(dc, duration, textFont, "duration " + v);
    }
    return true;
}

// --- tap hit mapping --------------------------------------------------------
//
// editorActionAt encodes its result as (row * 2) + direction, so these six cases
// are what pins the ACTION_ constants to staying contiguous and in order.
//
// The y values are the three rows top to bottom, and the actions are the screen
// order they now carry: POWER, PACE, BUZZ. This is the test that fails if a row
// is moved on screen without moving its ACTION_ constants with it -- the failure
// mode being that every tap edits a different setting than the one under it,
// which nothing else here would notice.

(:test)
function editorLayoutMapsEveryControl(logger as Test.Logger) as Boolean {
    var w = 390;
    Test.assertEqualMessage(Layout.editorActionAt(55, 130, w), Layout.ACTION_STRENGTH_DOWN, "power -");
    Test.assertEqualMessage(Layout.editorActionAt(335, 130, w), Layout.ACTION_STRENGTH_UP, "power +");
    Test.assertEqualMessage(Layout.editorActionAt(55, 202, w), Layout.ACTION_PACE_DOWN, "pace -");
    Test.assertEqualMessage(Layout.editorActionAt(335, 202, w), Layout.ACTION_PACE_UP, "pace +");
    Test.assertEqualMessage(Layout.editorActionAt(55, 274, w), Layout.ACTION_DURATION_DOWN, "buzz -");
    Test.assertEqualMessage(Layout.editorActionAt(335, 274, w), Layout.ACTION_DURATION_UP, "buzz +");
    return true;
}

(:test)
function editorLayoutRejectsLabelsAndOutsideRows(logger as Test.Logger) as Boolean {
    var w = 390;
    Test.assertEqualMessage(Layout.editorActionAt(195, 130, w), Layout.ACTION_NONE, "power label");
    Test.assertEqualMessage(Layout.editorActionAt(55, 90, w), Layout.ACTION_NONE, "above rows");
    Test.assertEqualMessage(Layout.editorActionAt(335, 312, w), Layout.ACTION_NONE, "below rows");
    return true;
}
