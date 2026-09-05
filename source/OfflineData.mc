import Toybox.Lang;

// Offline drinking water fountain data for Munich
// Generated from OpenStreetMap Overpass API (September 2026)
// 30 fountains within ~3km of Marienplatz, sorted by distance from center
module OfflineData {

    // Munich city center (Marienplatz)
    const MUNICH_CENTER_LAT = 48.137d;
    const MUNICH_CENTER_LON = 11.576d;

    // Maximum distance from center to use offline data (5km)
    const MAX_OFFLINE_DISTANCE_M = 5000.0;

    // Fountain coordinates [lat, lon]
    const MUNICH_FOUNTAINS = [
        [48.136286d, 11.573669d],
        [48.134228d, 11.573447d],
        [48.135433d, 11.570796d],
        [48.134289d, 11.567279d],
        [48.139355d, 11.566415d],
        [48.138159d, 11.565663d],
        [48.145967d, 11.575200d],
        [48.132199d, 11.562965d],
        [48.142319d, 11.562437d],
        [48.142170d, 11.560773d],
        [48.125810d, 11.583001d],
        [48.124792d, 11.583714d],
        [48.123836d, 11.572892d],
        [48.131078d, 11.596146d],
        [48.134344d, 11.598813d],
        [48.121493d, 11.580189d],
        [48.132090d, 11.553291d],
        [48.121458d, 11.581503d],
        [48.134987d, 11.551644d],
        [48.136427d, 11.551417d],
        [48.153531d, 11.570827d],
        [48.119133d, 11.583960d],
        [48.152827d, 11.559339d],
        [48.155430d, 11.566732d],
        [48.132423d, 11.604750d],
        [48.156869d, 11.574591d],
        [48.117451d, 11.581757d],
        [48.128495d, 11.603157d],
        [48.157201d, 11.574030d],
        [48.116159d, 11.577096d]
    ];

    // Check if location is within Munich offline data range
    function isInMunichRange(lat as Double, lon as Double) as Boolean {
        var distance = GeoMath.calculateDistance(lat, lon, MUNICH_CENTER_LAT, MUNICH_CENTER_LON);
        return distance <= MAX_OFFLINE_DISTANCE_M;
    }

    // Get fountains array
    function getMunichFountains() as Array {
        return MUNICH_FOUNTAINS;
    }

    // Get fountain count
    function getFountainCount() as Number {
        return MUNICH_FOUNTAINS.size();
    }
}
