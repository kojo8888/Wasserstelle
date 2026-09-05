import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

class WasserstelleApp extends Application.AppBase {

    private var _locationService as LocationService?;
    private var _overpassService as OverpassService?;

    function initialize() {
        AppBase.initialize();
    }

    // onStart() is called on application start up
    function onStart(state as Dictionary?) as Void {
        _locationService = new LocationService();
        _overpassService = new OverpassService();
    }

    // onStop() is called when your application is exiting
    function onStop(state as Dictionary?) as Void {
        if (_locationService != null) {
            _locationService.stopListening();
        }
    }

    // Return the initial view of your application here
    function getInitialView() as [Views] or [Views, InputDelegates] {
        var view = new WasserstelleView();

        if (_locationService != null && _overpassService != null) {
            view.setServices(_locationService, _overpassService);
        }

        var delegate = new WasserstelleDelegate(view);

        return [view, delegate];
    }
}

function getApp() as WasserstelleApp {
    return Application.getApp() as WasserstelleApp;
}
