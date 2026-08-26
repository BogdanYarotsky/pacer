import Toybox.Lang;
import Toybox.Math;

// Pure layout maths for Candle's screens.
//
// Every function takes screen dimensions and font metrics as arguments and
// returns coordinates or a yes/no fit answer. Nothing here touches a Dc, so all
// of it runs under the unit test runner without drawing anything. That makes
// looking at shots/*.png the last resort rather than the main loop.
//
// The vivoactive 5 is a 390x390 ROUND display (SDK device config, deviceFamily
// round-390x390). On a round screen the usable width shrinks toward the top and
// bottom edges, so fitting inside the bounding box is not the same as fitting on
// the screen. halfChordAt models that and is the reason these tests are worth
// having at all.
//
// Both screens share every function here. What differs between them is one
// number -- how many rows they carry -- so the row grid takes that as an
// argument rather than pinning it as a constant. Rows.forScreen owns which
// rows those are; this module never learns which setting is standing in a row.
module Layout {

    const DISPLAY_WIDTH = 390;

    // The row grid is CENTRED ON THE GLASS rather than hung from a fixed top
    // edge, and that is not a cosmetic choice. A round screen is widest at its
    // vertical centre, and the control circles are what run out of room first:
    // every pixel a row sits away from the centre is a pixel its circles have
    // to give back. Hanging a two-row grid off the old 96 px top edge would
    // have left the rows lopsided in the band and the outer one further from
    // the centre than it needs to be, for no gain at all.
    //
    // 102 px per row is what two rows can afford. It leaves ~23 px of air
    // between the circles of adjacent rows at the radius below, and the block
    // (93..297 on this device) clears the clock above it and the bottom line
    // under it with room to spare.
    const EDITOR_ROW_HEIGHT = 102;

    // The controls are drawn as large as the glass allows, and the outer rows
    // are the binding case. A ring at (inset, rowCentre) fits iff
    //     sqrt((195 - inset)^2 + (rowCentre - 195)^2) + radius + pen <= 195
    // -- the pen is counted as if the whole stroke fell outside the radius,
    // which is the conservative reading of an undocumented detail.
    //
    // At inset 54, radius 38, pen 3 the main screen's two rows sit 51 px off
    // centre and reach 149.94 + 41 = 190.94 against the 195 px glass: 4.06 px
    // of air, the same margin the old three-row layout was tuned to. Radius 32
    // at the old inset 55 left 1.25 px, which antialiasing visibly clipped.
    // layoutRealLinesFitOnVivoactive5 holds this with the real circle-in-circle
    // arithmetic, not a chord approximation, and it checks both screens.
    //
    // The settings screen's single row sits ON the centre line, where the same
    // circle has 13 px of air. It is drawn at the same radius anyway: a control
    // that changed size when you walked to another screen would read as a
    // different control.
    const CONTROL_INSET = 54;
    const CONTROL_RADIUS = 38;

    // The ring, not a fill. The face is the black of the cleared screen inside
    // a white border, which is what a button looks like and what a filled disc
    // does not. At this radius a 1 px stroke reads as a hairline, so the pen is
    // wide enough to be a border; it is a Layout constant and not a view detail
    // because the fit maths above has to pay for it.
    const CONTROL_PEN = 3;

    // The "-" and "+" are drawn as bars, not set in a font, and these two
    // numbers are their whole shape: how long an arm is, and how thick.
    //
    // A font could not keep the promise the pair makes. FONT_LARGE's hyphen
    // was 13 px of ink against the plus's 26 -- exactly half as wide, in two
    // controls that sit either side of the same row and are meant to read as
    // one control twice -- and no test could have caught it, because
    // getTextWidthInPixels reports an ADVANCE width: the two strings measure
    // alike while the ink does not. A bar has one width and it is this file's.
    //
    // Both numbers are ODD, and that is the vertical centring. A bar of even
    // thickness has its centre on a pixel boundary, so it must land half a
    // pixel off the circle's centre whichever way the division rounds; an odd
    // one has a middle row to put there. Measured off shots/screen-main.png,
    // the font's glyphs sat 3.5 px (the hyphen) and 2 px (the plus) BELOW the
    // centre of their circles -- centred on the font's line box, which is what
    // TEXT_JUSTIFY_VCENTER centres, and never on the ink.
    //
    // 27 px reproduces the old plus's bar to the pixel (26, plus one for
    // symmetry) and is 36% of the 76 px circle; 5 px is the nearest odd number
    // to the font's 4.
    const GLYPH_LENGTH = 27;
    const GLYPH_THICKNESS = 5;

