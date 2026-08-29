import Toybox.Lang;
import Toybox.Math;
import Toybox.Test;
import Toybox.Graphics;
import Toybox.System;
// For the settings logo, the one drawn thing here that is a resource rather
// than a string. ADR-0040
import Toybox.WatchUi;

// Layout tests for the vivoactive 5.
//
// 390x390 round is not a guess: it comes from the SDK device config at
// %APPDATA%\Garmin\ConnectIQ\Devices\vivoactive5\compiler.json
// ("resolution": 390x390, "deviceFamily": "round-390x390").
//
// Every sweep in this file walks BOTH screens. A row's anchor depends on how
// many rows share the screen with it, so a value measured at the main screen's
// row 0 says nothing about the same value on the settings screen -- and the
// settings screen is the one carrying the widest string the app can produce.
module LayoutTestConst {
    const VA5_W = 390;
    const VA5_H = 390;
}

// Both screens, so a sweep that claims to cover every reachable value really
// covers every anchor a value can be drawn at.
function everyScreen() as Array<Number> {
    return [Rows.SCREEN_MAIN, Rows.SCREEN_SETTINGS] as Array<Number>;
}

// The band a row's taps can walk, straight off the app's own range constants.
// Stepping it by 1 rather than by the control's step is deliberate: clamping
// means an endpoint is reachable from a value that is off the ladder, so every
// integer in the band is a value the row can end up displaying -- a migrated
// 5.26 s is exactly such a value. rowSweepStep below is where that stops being
// true, for the one row it is not true of.
function rowRange(row as Number) as Array<Number> {
    var app = getApp();
    if (row == Rows.EVERY) {
        return [app.MIN_EVERY_MILLIS, app.MAX_EVERY_MILLIS] as Array<Number>;
    }
    if (row == Rows.PACE) {
        return [app.MIN_PACE_HUNDREDTHS, app.MAX_PACE_HUNDREDTHS] as Array<Number>;
    }
    if (row == Rows.BUZZ) {
        return [app.MIN_VIBE_DURATION, app.MAX_VIBE_DURATION] as Array<Number>;
    }
    return [app.MIN_VIBE_STRENGTH, app.MAX_VIBE_STRENGTH] as Array<Number>;
}

// How far apart two DISPLAYABLE values of a row are, for the sweeps above.
//
// It is 1 for every row today, PACE included, so this changes nothing right
// now -- and it stays because the reason it exists is a live coupling, not a
// historical one. PACE's displayed value never comes out of Storage directly;
// it comes through CandleMath.everyToPace, which rounds to the nearest rung.
// Its rungs are one hundredth of a bpm apart, so every integer in its band IS
// drawable and the sweep is honest by luck of the step being 1.
//
// Coarsen PACE_STEP and that stops being true immediately: at the 0.1 bpm step
// this row shipped with for one day, "2.01 BPM" was a string no interval could
// produce -- and a character wider than anything real, so the sweep would have
// policed a budget against fiction while missing nothing that existed.
// Reading the step from the app is what keeps the two in step.
function rowSweepStep(row as Number) as Number {
    return row == Rows.PACE ? getApp().PACE_STEP : 1;
}

// The line a row draws at a given value, composed through the same two
// functions candleView draws it with. Hardcoding the string here is how the
// test came to be checking "v0.22  UNLOCKED" for a screen that had said
// "v0.22  EDIT" for several commits.
function rowLine(row as Number, value as Number) as String {
    return Display.rowText(row, CandleMath.rowValueText(row, value));
}

(:test)
function layoutCenterXIsHalfWidth(logger as Test.Logger) as Boolean {
    Test.assertEqualMessage(
        Layout.centerX(LayoutTestConst.VA5_W), 195,
        "centerX(390) should be 195"
    );
    return true;
}

// candleDelegate maps taps with Layout.DISPLAY_WIDTH while candleView draws with
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

    // candleDelegate passes DISPLAY_WIDTH for the height too, which is only
    // sound while the two are equal. This is the assertion that makes that
    // shortcut safe rather than lucky.
    Test.assertEqualMessage(
        Layout.DISPLAY_WIDTH, settings.screenHeight,
        "the hit map passes DISPLAY_WIDTH as the height, so it must be the height"
    );
    return true;
}

