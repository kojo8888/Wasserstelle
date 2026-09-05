import Toybox.Lang;
import Toybox.Math;

// Geographic math utilities for distance and bearing calculations
module GeoMath {

    // Earth's radius in meters
    const EARTH_RADIUS_M = 6371000.0;

    // Meters per mile
    const METERS_PER_MILE = 1609.344;

    // Calculate distance between two coordinates using Haversine formula
    // Returns distance in meters
    function calculateDistance(lat1 as Double, lon1 as Double, lat2 as Double, lon2 as Double) as Double {
        var lat1Rad = Math.toRadians(lat1);
        var lat2Rad = Math.toRadians(lat2);
        var deltaLat = Math.toRadians(lat2 - lat1);
        var deltaLon = Math.toRadians(lon2 - lon1);

        var a = Math.sin(deltaLat / 2.0) * Math.sin(deltaLat / 2.0) +
                Math.cos(lat1Rad) * Math.cos(lat2Rad) *
                Math.sin(deltaLon / 2.0) * Math.sin(deltaLon / 2.0);

        var c = 2.0 * Math.atan2(Math.sqrt(a), Math.sqrt(1.0 - a));

        return EARTH_RADIUS_M * c;
    }

    // Calculate bearing from point 1 to point 2
    // Returns bearing in degrees (0-360, where 0 = North)
    function calculateBearing(lat1 as Double, lon1 as Double, lat2 as Double, lon2 as Double) as Double {
        var lat1Rad = Math.toRadians(lat1);
        var lat2Rad = Math.toRadians(lat2);
        var deltaLon = Math.toRadians(lon2 - lon1);

        var x = Math.sin(deltaLon) * Math.cos(lat2Rad);
        var y = Math.cos(lat1Rad) * Math.sin(lat2Rad) -
                Math.sin(lat1Rad) * Math.cos(lat2Rad) * Math.cos(deltaLon);

        var bearing = Math.toDegrees(Math.atan2(x, y));

        // Normalize to 0-360
        bearing = bearing.toDouble();
        while (bearing < 0.0) {
            bearing += 360.0;
        }
        while (bearing >= 360.0) {
            bearing -= 360.0;
        }
        return bearing;
    }

    // Convert bearing to cardinal direction
    function bearingToCardinal(bearing as Double) as String {
        // Normalize bearing to 0-360
        var b = bearing.toDouble();
        while (b < 0.0) {
            b += 360.0;
        }
        while (b >= 360.0) {
            b -= 360.0;
        }

        if (b >= 337.5 || b < 22.5) {
            return "N";
        } else if (b >= 22.5 && b < 67.5) {
            return "NE";
        } else if (b >= 67.5 && b < 112.5) {
            return "E";
        } else if (b >= 112.5 && b < 157.5) {
            return "SE";
        } else if (b >= 157.5 && b < 202.5) {
            return "S";
        } else if (b >= 202.5 && b < 247.5) {
            return "SW";
        } else if (b >= 247.5 && b < 292.5) {
            return "W";
        } else {
            return "NW";
        }
    }

    // Format distance for display - always in meters
    function formatDistance(meters as Double, useMetric as Boolean) as String {
        return meters.toNumber().toString() + " m";
    }

    // Calculate relative bearing from device heading to absolute bearing
    // Returns: bearing relative to where you're facing (0 = straight ahead, 90 = right, 270 = left)
    function calculateRelativeBearing(absoluteBearing as Float, deviceHeading as Float) as Float {
        var relative = absoluteBearing - deviceHeading;
        // Normalize to 0-360
        while (relative < 0.0f) {
            relative = relative + 360.0f;
        }
        while (relative >= 360.0f) {
            relative = relative - 360.0f;
        }
        return relative;
    }
}
