import Toybox.Lang;
import Toybox.Math;
import Toybox.Position;
import Toybox.System;

// GPS location service with state management
class LocationService {

    // State constants
    enum {
        STATE_WAITING,
        STATE_ACQUIRED,
        STATE_ERROR
    }

    private var _state as Number;
    private var _latitude as Double?;
    private var _longitude as Double?;
    private var _accuracy as Number?;
    private var _heading as Float?;
    private var _callback as Method?;

    function initialize() {
        _state = STATE_WAITING;
        _latitude = null;
        _longitude = null;
        _accuracy = null;
        _heading = null;
        _callback = null;
    }

    // Start listening for GPS position updates
    function startListening(callback as Method?) as Void {
        _callback = callback;
        _state = STATE_WAITING;

        Position.enableLocationEvents(Position.LOCATION_CONTINUOUS, method(:onPosition));
    }

    // Stop listening for GPS updates
    function stopListening() as Void {
        Position.enableLocationEvents(Position.LOCATION_DISABLE, method(:onPosition));
    }

    // Position callback
    function onPosition(info as Position.Info) as Void {
        if (info.position != null) {
            var coords = info.position.toDegrees();
            _latitude = coords[0].toDouble();
            _longitude = coords[1].toDouble();
            _accuracy = info.accuracy;
            _state = STATE_ACQUIRED;

            // Capture heading if available (in radians, convert to degrees)
            if (info.heading != null) {
                _heading = Math.toDegrees(info.heading).toFloat();
                // Normalize to 0-360
                if (_heading < 0) {
                    _heading = _heading + 360.0f;
                }
            }

            if (_callback != null) {
                _callback.invoke();
            }
        }
    }

    // Get current state
    function getState() as Number {
        return _state;
    }

    // Check if position is available
    function hasPosition() as Boolean {
        return _latitude != null && _longitude != null;
    }

    // Get latitude
    function getLatitude() as Double? {
        return _latitude;
    }

    // Get longitude
    function getLongitude() as Double? {
        return _longitude;
    }

    // Get accuracy level
    function getAccuracy() as Number? {
        return _accuracy;
    }

    // Check if heading is available
    function hasHeading() as Boolean {
        return _heading != null;
    }

    // Get heading in degrees (0-360, 0=North)
    function getHeading() as Float? {
        return _heading;
    }

    // Set error state
    function setError() as Void {
        _state = STATE_ERROR;
    }

    // Reset to waiting state
    function reset() as Void {
        _state = STATE_WAITING;
        _latitude = null;
        _longitude = null;
        _heading = null;
    }
}
