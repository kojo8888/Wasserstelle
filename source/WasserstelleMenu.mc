import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.System;
import Toybox.PersistedContent;
import Toybox.Position;

// Menu for navigation options
class WasserstelleMenu extends WatchUi.Menu2 {

    function initialize() {
        Menu2.initialize({:title => "Options"});
        addItem(new WatchUi.MenuItem("Navigate", "Start routing", :navigate, null));
        addItem(new WatchUi.MenuItem("Save Waypoint", "Save location", :save, null));
    }
}

// Menu delegate to handle menu selections
class WasserstelleMenuDelegate extends WatchUi.Menu2InputDelegate {

    private var _view as WasserstelleView;

    function initialize(view as WasserstelleView) {
        Menu2InputDelegate.initialize();
        _view = view;
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var id = item.getId();

        if (id == :navigate) {
            navigateToFountain();
        } else if (id == :save) {
            saveWaypointOnly();
        }

        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }

    // Navigate to the current fountain using device's built-in navigation
    private function navigateToFountain() as Void {
        var coords = _view.getCurrentFountainCoords();
        if (coords == null) {
            return;
        }

        var lat = coords[:lat] as Double;
        var lon = coords[:lon] as Double;

        // Create a Position.Location for the fountain
        var location = new Position.Location({
            :latitude => lat,
            :longitude => lon,
            :format => :degrees
        });

        try {
            // Save waypoint first
            PersistedContent.saveWaypoint(location, {:name => "Water Fountain"});

            // Get the waypoints and find the one we just saved
            var iterator = PersistedContent.getAppWaypoints();
            if (iterator != null) {
                var waypoint = iterator.next();
                if (waypoint != null) {
                    // Exit to device navigation with this waypoint
                    System.exitTo(waypoint.toIntent());
                }
            }
        } catch (e) {
            System.println("Navigation error");
        }
    }

    // Save the fountain as a waypoint without navigating
    private function saveWaypointOnly() as Void {
        var coords = _view.getCurrentFountainCoords();
        if (coords == null) {
            return;
        }

        var lat = coords[:lat] as Double;
        var lon = coords[:lon] as Double;

        var location = new Position.Location({
            :latitude => lat,
            :longitude => lon,
            :format => :degrees
        });

        try {
            PersistedContent.saveWaypoint(location, {:name => "Water Fountain"});
            System.println("Waypoint saved!");
        } catch (e) {
            System.println("Save error");
        }
    }
}
