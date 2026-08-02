import Toybox.Lang;
import Toybox.Test;
import Toybox.Graphics;

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

(:test)
function layoutAnchorsAreOnScreen(logger as Test.Logger) as Boolean {
    var h = LayoutTestConst.VA5_H;
    var ys = Layout.stackFromBottom(h, [34, 26, 26]);

    Test.assertMessage(Layout.versionY() >= 0, "version y is above the top edge");
    for (var i = 0; i < ys.size(); i += 1) {
        var y = ys[i];
        logger.debug("stack[" + i + "] y=" + y);
        Test.assertMessage(y >= 0, "stack line " + i + " is above the top edge: " + y);
        Test.assertMessage(y < h, "stack line " + i + " is below the bottom edge: " + y);
    }
    return true;
}

// Lines must never overlap: each line's top edge has to clear the bottom of the
// line above it. This is the exact defect that shipped in the original layout.
(:test)
function layoutStackLinesNeverOverlap(logger as Test.Logger) as Boolean {
    var h = LayoutTestConst.VA5_H;
    var heights = [54, 48, 35];             // deliberately large, worst case
    var ys = Layout.stackFromBottom(h, heights);

    Test.assertEqualMessage(ys.size(), 3, "stackFromBottom should return one y per line");
    for (var i = 1; i < ys.size(); i += 1) {
        var previousBottom = ys[i - 1] + heights[i - 1];
        logger.debug("line " + i + " top=" + ys[i] + " previous bottom=" + previousBottom);
        Test.assertMessage(
            ys[i] >= previousBottom,
            "line " + i + " (y=" + ys[i] + ") overlaps the line above it (ends at " + previousBottom + ")"
        );
    }
    return true;
}

// The whole stack has to stay clear of the bottom edge whatever the fonts are.
(:test)
function layoutStackClearsTheBottomEdge(logger as Test.Logger) as Boolean {
    var h = LayoutTestConst.VA5_H;
    var heights = [54, 48, 35];
    var ys = Layout.stackFromBottom(h, heights);
    var bottom = ys[2] + heights[2];
    logger.debug("stack bottom = " + bottom + " of " + h);
    Test.assertMessage(bottom <= h, "the stack runs off the bottom edge: " + bottom + " > " + h);
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

// The real check, against metrics measured from the device's own font set.
//
// Graphics.getFontHeight cannot be called bare in the test runner -- it raises
// "Invalid Font Specified" because there is no graphics context. A buffered
// bitmap gives a genuine Dc, so both font heights AND rendered text widths are
// measured rather than guessed.
(:test)
function layoutRealLinesFitOnVivoactive5(logger as Test.Logger) as Boolean {
    var w = LayoutTestConst.VA5_W;
    var h = LayoutTestConst.VA5_H;

    var ref = Graphics.createBufferedBitmap({:width => w, :height => h});
    var bmp = ref.get();
    Test.assertMessage(bmp != null, "could not create a buffered bitmap to measure text with");
    var dc = (bmp as Graphics.BufferedBitmap).getDc();

    // These MUST be the fonts pacerView actually draws with, or the test proves
    // nothing about the real screen.
    var paceFont = Graphics.FONT_TINY;
    var subFont = Graphics.FONT_XTINY;

    var ys = Layout.stackFromBottom(h, [
        dc.getFontHeight(paceFont),
        dc.getFontHeight(subFont),
        dc.getFontHeight(subFont)
    ]);

    // The widest string each line can display: the slowest pace (4.50) gives the
    // longest interval text, and the pace line is longest at two-digit values.
    var texts = ["5.71 breaths/min", "Pulse every 6.67 s", "Back again to exit"];
    var fonts = [paceFont, subFont, subFont];
    var names = ["pace", "interval", "hint"];

    // The version line sits alone at the top.
    var versionH = dc.getFontHeight(Graphics.FONT_MEDIUM);
    var versionW = dc.getTextWidthInPixels("v0.13", Graphics.FONT_MEDIUM);
    logger.debug("version: y=" + Layout.versionY() + " w=" + versionW + " h=" + versionH);
    Test.assertMessage(
        Layout.fitsOnRoundScreen(Layout.versionY(), versionW, versionH, w, h),
        "the version line (" + versionW + "px wide) does not fit at y=" + Layout.versionY()
    );

    for (var i = 0; i < texts.size(); i += 1) {
        var y = ys[i];
        var font = fonts[i];
        var textW = dc.getTextWidthInPixels(texts[i], font);
        var fontH = dc.getFontHeight(font);
        var chord = Layout.halfChordAt(y + fontH, w, h) * 2;
        logger.debug(names[i] + ": y=" + y + " w=" + textW + " h=" + fontH + " chord=" + chord);

        Test.assertMessage(
            Layout.fitsOnRoundScreen(y, textW, fontH, w, h),
            "the " + names[i] + " line (\"" + texts[i] + "\", " + textW +
            "px wide) does not fit at y=" + y + " where the chord is " + chord
        );
    }

    // The normal hint shares the same anchor as the wider exit prompt.
    var normalHintW = dc.getTextWidthInPixels("Top button: menu", subFont);
    Test.assertMessage(
        Layout.fitsOnRoundScreen(
            ys[2], normalHintW, dc.getFontHeight(subFont), w, h
        ),
        "the normal main-screen hint does not fit"
    );
    return true;
}