    // The tap zone reaches as far inward as the widest row line allows: the
    // centre text must stay inert (reading a value can never change it), so the
    // zone edge stops short of where that text begins.
    //
    // The widest line either screen can show is now a PACE row -- "PACE
    // 2.01bpm" at 181 px, whose left edge measures x=105, so 104 leaves one
    // pixel and nothing more. It was 108 against "PULSE 250ms" at 171 px until
    // the pace step went to 0.01 bpm and gave that row a second decimal.
    //
    // Four pixels off a zone 104 px wide costs nothing that matters: a control
    // ring ends at x=92, so the zone still reaches 12 px past it. This is the
    // gap between the text and the ring being audited, not the target.
    //
    // Every value of every row on every screen is swept, and the guardrail's
    // failure message says exactly how far back the edge has to go -- which is
    // how this number was picked both times it moved.
    const CONTROL_HIT_EDGE = 104;

    // Clearance either side of a row's centred text, between it and the "-" and
    // "+" circles. See editorTextMaxWidth.
    const EDITOR_TEXT_GUTTER = 10;

    // Clearance from the bottom edge for the version line, which is positioned
    // from its measured font height rather than a fixed offset: the original
    // code used offsets of 74/46/24 from the bottom, i.e. gaps of 28 and 22 px,
    // while the fonts are 48-54 px tall. Every line overlapped the one above it
    // and all three were clipped by the curve of the display.
    const BOTTOM_SLOT_MARGIN = 34;

    // editorHitAt encodes its answer as (row * 2) + direction: a POSITION on
    // the screen and which side of it was touched, and deliberately nothing
    // about which setting is standing there. Rows.forScreen is the only thing
    // that knows that, and the view and the delegate both read it, so a
    // re-ordered screen cannot leave a tap pointing at the wrong setting.
    //
    // That is the whole difference from the ACTION_ constants this replaced.
    // They named the settings -- ACTION_EVERY_UP and friends -- so the encoding
    // itself asserted that EVERY was the first row, on the only screen there
    // was. Two screens make position and identity different things, and the
    // encoding now carries only the one it can actually know.
    const HIT_NONE = 0;
    const DIRECTION_DECREASE = 1;
    const DIRECTION_INCREASE = 2;

    // The settings screen's BACK button: the whole band below the row block,
    // edge to edge.
    //
    // It is a separate question from editorHitAt rather than another code in
    // that encoding, and deliberately so -- editorHitAt answers "which row, and
    // which side of it", and BACK is not a row. Folding it in would put a
    // non-position into an encoding whose entire point is that it carries
    // position and nothing else.
    //
    // The zone is far larger than the word drawn in it, for the same reason the
    // control zones are far larger than their rings: this is a thumb on a
    // 390 px round screen, and the band is empty otherwise. It starts where the
    // rows end, which on a two-row screen is 93 px of height -- and the row
    // controls reach only 10 px into that gap, so nothing above it is at risk.
    function isBackTap(y as Number, height as Number, rowCount as Number) as Boolean {
        return y >= editorRowsTop(rowCount, height) + (rowCount * EDITOR_ROW_HEIGHT);
    }

    function centerX(width as Number) as Number {
        return width / 2;
    }

    // Top edge of a screen's row block: rowCount rows of EDITOR_ROW_HEIGHT,
    // centred on the vertical centre of the glass.
    function editorRowsTop(rowCount as Number, height as Number) as Number {
        return (height / 2) - ((rowCount * EDITOR_ROW_HEIGHT) / 2);
    }

    function editorRowTop(index as Number, rowCount as Number, height as Number) as Number {
        return editorRowsTop(rowCount, height) + (index * EDITOR_ROW_HEIGHT);
    }

    // A row is one line, vertically centred here -- the caption and value sit
    // together on it, and the "-" and "+" circles share the same centre line.
    function editorRowCenter(index as Number, rowCount as Number, height as Number) as Number {
        return editorRowTop(index, rowCount, height) + (EDITOR_ROW_HEIGHT / 2);
    }

    // Top edge of the clock line, given the height of the font it will be drawn
    // in and the top of the row block beneath it. The clock has that whole band
    // to itself and sits centred in it, so a taller font grows away from both
    // neighbours instead of walking into the row below.
    //
    // Centred, and not pinned near the top edge: this is a round screen, and the
    // usable chord at y=12 is only ~134 px against ~168 px at y=19. The clock is
    // set in the largest font on the screen, so it wants the wider line.
    //
    // The band is passed in rather than read from a constant because it is the
    // main screen's row block that defines it, and Layout does not know which
    // screen it is drawing.
    function topSlotY(fontHeight as Number, rowsTop as Number) as Number {
        return (rowsTop - fontHeight) / 2;
    }

