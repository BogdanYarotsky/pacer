import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

class pacerView extends WatchUi.View {

    function initialize() {
        View.initialize();
    }

    // Load your resources here
    function onLayout(dc as Dc) as Void {
        setLayout(Rez.Layouts.MainLayout(dc));
    }

    // Disable the platform's raw touch handling while the pacing screen is
    // visible. This is required to suppress the non-programmable palm-cover
    // exit gesture on the vivoactive 5.
    function onShow() as Void {
        TouchControl.setEnabled(false);
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

        // The idle main screen deliberately has no bottom text. The only text
        // shown here is the temporary exit confirmation after the first Back.
        if (app.isExitPromptVisible()) {
            var promptFont = Graphics.FONT_XTINY;
            var ys = Layout.stackFromBottom(height, [
                dc.getFontHeight(promptFont)
            ]);
            dc.drawText(
                center,
                ys[0],
                promptFont,
                app.getExitPromptText(),
                Graphics.TEXT_JUSTIFY_CENTER
            );
        }
    }

    // Best-effort lifecycle restoration. Controlled navigation and exit paths
    // restore earlier because this callback can be too late for the
    // foreground-only API.
    function onHide() as Void {
        TouchControl.setEnabled(true);
    }

}
