import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Lang;
import Toybox.Math;
import Toybox.System;

// Display states
enum {
    VIEW_STATE_INIT,
    VIEW_STATE_ACQUIRING_GPS,
    VIEW_STATE_SEARCHING,
    VIEW_STATE_SHOWING_RESULT,
    VIEW_STATE_NO_GPS,
    VIEW_STATE_NO_CONNECTION,
    VIEW_STATE_NO_RESULTS,
    VIEW_STATE_ERROR
}

class WasserstelleView extends WatchUi.View {

    private var _locationService as LocationService?;
    private var _overpassService as OverpassService?;
    private var _viewState as Number;
    private var _bearing as Float;
    private var _distance as Float;
    private var _cardinal as String;
    private var _useMetric as Boolean;
    private var _useTestMode as Boolean;
    private var _fountainLat as Double;
    private var _fountainLon as Double;
    private var _currentIndex as Number;
    private var _totalFountains as Number;

    // Test mode coordinates (Munich city center)
    private const TEST_LAT = 48.137d;
    private const TEST_LON = 11.576d;

    function initialize() {
        View.initialize();
        _viewState = VIEW_STATE_INIT;
        _bearing = 0.0f;
        _distance = 0.0f;
        _cardinal = "N";
        _useMetric = true;
        _useTestMode = true;  // Set to true for simulator testing, false for real device
        _fountainLat = 0.0d;
        _fountainLon = 0.0d;
        _currentIndex = 0;
        _totalFountains = 0;
    }

    // Set services from app
    function setServices(locationService as LocationService, overpassService as OverpassService) as Void {
        _locationService = locationService;
        _overpassService = overpassService;
    }

    // Called when this View is brought to the foreground
    function onShow() as Void {
        // Check device settings for metric/imperial
        var settings = System.getDeviceSettings();
        _useMetric = (settings.distanceUnits == System.UNIT_METRIC);

        if (_viewState == VIEW_STATE_INIT) {
            _viewState = VIEW_STATE_ACQUIRING_GPS;
            startLocationSearch();
        }
    }

    // Start GPS listening
    function startLocationSearch() as Void {
        // Test mode: skip GPS and use hardcoded Munich position
        if (_useTestMode) {
            _viewState = VIEW_STATE_SEARCHING;
            WatchUi.requestUpdate();
            if (_overpassService != null) {
                _overpassService.fetchNearbyWater(TEST_LAT, TEST_LON, method(:onSearchComplete));
            }
            return;
        }

        _viewState = VIEW_STATE_ACQUIRING_GPS;
        if (_locationService != null) {
            _locationService.startListening(method(:onLocationUpdate));
        }
        WatchUi.requestUpdate();
    }

    // Called when location is updated
    function onLocationUpdate() as Void {
        if (_locationService != null && _locationService.hasPosition()) {
            // Got GPS, now search for water
            _viewState = VIEW_STATE_SEARCHING;
            WatchUi.requestUpdate();

            if (_overpassService != null) {
                var lat = _locationService.getLatitude();
                var lon = _locationService.getLongitude();
                if (lat != null && lon != null) {
                    _overpassService.fetchNearbyWater(lat, lon, method(:onSearchComplete));
                }
            }
        }
    }

    // Called when Overpass search completes
    function onSearchComplete() as Void {
        if (_overpassService == null) {
            _viewState = VIEW_STATE_ERROR;
            WatchUi.requestUpdate();
            return;
        }

        var state = _overpassService.getState();

        if (state == OverpassService.STATE_SUCCESS) {
            _currentIndex = 0;
            _totalFountains = _overpassService.getFountainCount();
            updateCurrentFountain();
        } else if (state == OverpassService.STATE_NO_RESULTS) {
            _viewState = VIEW_STATE_NO_RESULTS;
        } else if (state == OverpassService.STATE_ERROR_NETWORK) {
            _viewState = VIEW_STATE_NO_CONNECTION;
        } else {
            _viewState = VIEW_STATE_ERROR;
        }

        WatchUi.requestUpdate();
    }

    // Trigger manual refresh
    function refresh() as Void {
        if (_overpassService != null) {
            _overpassService.reset();
        }
        _currentIndex = 0;
        startLocationSearch();
    }