    function editorControlX(width as Number, increase as Boolean) as Number {
        return increase ? width - CONTROL_INSET : CONTROL_INSET;
    }

    // The leading edge of one arm of a control's glyph: a bar `extent` px long,
    // centred on `center`. All three bars the two controls draw come out of
    // this one function -- the "+"'s vertical arm is its horizontal arm with
    // the two extents swapped -- so "centred" has one definition and the "-"
    // cannot be a different width from the "+" without this line changing.
    //
    // Integer division, and the constants are odd, so a bar spans
    // center-13..center+13 and the middle pixel IS the centre.
    function glyphArmStart(center as Number, extent as Number) as Number {
        return center - (extent / 2);
    }

    // Widest a row's centred label or value may be drawn.
    //
    // The round-screen chord is not the only thing a row can run out of, and it
    // is the more forgiving of the two: an editor row sits near the vertical
    // centre where the glass is widest, but it also has a circle parked at each
    // end of it. A line long enough to reach one draws straight through it.
    //
    // That is not hypothetical. "5.22 sec (5.75 bpm)" measured 239px in
    // FONT_XTINY against the 232px between the two circles, and cleared every
    // chord check on the screen while sitting on top of both controls. The
    // gutter is what keeps a line that only just misses them from reading as if
    // it touches -- the layout it replaced had about 12 px of air each side.
    function editorTextMaxWidth(width as Number) as Number {
        return width - (2 * (CONTROL_INSET + CONTROL_RADIUS + EDITOR_TEXT_GUTTER));
    }

    // Top edge of the bottom-anchored version line, given the height of the font
    // it will be drawn in. Taking the measured height is what keeps the line
    // clear of the bottom edge whatever font the device ships.
    function bottomSlotY(height as Number, fontHeight as Number) as Number {
        return height - BOTTOM_SLOT_MARGIN - fontHeight;
    }

    // Map only the large edge hit zones to a row and a direction. The centre
    // text is not interactive, preventing an accidental adjustment while
    // reading a value.
    function editorHitAt(
        x as Number,
        y as Number,
        width as Number,
        height as Number,
        rowCount as Number
    ) as Number {
        var top = editorRowsTop(rowCount, height);
        if (y < top || y >= top + (rowCount * EDITOR_ROW_HEIGHT)) {
            return HIT_NONE;
        }

        var direction;
        if (x <= CONTROL_HIT_EDGE) {
            direction = DIRECTION_DECREASE;
        } else if (x >= width - CONTROL_HIT_EDGE) {
            direction = DIRECTION_INCREASE;
        } else {
            return HIT_NONE;
        }

        // Number / Number is integer division in Monkey C, so this is the row
        // index directly.
        var row = (y - top) / EDITOR_ROW_HEIGHT;
        return (row * 2) + direction;
    }

    // The two halves of a hit, back out of the encoding above. Only ever call
    // these on a hit that is not HIT_NONE.
    function hitRow(hit as Number) as Number {
        return (hit - 1) / 2;
    }

    function hitIsIncrease(hit as Number) as Boolean {
        return (hit % 2) == 0;
    }

    // Half the usable width of a round screen at vertical position y, measured
    // from the vertical centre line. Returns 0 for a y outside the circle.
    //
    // For a circle of radius r centred on the display, the half-chord at
    // vertical distance dy from the centre is sqrt(r^2 - dy^2).
    function halfChordAt(y as Number, width as Number, height as Number) as Number {
        var r = width / 2.0;
        var dy = (y - (height / 2.0)).abs();
        if (dy >= r) {
            return 0;
        }
        return Math.sqrt((r * r) - (dy * dy)).toNumber();
    }

    // True when a horizontally centred line of text is fully on screen.
    //
    // y is the top edge of the glyph box, textWidth its width in pixels. Both
    // the top and bottom edge of the box are checked because whichever sits
    // further from the vertical centre has the tighter chord.
    function fitsOnRoundScreen(
        y as Number,
        textWidth as Number,
        fontHeight as Number,
        width as Number,
        height as Number
    ) as Boolean {
        if (y < 0 || (y + fontHeight) > height) {
            return false;
        }

        var topHalf = halfChordAt(y, width, height);
        var bottomHalf = halfChordAt(y + fontHeight, width, height);
        var tightest = topHalf < bottomHalf ? topHalf : bottomHalf;

        return (textWidth / 2) <= tightest;
    }
}
