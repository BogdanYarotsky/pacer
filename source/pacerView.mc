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

        var center = (dc.getWidth() / 2).toNumber();
        var app = getApp();

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            center,
            18,
            Graphics.FONT_MEDIUM,
            "Pacer",
            Graphics.TEXT_JUSTIFY_CENTER
        );
        dc.drawText(
            center,
            dc.getHeight() - 74,
            Graphics.FONT_SMALL,
            app.getPaceText(),
            Graphics.TEXT_JUSTIFY_CENTER
        );
        dc.drawText(
            center,
            dc.getHeight() - 46,
            Graphics.FONT_XTINY,
            app.getIntervalText(),
            Graphics.TEXT_JUSTIFY_CENTER
        );
        dc.drawText(
            center,
            dc.getHeight() - 24,
            Graphics.FONT_XTINY,
            "Top button: settings / exit",
            Graphics.TEXT_JUSTIFY_CENTER
        );
    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() as Void {
    }

}
