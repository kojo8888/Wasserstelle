import Toybox.Lang;
import Toybox.WatchUi;

// Input delegate for handling button presses
class WasserstelleDelegate extends WatchUi.BehaviorDelegate {

    private var _view as WasserstelleView;

    function initialize(view as WasserstelleView) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    // Handle SELECT button press - trigger refresh
    function onSelect() as Boolean {
        _view.refresh();
        return true;
    }

    // Handle UP button - previous fountain
    function onPreviousPage() as Boolean {
        _view.previousFountain();
        return true;
    }

    // Handle DOWN button - next fountain
    function onNextPage() as Boolean {
        _view.nextFountain();
        return true;
    }

    // Handle MENU button - show navigation options
    function onMenu() as Boolean {
        var menu = new WasserstelleMenu();
        var delegate = new WasserstelleMenuDelegate(_view);
        WatchUi.pushView(menu, delegate, WatchUi.SLIDE_UP);
        return true;
    }

    // Handle back button - exit widget
    function onBack() as Boolean {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        return true;
    }
}
