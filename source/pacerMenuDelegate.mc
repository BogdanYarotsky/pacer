import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

function showPacerSettings() as Void {
    var app = getApp();
    var menu = new WatchUi.Menu2({ :title => "Pacer settings" });

    menu.addItem(new WatchUi.MenuItem(
        "Breathing pace",
        app.getPaceText(),
        "pace",
        {}
    ));
    menu.addItem(new WatchUi.MenuItem(
        "Vibration strength",
        app.getStrengthText(),
        "strength",
        {}
    ));
    menu.addItem(new WatchUi.MenuItem(
        "Vibration length",
        app.getDurationText(),
        "duration",
        {}
    ));
    menu.addItem(new WatchUi.MenuItem(
        "Exit Pacer",
        "Stop all pacing cues",
        "exit",
        {}
    ));

    WatchUi.pushView(menu, new pacerMenuDelegate(), WatchUi.SLIDE_UP);
}

class pacerMenuDelegate extends WatchUi.Menu2InputDelegate {

    function initialize() {
        Menu2InputDelegate.initialize();
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var identifier = item.getId();
        var app = getApp();

        if ("pace".equals(identifier)) {
            openPicker(
                item,
                identifier,
                "Breaths per minute",
                app.MIN_PACE_HUNDREDTHS,
                app.MAX_PACE_HUNDREDTHS,
                1,
                app.getPaceHundredths(),
                pacerValuePickerFactory::FORMAT_PACE
            );
        } else if ("strength".equals(identifier)) {
            openPicker(
                item,
                identifier,
                "Vibration strength",
                app.MIN_VIBE_STRENGTH,
                app.MAX_VIBE_STRENGTH,
                5,
                app.getVibrationStrength(),
                pacerValuePickerFactory::FORMAT_PERCENT
            );
        } else if ("duration".equals(identifier)) {
            openPicker(
                item,
                identifier,
                "Vibration length",
                app.MIN_VIBE_DURATION,
                app.MAX_VIBE_DURATION,
                10,
                app.getVibrationDuration(),
                pacerValuePickerFactory::FORMAT_MILLISECONDS
            );
        } else if ("exit".equals(identifier)) {
            System.exit();
        }
    }

    private function openPicker(item, identifier, titleText, minimum, maximum, step, current, format) as Void {
        var title = new WatchUi.Text({
            :text => titleText,
            :locX => WatchUi.LAYOUT_HALIGN_CENTER,
            :locY => WatchUi.LAYOUT_VALIGN_BOTTOM,
            :color => Graphics.COLOR_WHITE,
            :font => Graphics.FONT_SMALL,
            :justification => Graphics.TEXT_JUSTIFY_CENTER
        });
        var factory = new pacerValuePickerFactory(minimum, maximum, step, format);
        var picker = new WatchUi.Picker({
            :title => title,
            :pattern => [ factory ],
            :defaults => [ factory.getIndex(current) ]
        });

        WatchUi.pushView(
            picker,
            new pacerPickerDelegate(identifier, item),
            WatchUi.SLIDE_UP
        );
    }
}

class pacerValuePickerFactory extends WatchUi.PickerFactory {
    const FORMAT_PACE = 0;
    const FORMAT_PERCENT = 1;
    const FORMAT_MILLISECONDS = 2;

    var _minimum;
    var _maximum;
    var _step;
    var _format;

    function initialize(minimum, maximum, step, format) {
        PickerFactory.initialize();
        _minimum = minimum;
        _maximum = maximum;
        _step = step;
        _format = format;
    }

    function getSize() {
        return ((_maximum - _minimum) / _step).toNumber() + 1;
    }

    function getValue(item) {
        return _minimum + (item * _step);
    }

    function getIndex(value) {
        return ((value - _minimum) / _step).toNumber();
    }

    function getDrawable(item, isSelected) {
        return new WatchUi.Text({
            :text => formatValue(getValue(item)),
            :color => Graphics.COLOR_WHITE,
            :font => Graphics.FONT_LARGE,
            :justification => Graphics.TEXT_JUSTIFY_CENTER
        });
    }

    private function formatValue(value) {
        if (_format == FORMAT_PACE) {
            var whole = (value / 100).toNumber();
            var fraction = value % 100;
            var fractionText = fraction.toString();
            if (fraction < 10) {
                fractionText = "0" + fractionText;
            }
            return whole.toString() + "." + fractionText + "/min";
        } else if (_format == FORMAT_PERCENT) {
            return value.toString() + "%";
        }

        return value.toString() + " ms";
    }
}

class pacerPickerDelegate extends WatchUi.PickerDelegate {
    var _identifier;
    var _menuItem;

    function initialize(identifier, menuItem) {
        PickerDelegate.initialize();
        _identifier = identifier;
        _menuItem = menuItem;
    }

    function onAccept(values as Array) as Boolean {
        var app = getApp();
        var value = values[0];

        if ("pace".equals(_identifier)) {
            app.setPaceHundredths(value);
            _menuItem.setSubLabel(app.getPaceText());
        } else if ("strength".equals(_identifier)) {
            app.setVibrationStrength(value);
            _menuItem.setSubLabel(app.getStrengthText());
        } else if ("duration".equals(_identifier)) {
            app.setVibrationDuration(value);
            _menuItem.setSubLabel(app.getDurationText());
        }

        WatchUi.popView(WatchUi.SLIDE_DOWN);
        return true;
    }

    function onCancel() as Boolean {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        return true;
    }
}
