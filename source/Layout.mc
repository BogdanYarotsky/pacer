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

    const EDITOR_FIRST_ROW_TOP = 96;
    const EDITOR_ROW_HEIGHT = 72;
    const EDITOR_ROW_COUNT = 3;

    // The controls are drawn as large as the glass allows. A circle at
    // (inset, rowCenter) fits the round screen iff
    //     sqrt((195 - inset)^2 + (rowCenter - 195)^2) + radius <= 195
    // and the outer rows are the binding case: at inset 58, radius 32, rows 0
    // and 2 sit 159.15 + 32 = 191.15 from centre against the 195 radius --
    // 3.85 px of air. Radius 32 at the old inset 55 left 1.25 px, which
    // antialiasing visibly clips; 34 needs inset 60 and starves the text
    // budget. layoutRealLinesFitOnVivoactive5 holds this with the real
    // circle-in-circle arithmetic, not the chord approximation it replaced.
    const CONTROL_INSET = 58;
    const CONTROL_RADIUS = 32;

    // The tap zone reaches as far inward as the widest row line allows: the
    // centre text must stay inert (reading a value can never change it), so
    // the zone edge stops short of "EVERY 14.95s" -- measured at 168 px, left
    // edge x=111, which is what pushed a hoped-for 113 back to 110.
    // layoutHitZonesClearRealisticText is the guardrail that pins this
    // constant to that measurement; its failure message says how far back the
    // edge must go.
    const CONTROL_HIT_EDGE = 110;

    // Clearance either side of a row's centred text, between it and the "-" and
    // "+" circles. See editorTextMaxWidth.
    const EDITOR_TEXT_GUTTER = 10;

    // Clearance from the bottom edge for the version line, which is positioned
    // from its measured font height rather than a fixed offset: the original
    // code used offsets of 74/46/24 from the bottom, i.e. gaps of 28 and 22 px,
    // while the fonts are 48-54 px tall. Every line overlapped the one above it
    // and all three were clipped by the curve of the display.
    const VERSION_BOTTOM_MARGIN = 34;

    // editorActionAt encodes its result as (row * 2) + direction, so these must
    // stay contiguous and in this order, decrease before increase. All six are
    // pinned by the tap-hit-mapping tests in tests/LayoutTest.mc.
    //
    // **The order of this block IS the order of the rows on screen**, which is
    // EVERY, PULSE, POWER -- the interval leads because it is the setting, the
    // cue's shape follows. The names are the on-screen captions, not the code's
    // setting names: pacerDelegate is where PULSE maps to duration and POWER to
    // strength. pacerView draws in this same order and pacerDelegate dispatches
    // by name, so re-ordering the screen means editing this block and the draw
    // calls together. If they ever disagree, every tap edits the wrong setting
    // and nothing on screen says so.
    const ACTION_NONE = 0;
    const ACTION_EVERY_DOWN = 1;
    const ACTION_EVERY_UP = 2;
    const ACTION_PULSE_DOWN = 3;
    const ACTION_PULSE_UP = 4;
    const ACTION_POWER_DOWN = 5;
    const ACTION_POWER_UP = 6;

    const DIRECTION_DECREASE = 1;
    const DIRECTION_INCREASE = 2;

    function centerX(width as Number) as Number {
        return width / 2;
    }

    // Top edge of the clock line, given the height of the font it will be drawn
    // in. The clock has the whole band above the first editor row to itself and
    // sits centred in it, so a taller font grows away from both neighbours
    // instead of walking into the row below.
    //
    // Centred, and not pinned near the top edge: this is a round screen, and the
    // usable chord at y=12 is only ~134 px against ~176 px at y=21. The clock is
    // set in the largest font on the screen, so it wants the wider line.
    function clockY(fontHeight as Number) as Number {
        return (EDITOR_FIRST_ROW_TOP - fontHeight) / 2;
    }

    function editorRowTop(index as Number) as Number {
        return EDITOR_FIRST_ROW_TOP + (index * EDITOR_ROW_HEIGHT);
    }

    // A row is one line, vertically centred here -- the caption and value sit
    // together on it, and the "-" and "+" circles share the same centre line.
    function editorRowCenter(index as Number) as Number {
        return editorRowTop(index) + (EDITOR_ROW_HEIGHT / 2);
    }

    function editorControlX(width as Number, increase as Boolean) as Number {
        return increase ? width - CONTROL_INSET : CONTROL_INSET;
    }

    // Widest a row's centred label or value may be drawn.
    //
    // The round-screen chord is not the only thing a row can run out of, and it
    // is the more forgiving of the two: an editor row sits near the vertical
    // centre where the glass is widest, but it also has a circle parked at each
    // end of it. A line long enough to reach one draws straight through it.
    //
    // That is not hypothetical. "5.22 sec (5.75 bpm)" measured 239 px in
    // FONT_XTINY against the 232 px between the two circles, and cleared every
    // chord check on the screen while sitting on top of both controls. The
    // gutter is what keeps a line that only just misses them from reading as if
    // it touches -- the layout it replaced had about 12 px of air each side.
    function editorTextMaxWidth(width as Number) as Number {
        return width - (2 * (CONTROL_INSET + CONTROL_RADIUS + EDITOR_TEXT_GUTTER));
    }

    // Top edge of the bottom-anchored version line, given the height of the font
    // it will be drawn in. Taking the measured height is what keeps the line
    // clear of the bottom edge whatever font the device ships.
    function versionY(height as Number, fontHeight as Number) as Number {
        return height - VERSION_BOTTOM_MARGIN - fontHeight;
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
