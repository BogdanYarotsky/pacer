import Toybox.Lang;
import Toybox.Math;

// Pure layout maths. Nothing here touches a Dc, so all of it runs under the
// test runner and shots/*.png stay the last resort. ADR-0030
//
// The vivoactive 5 is a ROUND display: fitting the bounding box is not fitting
// the screen, and halfChordAt is why these tests are worth having. ADR-0011
//
// Both screens share every function here. What differs is one number -- how
// many rows they carry -- so the row grid takes that as an argument. This
// module never learns which setting is standing in a row. ADR-0028
module Layout {

    const DISPLAY_WIDTH = 390;

    // The row grid is CENTRED ON THE GLASS, and the controls are as large as
    // that allows. ADR-0012
    const EDITOR_ROW_HEIGHT = 102;
    const CONTROL_INSET = 54;
    const CONTROL_RADIUS = 38;

    // A ring, not a fill, and wide enough to read as a border rather than a
    // hairline. It is a Layout constant and not a view detail because the
    // circle-in-circle fit maths has to pay for it. ADR-0012
    const CONTROL_PEN = 3;

    // The "-" and "+" are drawn bars, not font glyphs. **Both extents must stay
    // ODD** -- an even one cannot centre on a pixel. ADR-0015
    const GLYPH_LENGTH = 27;
    const GLYPH_THICKNESS = 5;

    // How far in the tap zones reach. Derived from a measurement of the widest
    // reachable row line; the guardrail's failure message says where it must
    // go, which is how this has been set every time it moved. ADR-0014
    const CONTROL_HIT_EDGE = 104;

    // Clearance either side of a row's centred text, between it and the
    // circles. See editorTextMaxWidth. ADR-0013
    const EDITOR_TEXT_GUTTER = 10;

    // Clearance from the bottom edge, applied to a MEASURED font height rather
    // than as a fixed offset. ADR-0011
    const BOTTOM_SLOT_MARGIN = 34;

    // A POSITION and a side, and deliberately nothing about which setting is
    // standing there. ADR-0014
    const HIT_NONE = 0;
    const DIRECTION_DECREASE = 1;
    const DIRECTION_INCREASE = 2;

    // There was an isBackTap() here, mapping the band below the rows to the
    // settings screen's BACK button. ADR-0036 retired the button along with the
    // only thing on either screen that a tap outside a row could do; the band
    // is inert on both screens now, which is what editorHitAt already returned
    // for it. ADR-0014

    function centerX(width as Number) as Number {
        return width / 2;
    }

    function editorRowsTop(rowCount as Number, height as Number) as Number {
        return (height / 2) - ((rowCount * EDITOR_ROW_HEIGHT) / 2);
    }

    function editorRowTop(index as Number, rowCount as Number, height as Number) as Number {
        return editorRowsTop(rowCount, height) + (index * EDITOR_ROW_HEIGHT);
    }

    // A row is one line, and its "-" and "+" circles share the same centre.
    function editorRowCenter(index as Number, rowCount as Number, height as Number) as Number {
        return editorRowTop(index, rowCount, height) + (EDITOR_ROW_HEIGHT / 2);
    }

    // The band above the rows, centred: the clock on the main screen, the build
    // version on the settings screen. Taller fonts grow away from the rows
    // rather than into them, which a test asserts as a direction. ADR-0011
    function topSlotY(fontHeight as Number, rowsTop as Number) as Number {
        return (rowsTop - fontHeight) / 2;
    }

    function editorControlX(width as Number, increase as Boolean) as Number {
        return increase ? width - CONTROL_INSET : CONTROL_INSET;
    }

    // The leading edge of one arm of a control's glyph. All three bars come out
    // of this one function -- the "+" is the "-" with its extents swapped -- so
    // "centred" has one definition. ADR-0015
    function glyphArmStart(center as Number, extent as Number) as Number {
        return center - (extent / 2);
    }

    // The SECOND width budget: the chord is not the only thing a row runs out
    // of, and it is the more forgiving of the two. ADR-0013
    function editorTextMaxWidth(width as Number) as Number {
        return width - (2 * (CONTROL_INSET + CONTROL_RADIUS + EDITOR_TEXT_GUTTER));
    }

    // The band below the rows: the battery, warning or hint on the main screen,
    // and on the settings screen the same hint and nothing else. One anchor for
    // both, whose one geometric duty is to clear the bottom row's controls --
    // a test pins that. ADR-0005, ADR-0036
    function bottomSlotY(height as Number, fontHeight as Number) as Number {
        return height - BOTTOM_SLOT_MARGIN - fontHeight;
    }

    // Only the large edge zones map to a row; the centre stays inert so reading
    // a value can never change it. ADR-0014
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

    // Only ever call these on a hit that is not HIT_NONE.
    function hitRow(hit as Number) as Number {
        return (hit - 1) / 2;
    }

    function hitIsIncrease(hit as Number) as Boolean {
        return (hit % 2) == 0;
    }

    // Half the usable width at vertical position y, from the centre line. For a
    // circle of radius r the half-chord at distance dy is sqrt(r^2 - dy^2).
    // Returns 0 outside the circle. ADR-0011
    function halfChordAt(y as Number, width as Number, height as Number) as Number {
        var r = width / 2.0;
        var dy = (y - (height / 2.0)).abs();
        if (dy >= r) {
            return 0;
        }
        return Math.sqrt((r * r) - (dy * dy)).toNumber();
    }

    // True when a horizontally centred line is fully on screen. BOTH edges of
    // the glyph box are checked, because whichever sits further from the
    // vertical centre has the tighter chord. ADR-0011
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