    // Update display for current fountain index
    private function updateCurrentFountain() as Void {
        if (_overpassService == null) {
            return;
        }

        var fountains = _overpassService.getFountains();
        if (fountains == null || fountains.size() == 0) {
            _viewState = VIEW_STATE_NO_RESULTS;
            WatchUi.requestUpdate();
            return;
        }

        var fountain = fountains[_currentIndex];
        var lat = _useTestMode ? TEST_LAT : (_locationService != null ? _locationService.getLatitude() : null);
        var lon = _useTestMode ? TEST_LON : (_locationService != null ? _locationService.getLongitude() : null);

        if (lat != null && lon != null) {
            var bearingVal = GeoMath.calculateBearing(lat, lon, fountain.lat, fountain.lon);
            _bearing = bearingVal.toFloat();
            _distance = fountain.distance;
            _cardinal = GeoMath.bearingToCardinal(bearingVal);
            _fountainLat = fountain.lat;
            _fountainLon = fountain.lon;
            _viewState = VIEW_STATE_SHOWING_RESULT;
        }

        WatchUi.requestUpdate();
    }

    // Navigate to next fountain
    function nextFountain() as Void {
        if (_totalFountains > 0) {
            _currentIndex = (_currentIndex + 1) % _totalFountains;
            updateCurrentFountain();
        }
    }

    // Navigate to previous fountain
    function previousFountain() as Void {
        if (_totalFountains > 0) {
            _currentIndex = _currentIndex - 1;
            if (_currentIndex < 0) {
                _currentIndex = _totalFountains - 1;
            }
            updateCurrentFountain();
        }
    }

    // Get current fountain coordinates for navigation
    function getCurrentFountainCoords() as Dictionary? {
        if (_viewState != VIEW_STATE_SHOWING_RESULT) {
            return null;
        }
        return {
            :lat => _fountainLat,
            :lon => _fountainLon
        };
    }

    // Update the view
    function onUpdate(dc as Dc) as Void {
        // Clear screen
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();

        var width = dc.getWidth();
        var height = dc.getHeight();
        var centerX = width / 2;
        var centerY = height / 2;

        switch (_viewState) {
            case VIEW_STATE_INIT:
            case VIEW_STATE_ACQUIRING_GPS:
                drawMessage(dc, WatchUi.loadResource(Rez.Strings.AcquiringGPS) as String);
                break;

            case VIEW_STATE_SEARCHING:
                drawMessage(dc, WatchUi.loadResource(Rez.Strings.Searching) as String);
                break;

            case VIEW_STATE_SHOWING_RESULT:
                drawCompass(dc, centerX, centerY);
                break;

            case VIEW_STATE_NO_GPS:
                drawMessage(dc, WatchUi.loadResource(Rez.Strings.NoGPS) as String);
                break;

            case VIEW_STATE_NO_CONNECTION:
                var errCode = (_overpassService != null) ? _overpassService.getLastErrorCode() : 0;
                drawMessage(dc, "No Connection (" + errCode + ")");
                break;

            case VIEW_STATE_NO_RESULTS:
                drawMessage(dc, WatchUi.loadResource(Rez.Strings.NoneFound) as String);
                break;

            case VIEW_STATE_ERROR:
                drawMessage(dc, WatchUi.loadResource(Rez.Strings.ServiceError) as String);
                break;
        }
    }

