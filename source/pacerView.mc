import Toybox.Graphics;
import Toybox.WatchUi;

class pacerView extends WatchUi.View {

    function initialize() {
        View.initialize();
    }

    // Load your resources here
    function onLayout(dc as Dc) as Void {
        setLayout(Rez.Layouts.MainLayout(dc));
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() as Void {
    }

    // Update the view
    function onUpdate(dc as Dc) as Void {
        View.onUpdate(dc);

        // All coordinates come from Layout, which is pure and unit tested
        // against the real 390x390 round geometry. Do not reintroduce literal
        // offsets here -- see tests/LayoutTest.mc.
        var width = dc.getWidth();
        var height = dc.getHeight();
        var center = Layout.centerX(width);
        var app = getApp();

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            center,
            Layout.versionY(),
            Graphics.FONT_MEDIUM,
            "v" + app.APP_VERSION,
            Graphics.TEXT_JUSTIFY_CENTER
        );

        // The info stack is laid out from the fonts' real heights so the lines
        // cannot overlap and stay inside the curve of the round display. The
        // fonts are deliberately small: at this height the usable width of a
        // 390px round screen is well under 390px. See tests/LayoutTest.mc.
        var paceFont = Graphics.FONT_TINY;
        var subFont = Graphics.FONT_XTINY;
        var ys = Layout.stackFromBottom(height, [
            dc.getFontHeight(paceFont),
            dc.getFontHeight(subFont),
            dc.getFontHeight(subFont)
        ]);

        dc.drawText(center, ys[0], paceFont, app.getPaceText(), Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(center, ys[1], subFont, app.getIntervalText(), Graphics.TEXT_JUSTIFY_CENTER);
        // Shortened from "Top button: settings / exit" (310px): the bottom of a
        // round 390px screen only offers ~220px, so the original was clipped at
        // both ends. The menu itself still says "Exit Pacer".
        dc.drawText(center, ys[2], subFont, "Top button: menu", Graphics.TEXT_JUSTIFY_CENTER);
    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() as Void {
    }

}
