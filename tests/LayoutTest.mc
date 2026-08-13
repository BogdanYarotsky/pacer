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

(:test)
function layoutAnchorsAreOnScreen(logger as Test.Logger) as Boolean {
    var h = LayoutTestConst.VA5_H;

    Test.assertMessage(Layout.CLOCK_Y >= 0, "clock is above the top edge");
    Test.assertMessage(
        Layout.STATUS_Y > Layout.CLOCK_Y,
        "the status line must sit below the clock"
    );
    Test.assertMessage(
        Layout.editorRowTop(0) > Layout.STATUS_Y,
        "the first editor row must sit below the status line"
    );
    Test.assertMessage(
        Layout.editorRowTop(2) + Layout.EDITOR_ROW_HEIGHT < h,
        "editor rows extend below the screen"
    );
    return true;
}

// The footer is anchored off the bottom edge by the height of the font it will
// actually be drawn in, so it cannot run off the screen whatever that font is.
// Fixed per-line offsets are the exact defect that shipped in the original
// layout: 74/46/24 px from the bottom for fonts 48-54 px tall, so every line
// overlapped the one above it.
(:test)
function layoutFooterClearsTheBottomEdgeForAnyFont(logger as Test.Logger) as Boolean {
    var h = LayoutTestConst.VA5_H;
    var heights = [20, 26, 35, 48, 54];

    for (var i = 0; i < heights.size(); i += 1) {
        var fontHeight = heights[i] as Number;
        var y = Layout.footerY(h, fontHeight);
        var bottom = y + fontHeight;
        logger.debug("font " + fontHeight + "px -> footer y=" + y + " bottom=" + bottom);

        Test.assertMessage(y >= 0, "footer for a " + fontHeight + "px font is off the top: " + y);
        Test.assertMessage(
            bottom <= h,
            "footer for a " + fontHeight + "px font runs off the bottom: " + bottom + " > " + h
        );
        Test.assertMessage(
            bottom <= h - Layout.FOOTER_BOTTOM_MARGIN,
            "footer for a " + fontHeight + "px font eats into the bottom margin"
        );
    }

    // A taller font must move the line up, never push it down into the edge.
    Test.assertMessage(
        Layout.footerY(h, 54) < Layout.footerY(h, 20),
        "a taller font must raise the footer anchor"
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
    var version = getApp().APP_VERSION;

    // 24-hour is the wider of the two clock formats, and 23:59 the widest hour.
    assertLineFits(dc, Layout.CLOCK_Y, ClockText.formatTime(23, 59, true), clockFont, "clock");

    assertLineFits(dc, Layout.STATUS_Y, Display.status(version, true), textFont, "status locked");
    assertLineFits(dc, Layout.STATUS_Y, Display.status(version, false), textFont, "status unlocked");

    var labels = [ Display.LABEL_PACE, Display.LABEL_STRENGTH, Display.LABEL_LENGTH ];
    for (var i = 0; i < labels.size(); i += 1) {
        assertLineFits(dc, Layout.editorLabelY(i), labels[i] as String, textFont, "label " + i);

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

    var footers = [ Display.footer(true), Display.footer(false) ];
    var footerY = Layout.footerY(h, dc.getFontHeight(textFont));
    for (var i = 0; i < footers.size(); i += 1) {
        assertLineFits(dc, footerY, footers[i] as String, textFont, "footer " + i);
    }

    return true;
}

// Not a sample of plausible values -- every value the tap editor can reach.
// A string that only overflows at 1000 ms or at a three-digit strength is
// exactly what a handful of hand-picked worst cases misses.
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
    // endpoint is reachable even when the step does not divide the range, so
    // every integer in the band is a value the row can end up displaying.
    for (var v = app.MIN_PACE_HUNDREDTHS; v <= app.MAX_PACE_HUNDREDTHS; v += 1) {
        assertLineFits(
            dc, Layout.editorValueY(0), PacerMath.formatPaceSummary(v), textFont, "pace " + v);
    }
    for (var v = app.MIN_VIBE_STRENGTH; v <= app.MAX_VIBE_STRENGTH; v += 1) {
        assertLineFits(
            dc, Layout.editorValueY(1), PacerMath.formatStrength(v), textFont, "strength " + v);
    }
    for (var v = app.MIN_VIBE_DURATION; v <= app.MAX_VIBE_DURATION; v += 1) {
        assertLineFits(
            dc, Layout.editorValueY(2), PacerMath.formatDuration(v), textFont, "duration " + v);
    }
    return true;
}