    // Draw centered message
    private function drawMessage(dc as Dc, message as String) as Void {
        var width = dc.getWidth();
        var height = dc.getHeight();

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            width / 2,
            height / 2,
            Graphics.FONT_MEDIUM,
            message,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );
    }

    // Draw compass arrow pointing to nearest fountain
    private function drawCompass(dc as Dc, centerX as Number, centerY as Number) as Void {
        var width = dc.getWidth();
        var height = dc.getHeight();

        // Title with menu hint
        dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            centerX,
            15,
            Graphics.FONT_SMALL,
            WatchUi.loadResource(Rez.Strings.Water) as String,
            Graphics.TEXT_JUSTIFY_CENTER
        );

        // Menu hint
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            centerX,
            35,
            Graphics.FONT_XTINY,
            "MENU to navigate",
            Graphics.TEXT_JUSTIFY_CENTER
        );

        // Draw compass arrow
        var arrowSize = 40;
        var arrowY = centerY - 10;

        // Calculate arrow bearing: relative if heading available, absolute otherwise
        var displayBearing = _bearing;
        var currentlyHasHeading = false;

        // Read current heading fresh from LocationService for responsive updates
        if (_locationService != null && _locationService.hasHeading()) {
            var currentHeading = _locationService.getHeading();
            if (currentHeading != null) {
                currentlyHasHeading = true;
                displayBearing = GeoMath.calculateRelativeBearing(_bearing, currentHeading);
            }
        }

        drawArrow(dc, centerX, arrowY, arrowSize, displayBearing, currentlyHasHeading);

        // Heading mode indicator and cardinal direction
        if (currentlyHasHeading) {
            // Relative mode: show "REL" indicator in top-left
            dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
            dc.drawText(
                10,
                20,
                Graphics.FONT_XTINY,
                "REL",
                Graphics.TEXT_JUSTIFY_LEFT
            );
            // Still show cardinal direction (absolute direction to fountain)
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(
                centerX,
                arrowY + arrowSize + 10,
                Graphics.FONT_SMALL,
                _cardinal,
                Graphics.TEXT_JUSTIFY_CENTER
            );
        } else {
            // Absolute mode: cardinal direction is primary
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(
                centerX,
                arrowY + arrowSize + 10,
                Graphics.FONT_MEDIUM,
                _cardinal,
                Graphics.TEXT_JUSTIFY_CENTER
            );
        }

        // Distance
        var distanceStr = GeoMath.formatDistance(_distance.toDouble(), _useMetric);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            centerX,
            height - 45,
            Graphics.FONT_LARGE,
            distanceStr,
            Graphics.TEXT_JUSTIFY_CENTER
        );

        // Fountain index (e.g., "1/5")
        if (_totalFountains > 1) {
            dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
            var indexStr = (_currentIndex + 1).toString() + "/" + _totalFountains.toString();
            dc.drawText(
                width - 25,
                20,
                Graphics.FONT_SMALL,
                indexStr,
                Graphics.TEXT_JUSTIFY_CENTER
            );
        }

        // Fountain coordinates
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        var coordStr = _fountainLat.format("%.4f") + ", " + _fountainLon.format("%.4f");
        dc.drawText(
            centerX,
            height - 15,
            Graphics.FONT_XTINY,
            coordStr,
            Graphics.TEXT_JUSTIFY_CENTER
        );

    }

    // Draw rotated arrow pointing in bearing direction
    // isRelative: true if using heading-relative bearing, false for absolute
    private function drawArrow(dc as Dc, x as Number, y as Number, size as Number, bearing as Float, isRelative as Boolean) as Void {
        var radians = Math.toRadians(bearing);

        // Arrow points (triangle pointing up, then rotated)
        var tipX = x + (size * Math.sin(radians)).toNumber();
        var tipY = y - (size * Math.cos(radians)).toNumber();

        var leftAngle = radians - 2.5;
        var rightAngle = radians + 2.5;
        var baseSize = size * 0.6;

        var leftX = x + (baseSize * Math.sin(leftAngle)).toNumber();
        var leftY = y - (baseSize * Math.cos(leftAngle)).toNumber();

        var rightX = x + (baseSize * Math.sin(rightAngle)).toNumber();
        var rightY = y - (baseSize * Math.cos(rightAngle)).toNumber();

        // Draw filled triangle - green for relative, blue for absolute
        var fillColor = isRelative ? Graphics.COLOR_GREEN : Graphics.COLOR_BLUE;
        var outlineColor = isRelative ? Graphics.COLOR_DK_GREEN : Graphics.COLOR_DK_BLUE;
        dc.setColor(fillColor, Graphics.COLOR_TRANSPARENT);
        var points = [[tipX, tipY], [leftX, leftY], [x, y], [rightX, rightY]];
        dc.fillPolygon(points);

        // Draw outline
        dc.setColor(outlineColor, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(tipX, tipY, leftX, leftY);
        dc.drawLine(leftX, leftY, x, y);
        dc.drawLine(x, y, rightX, rightY);
        dc.drawLine(rightX, rightY, tipX, tipY);
    }

    // Called when this View is removed from the screen
    function onHide() as Void {
        if (_locationService != null) {
            _locationService.stopListening();
        }
    }
}