// Every setting is reachable from at least one row, every row is a row this
// app knows, and every screen has rows.
//
// This is what replaced "the ACTION_ order must match the draw order". That
// coupling is gone -- the view and the delegate read the same list -- but a new
// way to lose a setting arrived with the second screen: drop it from both
// lists and it becomes unreachable, still stored, still driving the cue, and
// with nothing on either screen to change it by.
//
// **It asserted "exactly once" until PACE arrived, and could not any longer.**
// PACE and EVERY are two rows on one setting on purpose -- the same interval in
// the two units the measuring tools report it in -- so "exactly one row per
// setting" is now false by design rather than by accident. What survives is the
// half that catches the failure the assertion was written for: a setting on no
// row at all.
//
// The second half is new, and it is what the weakening costs. Under "exactly
// once" a row naming an identity no setting answers to would have shown up as a
// count of zero somewhere; now it would not, and such a row would draw a
// caption, take taps and edit nothing. So every row is checked against the list
// of identities this app actually handles.
(:test)
function rowsReachEverySettingAtLeastOnce(logger as Test.Logger) as Boolean {
    var settings = [Rows.EVERY, Rows.BUZZ, Rows.POWER] as Array<Number>;
    var knownRows = [Rows.EVERY, Rows.BUZZ, Rows.POWER, Rows.PACE] as Array<Number>;
    var screens = everyScreen();

    for (var s = 0; s < settings.size(); s += 1) {
        var setting = settings[s] as Number;
        var seen = 0;
        for (var i = 0; i < screens.size(); i += 1) {
            var rows = Rows.forScreen(screens[i] as Number);
            for (var r = 0; r < rows.size(); r += 1) {
                if ((rows[r] as Number) == setting) {
                    seen += 1;
                }
            }
        }
        Test.assertMessage(
            seen >= 1,
            "setting " + setting + " is on no screen row at all; it would keep its " +
                "stored value, keep driving the cue, and have nothing to change it by"
        );
    }

    for (var i = 0; i < screens.size(); i += 1) {
        var screen = screens[i] as Number;
        var rows = Rows.forScreen(screen);
        Test.assertMessage(rows.size() > 0, "screen " + screen + " has no rows at all");

        for (var r = 0; r < rows.size(); r += 1) {
            var row = rows[r] as Number;
            var known = false;
            for (var k = 0; k < knownRows.size(); k += 1) {
                if ((knownRows[k] as Number) == row) { known = true; }
            }
            Test.assertMessage(
                known,
                "screen " + screen + " row " + r + " is identity " + row +
                    ", which no formatter, caption or setter answers to"
            );
        }
    }

    // The two views of the interval must share a screen. Apart, changing one
    // would silently move a number the wearer cannot see, which is a puzzle
    // rather than a convenience.
    var settingsRows = Rows.forScreen(Rows.SCREEN_SETTINGS);
    var sawEvery = false;
    var sawPace = false;
    for (var r = 0; r < settingsRows.size(); r += 1) {
        if ((settingsRows[r] as Number) == Rows.EVERY) { sawEvery = true; }
        if ((settingsRows[r] as Number) == Rows.PACE) { sawPace = true; }
    }
    Test.assertMessage(
        sawEvery && sawPace,
        "EVERY and PACE are two views of one number and must be drawn together");
    return true;
}

