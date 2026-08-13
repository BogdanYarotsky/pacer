import Toybox.Lang;
import Toybox.Math;

// Pure layout math for the main Pacer screen.
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
    const CLOCK_FROM_TOP = 12;
    const STATUS_FROM_TOP = 65;
    const EDITOR_FIRST_ROW_TOP = 96;
    const EDITOR_ROW_HEIGHT = 72;
    const EDITOR_ROW_COUNT = 3;
    const CONTROL_INSET = 55;
    const CONTROL_RADIUS = 24;
    const CONTROL_HIT_EDGE = 110;

    const ACTION_NONE = 0;
    const ACTION_PACE_DOWN = 1;
    const ACTION_PACE_UP = 2;
    const ACTION_STRENGTH_DOWN = 3;
    const ACTION_STRENGTH_UP = 4;
    const ACTION_DURATION_DOWN = 5;
    const ACTION_DURATION_UP = 6;

    // Clearance from the bottom edge for the info stack, and the gap between
    // its lines. The stack is positioned from measured font heights rather than
    // fixed per-line offsets: the original code used offsets of 74/46/24 from
    // the bottom, i.e. gaps of 28 and 22 px, while the fonts are 48-54 px tall.
    // Every line overlapped the one above it and all three were clipped by the
    // curve of the display.
    const STACK_BOTTOM_MARGIN = 34;
    const STACK_LINE_GAP      = 2;

    function centerX(width as Number) as Number {
        return width / 2;
    }

    function clockY() as Number {
        return CLOCK_FROM_TOP;
    }

    function statusY() as Number {
        return STATUS_FROM_TOP;
    }

    function editorRowTop(index as Number) as Number {
        return EDITOR_FIRST_ROW_TOP + (index * EDITOR_ROW_HEIGHT);
    }

    function editorRowCenter(index as Number) as Number {
        return editorRowTop(index) + (EDITOR_ROW_HEIGHT / 2);
    }

    function editorLabelY(index as Number) as Number {
        return editorRowTop(index) + 3;
    }

    function editorValueY(index as Number) as Number {
        return editorRowTop(index) + 35;
    }

    function editorControlX(width as Number, increase as Boolean) as Number {
        return increase ? width - CONTROL_INSET : CONTROL_INSET;
    }

    // Map only the large edge hit zones to an action. The centre text is not
    // interactive, preventing an accidental adjustment while reading a value.
    function editorActionAt(x as Number, y as Number, width as Number) as Number {
        if (y < EDITOR_FIRST_ROW_TOP ||
                y >= EDITOR_FIRST_ROW_TOP + (EDITOR_ROW_COUNT * EDITOR_ROW_HEIGHT)) {
            return ACTION_NONE;
        }

        var direction = 0;
        if (x <= CONTROL_HIT_EDGE) {
            direction = 1;
        } else if (x >= width - CONTROL_HIT_EDGE) {
            direction = 2;
        } else {
            return ACTION_NONE;
        }

        var row = ((y - EDITOR_FIRST_ROW_TOP) / EDITOR_ROW_HEIGHT).toNumber();
        return (row * 2) + direction;
    }

    // Top-edge y for each line of a bottom-anchored stack, in reading order.
    //
    // Takes the height of each line's font, so lines can never overlap by
    // construction -- the gap between consecutive baselines is always at least
    // the font height. Callers pass the heights they are actually going to draw
    // with, measured from the Dc.
    function stackFromBottom(height as Number, fontHeights as Array<Number>) as Array<Number> {
        var count = fontHeights.size();
        var total = STACK_LINE_GAP * (count - 1);
        for (var i = 0; i < count; i += 1) {
            total += fontHeights[i];
        }

        var y = height - STACK_BOTTOM_MARGIN - total;
        var ys = [] as Array<Number>;
        for (var i = 0; i < count; i += 1) {
            ys.add(y);
            y += fontHeights[i] + STACK_LINE_GAP;
        }
        return ys;
    }

    // Half the usable width of a round screen at vertical position y, measured
    // from the vertical centre line. Returns 0 for a y outside the circle.
    //
    // For a circle of radius r centred on the display, the half-chord at
    // vertical distance dy from the centre is sqrt(r^2 - dy^2).
    function halfChordAt(y as Number, width as Number, height as Number) as Number {
        var r = width / 2.0;
        var dy = y - (height / 2.0);
        if (dy < 0) { dy = -dy; }
        if (dy >= r) { return 0; }
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

        var topHalf    = halfChordAt(y, width, height);
        var bottomHalf = halfChordAt(y + fontHeight, width, height);
        var tightest   = topHalf;
        if (bottomHalf < tightest) { tightest = bottomHalf; }

        return (textWidth / 2) <= tightest;
    }
}
