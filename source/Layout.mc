import Toybox.Lang;
import Toybox.Math;

// Pure layout maths for the main Pacer screen.
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
module Layout {

    const DISPLAY_WIDTH = 390;

    const CLOCK_Y = 12;
    const STATUS_Y = 65;

    const EDITOR_FIRST_ROW_TOP = 96;
    const EDITOR_ROW_HEIGHT = 72;
    const EDITOR_ROW_COUNT = 3;
    const EDITOR_LABEL_OFFSET = 3;
    const EDITOR_VALUE_OFFSET = 35;

    const CONTROL_INSET = 55;
    const CONTROL_RADIUS = 24;
    const CONTROL_HIT_EDGE = 110;

    // Clearance from the bottom edge for the footer line. The footer is
    // positioned from its measured font height rather than a fixed offset: the
    // original code used offsets of 74/46/24 from the bottom, i.e. gaps of 28
    // and 22 px, while the fonts are 48-54 px tall. Every line overlapped the
    // one above it and all three were clipped by the curve of the display.
    const FOOTER_BOTTOM_MARGIN = 34;

    // editorActionAt encodes its result as (row * 2) + direction, so these must
    // stay contiguous and in this order, decrease before increase. All six are
    // pinned by tests/EditorLayoutTest.mc.
    const ACTION_NONE = 0;
    const ACTION_PACE_DOWN = 1;
    const ACTION_PACE_UP = 2;
    const ACTION_STRENGTH_DOWN = 3;
    const ACTION_STRENGTH_UP = 4;
    const ACTION_DURATION_DOWN = 5;
    const ACTION_DURATION_UP = 6;

    const DIRECTION_DECREASE = 1;
    const DIRECTION_INCREASE = 2;

    function centerX(width as Number) as Number {
        return width / 2;
    }

    function editorRowTop(index as Number) as Number {
        return EDITOR_FIRST_ROW_TOP + (index * EDITOR_ROW_HEIGHT);
    }

    function editorRowCenter(index as Number) as Number {
        return editorRowTop(index) + (EDITOR_ROW_HEIGHT / 2);
    }

    function editorLabelY(index as Number) as Number {
        return editorRowTop(index) + EDITOR_LABEL_OFFSET;
    }

    function editorValueY(index as Number) as Number {
        return editorRowTop(index) + EDITOR_VALUE_OFFSET;
    }

    function editorControlX(width as Number, increase as Boolean) as Number {
        return increase ? width - CONTROL_INSET : CONTROL_INSET;
    }

    // Top edge of the bottom-anchored footer line, given the height of the font
    // it will be drawn in. Taking the measured height is what keeps the line
    // clear of the bottom edge whatever font the device ships.
    function footerY(height as Number, fontHeight as Number) as Number {
        return height - FOOTER_BOTTOM_MARGIN - fontHeight;
    }

    // Map only the large edge hit zones to an action. The centre text is not
    // interactive, preventing an accidental adjustment while reading a value.
    function editorActionAt(x as Number, y as Number, width as Number) as Number {
        if (y < EDITOR_FIRST_ROW_TOP ||
                y >= EDITOR_FIRST_ROW_TOP + (EDITOR_ROW_COUNT * EDITOR_ROW_HEIGHT)) {
            return ACTION_NONE;
        }

        var direction;
        if (x <= CONTROL_HIT_EDGE) {
            direction = DIRECTION_DECREASE;
        } else if (x >= width - CONTROL_HIT_EDGE) {
            direction = DIRECTION_INCREASE;
        } else {
            return ACTION_NONE;
        }

        // Number / Number is integer division in Monkey C, so this is the row
        // index directly.
        var row = (y - EDITOR_FIRST_ROW_TOP) / EDITOR_ROW_HEIGHT;
        return (row * 2) + direction;
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