// The clock is anchored off the main screen's row block by the height of the
// font it will be drawn in, so it cannot fall off the top edge or grow down
// into the row below whatever that font turns out to be.
(:test)
function layoutAnchorsAreOnScreen(logger as Test.Logger) as Boolean {
    var h = LayoutTestConst.VA5_H;
    var rowCount = Rows.forScreen(Rows.SCREEN_MAIN).size();
    var rowsTop = Layout.editorRowsTop(rowCount, h);
    var heights = [20, 26, 35, 48, 54];
    logger.debug("main screen: " + rowCount + " rows, block starts at y=" + rowsTop);

    for (var i = 0; i < heights.size(); i += 1) {
        var fontHeight = heights[i] as Number;
        var y = Layout.topSlotY(fontHeight, rowsTop);
        logger.debug("font " + fontHeight + "px -> clock y=" + y + " bottom=" + (y + fontHeight));

        Test.assertMessage(y >= 0, "clock for a " + fontHeight + "px font is off the top: " + y);
        Test.assertMessage(
            y + fontHeight <= rowsTop,
            "clock for a " + fontHeight + "px font runs into the first editor row"
        );
    }

    // A taller font must grow the clock upwards, never down into the rows.
    Test.assertMessage(
        Layout.topSlotY(54, rowsTop) < Layout.topSlotY(20, rowsTop),
        "a taller font must raise the clock anchor"
    );

    // The row block is centred on the glass, so it must stay on it -- on every
    // screen, not just the busiest one.
    var screens = everyScreen();
    for (var i = 0; i < screens.size(); i += 1) {
        var count = Rows.forScreen(screens[i] as Number).size();
        var top = Layout.editorRowsTop(count, h);
        Test.assertMessage(top >= 0, "screen " + i + "'s row block starts off the top: " + top);
        Test.assertMessage(
            top + (count * Layout.EDITOR_ROW_HEIGHT) <= h,
            "screen " + i + "'s editor rows extend below the screen"
        );
    }
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
        var y = Layout.bottomSlotY(h, fontHeight);
        var bottom = y + fontHeight;
        logger.debug("font " + fontHeight + "px -> version y=" + y + " bottom=" + bottom);

        Test.assertMessage(y >= 0, "version for a " + fontHeight + "px font is off the top: " + y);
        Test.assertMessage(
            bottom <= h,
            "version for a " + fontHeight + "px font runs off the bottom: " + bottom + " > " + h
        );
        Test.assertMessage(
            bottom <= h - Layout.BOTTOM_SLOT_MARGIN,
            "version for a " + fontHeight + "px font eats into the bottom margin"
        );
    }

    // A taller font must move the line up, never push it down into the edge.
    Test.assertMessage(
        Layout.bottomSlotY(h, 54) < Layout.bottomSlotY(h, 20),
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

// A row's control circles, drawn on a round screen, are a circle-in-circle
// problem and not a chord one: what has to be inside the glass is the ring's
// outer edge in every direction, not just horizontally. The chord-at-tangent
// check this replaced was strictly tighter than the real bound and rejected
// radii the glass fits.
//
// The pen is counted as if the whole stroke fell outside the radius. Where the
// SDK puts a wide stroke relative to the radius is not documented, and the
// conservative reading costs 3 px of a margin that has 4 to spare.
function assertControlsAreOnTheGlass(
    rowCenter as Number, what as String
) as Void {
    var w = LayoutTestConst.VA5_W;
    var h = LayoutTestConst.VA5_H;
    var dy = (rowCenter - (h / 2.0)).abs();
    var leftDx = (w / 2.0) - Layout.editorControlX(w, false);
    var rightDx = Layout.editorControlX(w, true) - (w / 2.0);
    var worseDx = leftDx > rightDx ? leftDx : rightDx;
    var reach = Math.sqrt((worseDx * worseDx) + (dy * dy)) +
        Layout.CONTROL_RADIUS + Layout.CONTROL_PEN;

    Test.assertMessage(
        reach <= w / 2.0,
        what + ": the controls reach " + reach + "px from the centre against a " +
            (w / 2) + "px glass radius"
    );
}

// The real check, against metrics measured from the device's own font set.
//
// Every string here comes from Display or from the same formatter the app uses,
// so this measures what the view actually draws -- on both screens, at each
// one's own anchors.
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
    var mainRowsTop = Layout.editorRowsTop(Rows.forScreen(Rows.SCREEN_MAIN).size(), h);
    assertLineFits(
        dc, Layout.topSlotY(clockHeight, mainRowsTop),
        ClockText.formatTime(23, 59, true), clockFont, "clock");

    // Each screen's rows at their widest reachable value, composed exactly as
    // drawn. The exhaustive sweep in layoutEveryReachableValueFits covers every
    // value; these name the worst cases so a failure reads as the string that
    // broke.
    var screens = everyScreen();
    for (var s = 0; s < screens.size(); s += 1) {
        var screen = screens[s] as Number;
        var rows = Rows.forScreen(screen);
        for (var i = 0; i < rows.size(); i += 1) {
            var row = rows[i] as Number;
            var line = rowLine(row, (rowRange(row) as Array<Number>)[1] as Number);
            var center = Layout.editorRowCenter(i, rows.size(), h);
            var what = "screen " + screen + " row " + i;
            logger.debug(what + " centre y=" + center + " \"" + line + "\"");

            assertLineFits(dc, center - (textHeight / 2), line, textFont, what);
            assertClearsControls(dc, line, textFont, what);
            assertControlsAreOnTheGlass(center, what);
        }

        // Adjacent rows must not run their circles into each other. The chord
        // maths cannot see this either -- both circles are comfortably on the
        // glass while overlapping one another.
        if (rows.size() > 1) {
            var gap = Layout.EDITOR_ROW_HEIGHT -
                (2 * (Layout.CONTROL_RADIUS + Layout.CONTROL_PEN));
            logger.debug("screen " + screen + ": " + gap + "px of air between stacked controls");
            Test.assertMessage(
                gap >= 12,
                "controls on adjacent rows are " + gap + "px apart, which reads as one blob"
            );
        }
    }

    // Every form of the main screen's bottom slot, because it sits where the
    // round screen is at its tightest -- the chord under this anchor is roughly
    // half the display width -- and a warning nobody can read because it is
    // clipped at both ends is worse than no warning.
    var bottomSlotY = Layout.bottomSlotY(h, textHeight);
    var flags = [ true, false ];
    for (var f = 0; f < flags.size(); f += 1) {
        var flag = flags[f] as Boolean;
        var warning = Display.vibeWarning(flag);
        logger.debug("main slot: vibrate=" + flag + " -> \"" + warning + "\"");
        assertLineFits(
            dc, bottomSlotY, warning, textFont, "main bottom slot (vibrate=" + flag + ")");
    }

    // The settings screen's TITLE, in its TOP band -- a different anchor from
    // everything above, against a different chord, at the text font's height
    // rather than the clock's. It is drawn in every build now (ADR-0037), so
    // there is no second state to pass in and no release string that goes
    // unmeasured.
    //
    // EVERY version this app can ever show, public and dev, in the BOTTOM band
    // it moved to when the logo took the top one (ADR-0040).
    //
    // The scheme is closed on purpose (ADR-0039), and that is what makes this a
    // sweep rather than a guess at a worst case. A public version is one digit
    // each side of the dot and rolls 1.9 -> 2.0: a hundred strings. A dev build
    // adds an iteration of one to three digits.
    //
    // An open-ended counter is what this replaced, and the cost of one was not
    // hypothetical: the budget would have to be sized for versions nobody will
    // ship, which buys room for fiction by taking font size off the realistic
    // case.
    //
    // version.ps1 refuses to bump past either ceiling. If a guard ever goes,
    // this is what notices -- and it is a tighter net now than when the string
    // carried the app's name, so it will not catch a regression by width alone.
    // It is still the thing that fails if the version is drawn somewhere it
    // does not fit.
    var widest = "";
    var widestPx = 0;

    // "" is the public shape; the rest are the iteration's digit counts at their
    // widest, since every digit is the same width in this font.
    var iterations = [ "", ".1", ".9", ".12", ".99", ".123", ".999" ];
    for (var major = 0; major <= 9; major += 1) {
        for (var minor = 0; minor <= 9; minor += 1) {
            var base = major.toString() + "." + minor.toString();
            for (var i = 0; i < iterations.size(); i += 1) {
                var line = Display.settingsVersion(base + (iterations[i] as String));
                var px = dc.getTextWidthInPixels(line, textFont);
                if (px > widestPx) { widestPx = px; widest = line; }
                assertLineFits(dc, bottomSlotY, line, textFont, "settings version");
            }
        }
    }
    logger.debug("settings version: widest of " + (100 * iterations.size()) +
        " is \"" + widest + "\" at " + widestPx + "px in a band of " +
        (Layout.halfChordAt(bottomSlotY, w, h) * 2) + "px, y=" + bottomSlotY);

    // And the string the source actually holds, which must be one of them --
    // a hand-set version that does not fit the scheme is a broken deploy.
    var shipping = Display.settingsVersion(getApp().APP_VERSION);
    logger.debug("settings version: shipping \"" + shipping + "\" is " +
        dc.getTextWidthInPixels(shipping, textFont) + "px");
    assertLineFits(dc, bottomSlotY, shipping, textFont, "settings version (shipping)");

    // The exit hint takes this slot for two seconds after a Back, on BOTH
    // screens since ADR-0036 -- the settings screen's bottom band held a BACK
    // button until then and holds nothing else now. Back does not exit any
    // more, so this string is the only feedback a Back produces on either
    // screen, and one clipped at the edges would be worse than useless.
    //
    // It was the widest thing this slot ever held until the battery caption was
    // spelled out: 175 px, against "BATTERY 100%" at 187. Which one is widest
    // does not matter, because every form of the slot is measured here -- but
    // the comment that named a winner had gone stale, so it names none now.
    var hint = Display.exitHint();
    logger.debug(
        "exit hint \"" + hint + "\" is " + dc.getTextWidthInPixels(hint, textFont) + "px");
    assertLineFits(dc, bottomSlotY, hint, textFont, "exit hint");

    // Every charge the battery line can show, not a sample of them. One digit,
    // two digits and three all render here, and the widest is not guessable
    // from the endpoints -- digit widths differ.
    var widestBattery = "";
    var widestBatteryPx = 0;
    for (var p = 0; p <= 100; p += 1) {
        var line = Display.batteryLine(p);
        assertLineFits(dc, bottomSlotY, line, textFont, "battery " + p);
        var px = dc.getTextWidthInPixels(line, textFont);
        if (px > widestBatteryPx) {
            widestBatteryPx = px;
            widestBattery = line;
        }
    }
    logger.debug(
        "widest battery line: \"" + widestBattery + "\" at " + widestBatteryPx + "px");

    // The reason the warning takes the slot outright instead of sharing it.
    // If this ever became false the two could go on one line -- but it is
    // false today by a wide margin, and a clipped VIBE OFF is the one failure
    // this slot exists to prevent.
    var combined = widestBattery + "  " + Display.vibeWarning(false);
    var combinedPx = dc.getTextWidthInPixels(combined, textFont);
    var chord = Layout.halfChordAt(bottomSlotY + textHeight, w, h) * 2;
    logger.debug(
        "battery + warning on one line would be " + combinedPx +
        "px against a " + chord + "px chord");
    Test.assertMessage(
        combinedPx > chord,
        "\"" + combined + "\" now fits the slot at " + combinedPx + "px against " + chord +
            "px -- the reason the warning evicts the battery instead of sharing has lapsed"
    );


    // The other end of the same question layoutAnchorsAreOnScreen asks at the
    // top: the version line is anchored to the bottom edge and the last row's
    // line to the row grid, so nothing but a measured font height stands
    // between them. Both are XTINY, and only what is drawn is compared -- a
    // font box is taller than its glyphs, so touching boxes are not a collision.
    // The circles reach lower than the text does, so they are what is measured.
    var mainRows = Rows.forScreen(Rows.SCREEN_MAIN);
    var lastRowBottom = Layout.editorRowCenter(mainRows.size() - 1, mainRows.size(), h) +
        Layout.CONTROL_RADIUS + Layout.CONTROL_PEN;
    Test.assertMessage(
        bottomSlotY >= lastRowBottom,
        "the version line overlaps the last editor row: version at " + bottomSlotY +
            ", the row's controls end at " + lastRowBottom
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
    var y = Layout.topSlotY(
        dc.getFontHeight(clockFont),
        Layout.editorRowsTop(Rows.forScreen(Rows.SCREEN_MAIN).size(), h));
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

// Not a sample of plausible values -- every value the tap editor can reach, on
// the screen and at the row position it can reach it from. A string that only
// overflows at a three-digit length, or at one end of a range and not the
// other, is exactly what a handful of hand-picked worst cases misses.
//
// Both budgets are checked for every line: the chord above and below it, and
// the clear width between the two controls. The second is the one the rows
// actually spend.
//
// Screen and row index are not interchangeable. A row's anchor comes from how
// many rows share its screen, so sweeping the settings screen's values at the
// main screen's row 0 measures the wrong chord entirely.
(:test)
function layoutEveryReachableValueFits(logger as Test.Logger) as Boolean {
    var w = LayoutTestConst.VA5_W;
    var h = LayoutTestConst.VA5_H;

    var ref = Graphics.createBufferedBitmap({:width => w, :height => h});
    var bmp = ref.get();
    Test.assertMessage(bmp != null, "could not create a buffered bitmap to measure text with");
    var dc = (bmp as Graphics.BufferedBitmap).getDc();
    var textFont = Graphics.FONT_XTINY;
    var textHeight = dc.getFontHeight(textFont);

    var swept = 0;
    var screens = everyScreen();
    for (var s = 0; s < screens.size(); s += 1) {
        var screen = screens[s] as Number;
        var rows = Rows.forScreen(screen);
        for (var i = 0; i < rows.size(); i += 1) {
            var row = rows[i] as Number;
            var range = rowRange(row) as Array<Number>;
            var y = Layout.editorRowCenter(i, rows.size(), h) - (textHeight / 2);
            var what = "screen " + screen + " row " + i;

            var step = rowSweepStep(row);
            for (var v = range[0] as Number; v <= (range[1] as Number); v += step) {
                var line = rowLine(row, v);
                assertLineFits(dc, y, line, textFont, what + " value " + v);
                assertClearsControls(dc, line, textFont, what + " value " + v);
                swept += 1;
            }
        }
    }

    logger.debug("swept " + swept + " reachable row lines across " + screens.size() + " screens");
    return true;
}

// --- tap hit mapping --------------------------------------------------------
//
// editorHitAt encodes its answer as (row * 2) + direction -- a position and a
// side, and deliberately nothing about the setting standing there. What these
// tests pin is that the encoding survives its two decoders and that the row
// list a screen draws is the row list its taps walk.
//
// This is the test that fails if a screen's rows are re-ordered without the
// taps following, the failure mode being that every tap edits a different
// setting than the one under it, which nothing else here would notice.

(:test)
function editorLayoutMapsEveryControlOnEveryScreen(logger as Test.Logger) as Boolean {
    var w = LayoutTestConst.VA5_W;
    var h = LayoutTestConst.VA5_H;
    var screens = everyScreen();

    for (var s = 0; s < screens.size(); s += 1) {
        var screen = screens[s] as Number;
        var rows = Rows.forScreen(screen);
        var count = rows.size();

        for (var i = 0; i < count; i += 1) {
            var y = Layout.editorRowCenter(i, count, h);
            var down = Layout.editorHitAt(50, y, w, h, count);
            var up = Layout.editorHitAt(w - 50, y, w, h, count);
            logger.debug(
                "screen " + screen + " row " + i + " at y=" + y +
                " -> down=" + down + " up=" + up);

            Test.assertNotEqualMessage(
                down, Layout.HIT_NONE, "screen " + screen + " row " + i + ": no hit on the left");
            Test.assertNotEqualMessage(
                up, Layout.HIT_NONE, "screen " + screen + " row " + i + ": no hit on the right");

            Test.assertEqualMessage(
                Layout.hitRow(down), i,
                "screen " + screen + ": a tap on row " + i + "'s left decodes to row " +
                    Layout.hitRow(down));
            Test.assertEqualMessage(
                Layout.hitRow(up), i,
                "screen " + screen + ": a tap on row " + i + "'s right decodes to row " +
                    Layout.hitRow(up));
            Test.assertMessage(
                !Layout.hitIsIncrease(down),
                "screen " + screen + " row " + i + ": the left control must decrease");
            Test.assertMessage(
                Layout.hitIsIncrease(up),
                "screen " + screen + " row " + i + ": the right control must increase");
        }
    }

    // The rows the taps walk and the rows the view draws are the same list --
    // which is the property that makes every assertion above about a position
    // also an assertion about the setting under it. Named explicitly so the
    // guarantee is written down somewhere and not merely true.
    Test.assertEqualMessage(
        (Rows.forScreen(Rows.SCREEN_MAIN)[0] as Number), Rows.POWER,
        "the main screen's first row is no longer POWER");
    Test.assertEqualMessage(
        (Rows.forScreen(Rows.SCREEN_MAIN)[1] as Number), Rows.BUZZ,
        "the main screen's second row is no longer BUZZ");
    Test.assertEqualMessage(
        (Rows.forScreen(Rows.SCREEN_SETTINGS)[0] as Number), Rows.EVERY,
        "the settings screen's only row is no longer EVERY");
    return true;
}

// The zone boundaries, one pixel to each side. Both edges are inclusive, so the
// inert centre is exactly (w - 2*edge - 2) px wide -- these four pins are what
// notices an off-by-one creeping into either comparison.
(:test)
function editorLayoutHitZoneEdgesAreInclusive(logger as Test.Logger) as Boolean {
    var w = LayoutTestConst.VA5_W;
    var h = LayoutTestConst.VA5_H;
    var count = Rows.forScreen(Rows.SCREEN_MAIN).size();
    var y = Layout.editorRowCenter(0, count, h);
    var edge = Layout.CONTROL_HIT_EDGE;

    Test.assertNotEqualMessage(
        Layout.editorHitAt(edge, y, w, h, count), Layout.HIT_NONE,
        "the left zone must include its inner edge");
    Test.assertEqualMessage(
        Layout.editorHitAt(edge + 1, y, w, h, count), Layout.HIT_NONE,
        "one px past the left zone must be inert");
    Test.assertNotEqualMessage(
        Layout.editorHitAt(w - edge, y, w, h, count), Layout.HIT_NONE,
        "the right zone must include its inner edge");
    Test.assertEqualMessage(
        Layout.editorHitAt(w - edge - 1, y, w, h, count), Layout.HIT_NONE,
        "one px short of the right zone must be inert");

    // The row block's own edges, top and bottom. A row that starts one pixel
    // late leaves a dead stripe under the clock that nothing on screen explains.
    var top = Layout.editorRowsTop(count, h);
    var bottom = top + (count * Layout.EDITOR_ROW_HEIGHT);
    Test.assertNotEqualMessage(
        Layout.editorHitAt(50, top, w, h, count), Layout.HIT_NONE,
        "the row block must include its top edge");
    Test.assertEqualMessage(
        Layout.editorHitAt(50, top - 1, w, h, count), Layout.HIT_NONE,
        "one px above the row block must be inert");
    Test.assertNotEqualMessage(
        Layout.editorHitAt(50, bottom - 1, w, h, count), Layout.HIT_NONE,
        "the row block must include its last row");
    Test.assertEqualMessage(
        Layout.editorHitAt(50, bottom, w, h, count), Layout.HIT_NONE,
        "the pixel past the row block must be inert");
    return true;
}

// The inward reach of the hit zones is bounded by the widest line ANY row on
// ANY screen can show: the centre text is deliberately inert (reading a value
// must never change it), so the zone edge has to stop short of where that text
// begins. Measured with the device's own font metrics -- this is the test that
// decides how wide CONTROL_HIT_EDGE may be, and its failure message says how
// far back it has to go.
//
// It used to measure the EVERY row alone, and that was not conservative, it was
// wrong: BUZZ at its 250 ms ceiling is 3 px wider than EVERY at 14.95 s, so
// the edge sat under the BUZZ line the whole time the test called it clear.
(:test)
function layoutHitZonesClearRealisticText(logger as Test.Logger) as Boolean {
    var w = LayoutTestConst.VA5_W;
    var h = LayoutTestConst.VA5_H;

    var ref = Graphics.createBufferedBitmap({:width => w, :height => h});
    var bmp = ref.get();
    Test.assertMessage(bmp != null, "could not create a buffered bitmap to measure text with");
    var dc = (bmp as Graphics.BufferedBitmap).getDc();

    var widest = "";
    var widestPx = 0;
    var screens = everyScreen();
    for (var s = 0; s < screens.size(); s += 1) {
        var rows = Rows.forScreen(screens[s] as Number);
        for (var i = 0; i < rows.size(); i += 1) {
            var row = rows[i] as Number;
            var range = rowRange(row) as Array<Number>;
            var step = rowSweepStep(row);
            for (var v = range[0] as Number; v <= (range[1] as Number); v += step) {
                var line = rowLine(row, v);
                var px = dc.getTextWidthInPixels(line, Graphics.FONT_XTINY);
                if (px > widestPx) {
                    widestPx = px;
                    widest = line;
                }
            }
        }
    }

    var textLeft = (w / 2) - (widestPx / 2);
    logger.debug(
        "widest row line anywhere: \"" + widest + "\" at " + widestPx +
        "px, left edge x=" + textLeft);

    Test.assertMessage(
        Layout.CONTROL_HIT_EDGE < textLeft,
        "the hit zone reaches under \"" + widest + "\": edge " + Layout.CONTROL_HIT_EDGE +
            " against a text left edge of " + textLeft
    );
    return true;
}

(:test)
function editorLayoutRejectsLabelsAndOutsideRows(logger as Test.Logger) as Boolean {
    var w = LayoutTestConst.VA5_W;
    var h = LayoutTestConst.VA5_H;
    var count = Rows.forScreen(Rows.SCREEN_MAIN).size();
    var rowY = Layout.editorRowCenter(0, count, h);

    Test.assertEqualMessage(
        Layout.editorHitAt(w / 2, rowY, w, h, count), Layout.HIT_NONE, "row label");
    Test.assertEqualMessage(
        Layout.editorHitAt(50, 10, w, h, count), Layout.HIT_NONE, "above rows");
    Test.assertEqualMessage(
        Layout.editorHitAt(w - 50, h - 10, w, h, count), Layout.HIT_NONE, "below rows");
    return true;
}

// The "-" and the "+" are the same bar at right angles, and this is the test
// that says so. Two properties, both of which the font quietly broke:
//
//   * the minus is exactly as wide as the plus. FONT_LARGE's hyphen measured
//     13 px of ink against the plus's 26 -- half -- and no string measurement
//     could see it, because getTextWidthInPixels reports advance, not ink.
//   * every bar is centred on the circle it sits in. TEXT_JUSTIFY_VCENTER
//     centres the line box, so the hyphen sat 3.5 px and the plus 2 px low.
//
// Both were found by measuring white pixels in shots/screen-main.png, which is
// the only instrument that could see them, and neither can come back while the
// glyphs are rectangles out of Layout: this test measures those rectangles.
(:test)
function layoutControlGlyphsAreSymmetricAndCentred(logger as Test.Logger) as Boolean {
    // A control centre on the real screen. The arithmetic does not depend on
    // which one -- glyphArmStart only ever sees one coordinate at a time.
    var cx = Layout.editorControlX(LayoutTestConst.VA5_W, false);
    var cy = LayoutTestConst.VA5_H / 2;

    var longStart = Layout.glyphArmStart(cx, Layout.GLYPH_LENGTH);
    var shortStart = Layout.glyphArmStart(cy, Layout.GLYPH_THICKNESS);
    logger.debug(
        "glyph arm " + Layout.GLYPH_LENGTH + "x" + Layout.GLYPH_THICKNESS +
        " at (" + longStart + "," + shortStart + ") for a control centred (" + cx + "," + cy + ")");

    // Odd extents, so a bar has a middle pixel to put on the centre. An even
    // one has its centre on a pixel boundary and cannot be centred at all --
    // which is exactly how the font's 4 px hyphen came to sit 3.5 px low.
    Test.assertMessage(
        Layout.GLYPH_LENGTH % 2 == 1,
        "GLYPH_LENGTH is " + Layout.GLYPH_LENGTH + ", and an even bar cannot be centred on a pixel");
    Test.assertMessage(
        Layout.GLYPH_THICKNESS % 2 == 1,
        "GLYPH_THICKNESS is " + Layout.GLYPH_THICKNESS + ", and an even bar cannot be centred on a pixel");

    // Centred: a bar reaches as far past the centre as it starts before it.
    Test.assertEqualMessage(
        (longStart + Layout.GLYPH_LENGTH - 1) - cx, cx - longStart,
        "the long arm is not centred on the control: it starts " + (cx - longStart) +
            "px before the centre and ends " + ((longStart + Layout.GLYPH_LENGTH - 1) - cx) + "px after it");
    Test.assertEqualMessage(
        (shortStart + Layout.GLYPH_THICKNESS - 1) - cy, cy - shortStart,
        "the short arm is not centred on the control: it starts " + (cy - shortStart) +
            "px before the centre and ends " + ((shortStart + Layout.GLYPH_THICKNESS - 1) - cy) + "px after it");

    // Inside the ring, corner first -- the far corner of an arm is what
    // reaches, not its end, and the ring's inner edge is the radius less the
    // pen. Anything closer than a few pixels would read as a glyph touching
    // its own border.
    var halfLong = Layout.GLYPH_LENGTH / 2.0;
    var halfShort = Layout.GLYPH_THICKNESS / 2.0;
    var corner = Math.sqrt((halfLong * halfLong) + (halfShort * halfShort));
    var inner = Layout.CONTROL_RADIUS - Layout.CONTROL_PEN;
    logger.debug("glyph corner reaches " + corner + "px inside a " + inner + "px inner radius");
    Test.assertMessage(
        corner + 4 <= inner,
        "the glyph reaches " + corner + "px against the ring's " + inner + "px inner edge");

    // And big enough to read. The font was chosen at LARGE because XTINY was a
    // speck in a 76 px circle; the bars inherit that judgement as a number.
    var diameter = 2 * Layout.CONTROL_RADIUS;
    Test.assertMessage(
        Layout.GLYPH_LENGTH * 3 >= diameter,
        "the glyph is " + Layout.GLYPH_LENGTH + "px across a " + diameter +
            "px circle, which reads as a speck");
    return true;
}

// The settings screen's logo fits its band, and the band is the round screen's
// narrowest.
//
// A bitmap is the one thing on either screen that no other test can see. Every
// string goes through assertLineFits, which measures against the chord; the
// logo is placed by arithmetic on its own dimensions and would simply be drawn
// off the glass, or over the rows, if either changed. tools/make-icons.ps1
// emits it at a fixed size, so this pins the two together: shrink the band or
// grow the mark and this is what says so. ADR-0040
(:test)
function layoutSettingsLogoFitsItsBand(logger as Test.Logger) as Boolean {
    var w = LayoutTestConst.VA5_W;
    var h = LayoutTestConst.VA5_H;

    var logo = WatchUi.loadResource(Rez.Drawables.LauncherIcon) as WatchUi.BitmapResource;
    var lw = logo.getWidth();
    var lh = logo.getHeight();
    var rowsTop = Layout.editorRowsTop(Rows.forScreen(Rows.SCREEN_SETTINGS).size(), h);
    var y = Layout.topSlotY(lh, rowsTop);
    var x = Layout.centerX(w) - (lw / 2);

    logger.debug("settings logo: " + lw + "x" + lh + " at " + x + "," + y +
        "  band is 0.." + rowsTop);

    // Wholly on the screen, vertically, and clear of the rows below it.
    Test.assertMessage(y >= 0, "the logo starts above the top edge, at y=" + y);
    Test.assertMessage(
        (y + lh) <= rowsTop,
        "the logo reaches y=" + (y + lh) + " but the rows start at " + rowsTop);

    // And inside the CHORD at both its edges, which is the constraint a square
    // bitmap near the top of a round screen actually runs into -- the corners
    // are off the glass long before the centre line is.
    Test.assertMessage(
        Layout.fitsOnRoundScreen(y, lw, lh, w, h),
        "the logo is " + lw + "px wide at y=" + y + ", outside the chord there (" +
            (Layout.halfChordAt(y, w, h) * 2) + "px at its top edge, " +
            (Layout.halfChordAt(y + lh, w, h) * 2) + "px at its bottom)");

    // Centred, to the pixel the integer division allows.
    Test.assertEqualMessage(
        x + (lw / 2), Layout.centerX(w), "the logo must be horizontally centred");
    return true;
}

// The bottom slot sits BELOW the rows, on both screens, with the row controls
// fully clear of it.
//
// This used to pin the settings screen's BACK tap band to the row boundary.
// ADR-0036 deleted the button, and with it the only tap outside a row either
// screen ever answered -- but the geometry it was really guarding survives the
// control, because the band still holds a drawn string: the battery or the
// warning on the main screen, the exit hint on both. A slot that crept up by a
// row height would draw over the bottom row's "-" and "+", which reach lower
// than that row's text does.
//
// Both screens carry two rows today, so the two checks are the same arithmetic.
// They are still run separately, because the day one screen grows a row is the
// day that stops being true and this is where it should fail.
(:test)
function layoutBottomSlotClearsTheRowControls(logger as Test.Logger) as Boolean {
    var h = LayoutTestConst.VA5_H;
    var ref = Graphics.createBufferedBitmap(
        {:width => LayoutTestConst.VA5_W, :height => h});
    var bmp = ref.get();
    Test.assertMessage(bmp != null, "could not create a buffered bitmap to measure text with");
    var dc = (bmp as Graphics.BufferedBitmap).getDc();
    var textHeight = dc.getFontHeight(Graphics.FONT_XTINY);
    var slotY = Layout.bottomSlotY(h, textHeight);

    var screens = [ Rows.SCREEN_MAIN, Rows.SCREEN_SETTINGS ];
    for (var s = 0; s < screens.size(); s += 1) {
        var screen = screens[s] as Number;
        var count = Rows.forScreen(screen).size();
        var rowsBottom = Layout.editorRowsTop(count, h) + (count * Layout.EDITOR_ROW_HEIGHT);

        // The row block's nominal bottom has to contain the circles the bottom
        // row actually draws, which hang below its text.
        var lastRowBottom = Layout.editorRowCenter(count - 1, count, h) +
            Layout.CONTROL_RADIUS + Layout.CONTROL_PEN;
        logger.debug("screen " + screen + ": " + count + " rows ending at y=" +
            rowsBottom + ", controls reach " + lastRowBottom +
            ", bottom slot drawn at " + slotY);
        Test.assertMessage(
            rowsBottom >= lastRowBottom,
            "screen " + screen + ": the rows end at " + rowsBottom +
                " but their controls reach " + lastRowBottom);

        // And the string in the slot is drawn below all of it.
        Test.assertMessage(
            slotY >= rowsBottom,
            "screen " + screen + ": the bottom slot is drawn at " + slotY +
                ", above the rows that end at " + rowsBottom);
    }
    return true;
}
