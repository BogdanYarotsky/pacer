import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Attention;
import Toybox.Timer;

using Toybox.Sensor;

class pacerApp extends Application.AppBase {
    const bpm = 5.71; // todo
    const _interval = 5254;
    const _vibeStrength = 15;
    const _vibeDuration = 170;

    var _timer;

    function initialize() {
        AppBase.initialize();
    }

    // onStart() is called on application start up
    function onStart(state as Dictionary?) as Void {
        if (_timer == null) {
            _timer = new Timer.Timer();
            // var interval = 6000 / bpm / 2;
            _timer.start(method(:timerCallback), interval, true);
        }
    }

    // Timer callback function
    function timerCallback() as Void {
        var vibe = [
            new Attention.VibeProfile(_vibeStrength, _vibeDuration)
        ];
        Attention.vibrate(vibe);
    }

    // onStop() is called when your application is exiting
    function onStop(state as Dictionary?) as Void {
        if (_timer != null) {
            _timer.stop();
            _timer = null;
        }
    }

    // Return the initial view of your application here
    function getInitialView() as [Views] or [Views, InputDelegates] {
        return [ new pacerView(), new pacerDelegate() ];
    }
}

function getApp() as pacerApp {
    return Application.getApp() as pacerApp;
}