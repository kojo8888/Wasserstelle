import Toybox.Test;
import Toybox.Lang;
import Toybox.Math;

// Unit tests for GeoMath module
// Run with: monkeyc -f monkey.jungle -d edge540 -t -y developer_key.der -o bin/test.prg

(:test)
function testCalculateDistanceSamePoint(logger as Logger) as Boolean {
    // Distance from a point to itself should be 0
    var distance = GeoMath.calculateDistance(48.137d, 11.576d, 48.137d, 11.576d);
    logger.debug("Same point distance: " + distance);
    return (distance < 1.0);  // Should be essentially 0 (allowing floating point tolerance)
}

(:test)
function testCalculateDistanceKnownPoints(logger as Logger) as Boolean {
    // Munich (48.137, 11.576) to Marienplatz area (48.137, 11.575) ~85m
    var distance = GeoMath.calculateDistance(48.137d, 11.576d, 48.137d, 11.575d);
    logger.debug("Short distance: " + distance + " m");
    // Should be approximately 74 meters (0.001 degree longitude at this latitude)
    return (distance > 50.0 && distance < 100.0);
}

(:test)
function testCalculateDistanceLongerDistance(logger as Logger) as Boolean {
    // Munich center to ~1km away
    var distance = GeoMath.calculateDistance(48.137d, 11.576d, 48.147d, 11.576d);
    logger.debug("1km distance: " + distance + " m");
    // 0.01 degree latitude ≈ 1.1km
    return (distance > 1000.0 && distance < 1200.0);
}

(:test)
function testCalculateBearingNorth(logger as Logger) as Boolean {
    // Going straight north should be ~0 degrees
    var bearing = GeoMath.calculateBearing(48.137d, 11.576d, 48.147d, 11.576d);
    logger.debug("North bearing: " + bearing);
    return (bearing < 5.0 || bearing > 355.0);  // Close to 0/360
}

(:test)
function testCalculateBearingEast(logger as Logger) as Boolean {
    // Going straight east should be ~90 degrees
    var bearing = GeoMath.calculateBearing(48.137d, 11.576d, 48.137d, 11.586d);
    logger.debug("East bearing: " + bearing);
    return (bearing > 85.0 && bearing < 95.0);
}

(:test)
function testCalculateBearingSouth(logger as Logger) as Boolean {
    // Going straight south should be ~180 degrees
    var bearing = GeoMath.calculateBearing(48.147d, 11.576d, 48.137d, 11.576d);
    logger.debug("South bearing: " + bearing);
    return (bearing > 175.0 && bearing < 185.0);
}

(:test)
function testCalculateBearingWest(logger as Logger) as Boolean {
    // Going straight west should be ~270 degrees
    var bearing = GeoMath.calculateBearing(48.137d, 11.586d, 48.137d, 11.576d);
    logger.debug("West bearing: " + bearing);
    return (bearing > 265.0 && bearing < 275.0);
}

(:test)
function testBearingToCardinalNorth(logger as Logger) as Boolean {
    var cardinal = GeoMath.bearingToCardinal(0.0d);
    logger.debug("0 degrees = " + cardinal);
    return cardinal.equals("N");
}

(:test)
function testBearingToCardinalNorthEast(logger as Logger) as Boolean {
    var cardinal = GeoMath.bearingToCardinal(45.0d);
    logger.debug("45 degrees = " + cardinal);
    return cardinal.equals("NE");
}

(:test)
function testBearingToCardinalEast(logger as Logger) as Boolean {
    var cardinal = GeoMath.bearingToCardinal(90.0d);
    logger.debug("90 degrees = " + cardinal);
    return cardinal.equals("E");
}

(:test)
function testBearingToCardinalSouth(logger as Logger) as Boolean {
    var cardinal = GeoMath.bearingToCardinal(180.0d);
    logger.debug("180 degrees = " + cardinal);
    return cardinal.equals("S");
}

(:test)
function testBearingToCardinalWest(logger as Logger) as Boolean {
    var cardinal = GeoMath.bearingToCardinal(270.0d);
    logger.debug("270 degrees = " + cardinal);
    return cardinal.equals("W");
}

(:test)
function testFormatDistanceMeters(logger as Logger) as Boolean {
    var formatted = GeoMath.formatDistance(150.0d, true);
    logger.debug("150m formatted: " + formatted);
    return formatted.equals("150 m");
}

(:test)
function testFormatDistanceLargeMeters(logger as Logger) as Boolean {
    var formatted = GeoMath.formatDistance(2500.0d, true);
    logger.debug("2500m formatted: " + formatted);
    return formatted.equals("2500 m");  // Always meters now
}

// ============================================
// Tests for heading-relative bearing calculation
// ============================================

(:test)
function testRelativeBearingFacingNorthFountainNorth(logger as Logger) as Boolean {
    // Facing North (0°), fountain is North (0°) → straight ahead (0°)
    var relative = GeoMath.calculateRelativeBearing(0.0f, 0.0f);
    logger.debug("Facing N, fountain N: " + relative);
    return (relative < 5.0f || relative > 355.0f);
}

(:test)
function testRelativeBearingFacingEastFountainNorth(logger as Logger) as Boolean {
    // Facing East (90°), fountain is North (0°) → to your left (270°)
    var relative = GeoMath.calculateRelativeBearing(0.0f, 90.0f);
    logger.debug("Facing E, fountain N: " + relative);
    return (relative > 265.0f && relative < 275.0f);
}

(:test)
function testRelativeBearingFacingSouthFountainNorth(logger as Logger) as Boolean {
    // Facing South (180°), fountain is North (0°) → behind you (180°)
    var relative = GeoMath.calculateRelativeBearing(0.0f, 180.0f);
    logger.debug("Facing S, fountain N: " + relative);
    return (relative > 175.0f && relative < 185.0f);
}

(:test)
function testRelativeBearingFacingWestFountainNorth(logger as Logger) as Boolean {
    // Facing West (270°), fountain is North (0°) → to your right (90°)
    var relative = GeoMath.calculateRelativeBearing(0.0f, 270.0f);
    logger.debug("Facing W, fountain N: " + relative);
    return (relative > 85.0f && relative < 95.0f);
}

(:test)
function testRelativeBearingNormalizesNegative(logger as Logger) as Boolean {
    // Facing East (90°), fountain is NE (45°) → result should be 315° (not -45°)
    var relative = GeoMath.calculateRelativeBearing(45.0f, 90.0f);
    logger.debug("Facing E, fountain NE: " + relative);
    return (relative > 310.0f && relative < 320.0f);
}

(:test)
function testRelativeBearingSameDirection(logger as Logger) as Boolean {
    // Facing SE (135°), fountain is SE (135°) → straight ahead (0°)
    var relative = GeoMath.calculateRelativeBearing(135.0f, 135.0f);
    logger.debug("Facing SE, fountain SE: " + relative);
    return (relative < 5.0f || relative > 355.0f);
}
