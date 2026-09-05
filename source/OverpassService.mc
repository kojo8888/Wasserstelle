import Toybox.Lang;
import Toybox.Communications;
import Toybox.System;

// Fountain data structure
class Fountain {
    var lat as Double;
    var lon as Double;
    var name as String?;
    var distance as Float;

    function initialize(latitude as Double, longitude as Double, fountainName as String?) {
        lat = latitude;
        lon = longitude;
        name = fountainName;
        distance = 0.0f;
    }
}

// Overpass API service for fetching drinking water locations
class OverpassService {

    // State constants
    enum {
        STATE_IDLE,
        STATE_FETCHING,
        STATE_SUCCESS,
        STATE_ERROR_NETWORK,
        STATE_ERROR_PARSE,
        STATE_NO_RESULTS
    }

    // Search radius in degrees (~1km for faster/reliable API responses)
    private const SEARCH_RADIUS = 0.01;

    // Overpass API endpoint
    private const API_URL = "https://overpass-api.de/api/interpreter";

    private var _state as Number;
    private var _fountains as Array<Fountain>?;
    private var _nearestFountain as Fountain?;
    private var _callback as Method?;
    private var _searchLat as Double?;
    private var _searchLon as Double?;
    private var _lastErrorCode as Number;

    function initialize() {
        _state = STATE_IDLE;
        _fountains = null;
        _nearestFountain = null;
        _callback = null;
        _lastErrorCode = 0;
    }

    // Fetch nearby drinking water sources
    function fetchNearbyWater(lat as Double, lon as Double, callback as Method?) as Void {
        _callback = callback;
        _searchLat = lat;
        _searchLon = lon;
        _state = STATE_FETCHING;
        _fountains = null;
        _nearestFountain = null;

        var minLat = lat - SEARCH_RADIUS;
        var maxLat = lat + SEARCH_RADIUS;
        var minLon = lon - SEARCH_RADIUS;
        var maxLon = lon + SEARCH_RADIUS;

        // Build Overpass query for drinking water
        var bbox = minLat.format("%.4f") + "," + minLon.format("%.4f") + "," +
                   maxLat.format("%.4f") + "," + maxLon.format("%.4f");

        // URL-encode the query (brackets and special chars)
        var query = "%5Bout%3Ajson%5D%5Btimeout%3A25%5D%3Bnode%5Bamenity%3Ddrinking_water%5D(" +
                    bbox + ")%3Bout%20body%205%3B";

        var url = API_URL + "?data=" + query;

        System.println("Fetching: " + url);

        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON,
            :headers => {
                "Accept" => "application/json"
            }
        };

        Communications.makeWebRequest(url, null, options, method(:onResponse));
    }

    // Handle API response
    function onResponse(responseCode as Number, data as Dictionary or String or Null) as Void {
        System.println("Overpass response code: " + responseCode);

        if (responseCode != 200) {
            System.println("Network error: " + responseCode);
            _lastErrorCode = responseCode;
            _state = STATE_ERROR_NETWORK;
            if (_callback != null) {
                _callback.invoke();
            }
            return;
        }

        if (data == null || !(data instanceof Dictionary)) {
            _state = STATE_ERROR_PARSE;
            if (_callback != null) {
                _callback.invoke();
            }
            return;
        }

        var elements = data.get("elements");
        if (elements == null || !(elements instanceof Array) || elements.size() == 0) {
            _state = STATE_NO_RESULTS;
            if (_callback != null) {
                _callback.invoke();
            }
            return;
        }

        // Parse fountains
        _fountains = [];
        for (var i = 0; i < elements.size(); i++) {
            var element = elements[i];
            if (element instanceof Dictionary) {
                var lat = element.get("lat");
                var lon = element.get("lon");

                if (lat != null && lon != null) {
                    var tags = element.get("tags");
                    var name = null;
                    if (tags != null && tags instanceof Dictionary) {
                        name = tags.get("name");
                    }

                    var latVal = lat as Float;
                    var lonVal = lon as Float;
                    var fountain = new Fountain(latVal.toDouble(), lonVal.toDouble(), name);

                    // Calculate distance from search position
                    if (_searchLat != null && _searchLon != null) {
                        var dist = GeoMath.calculateDistance(
                            _searchLat, _searchLon,
                            fountain.lat, fountain.lon
                        );
                        fountain.distance = dist.toFloat();
                    }

                    _fountains.add(fountain);
                }
            }
        }

        if (_fountains.size() == 0) {
            _state = STATE_NO_RESULTS;
        } else {
            // Find nearest fountain
            _nearestFountain = _fountains[0];
            for (var i = 1; i < _fountains.size(); i++) {
                if (_fountains[i].distance < _nearestFountain.distance) {
                    _nearestFountain = _fountains[i];
                }
            }
            _state = STATE_SUCCESS;
        }

        if (_callback != null) {
            _callback.invoke();
        }
    }

    // Get current state
    function getState() as Number {
        return _state;
    }

    // Get nearest fountain
    function getNearestFountain() as Fountain? {
        return _nearestFountain;
    }

    // Get all fountains
    function getFountains() as Array<Fountain>? {
        return _fountains;
    }

    // Get count of fountains found
    function getFountainCount() as Number {
        if (_fountains == null) {
            return 0;
        }
        return _fountains.size();
    }

    // Get last error code for debugging
    function getLastErrorCode() as Number {
        return _lastErrorCode;
    }

    // Reset state
    function reset() as Void {
        _state = STATE_IDLE;
        _fountains = null;
        _nearestFountain = null;
        _lastErrorCode = 0;
    }
}
