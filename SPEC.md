# Wasserstelle - Garmin Connect IQ Widget Specification

## 1. Objective

**What:** A Garmin Connect IQ widget that helps cyclists find the nearest drinking water fountain using OpenStreetMap Overpass API data.

**Who:** Garmin Edge users (540/840/1040) who need to locate water refill points during rides.

**Why:** Quick access to nearby water sources without needing a phone, displayed with compass navigation to guide the rider.

### Success Criteria
- Widget displays compass arrow pointing to nearest drinking water source
- Distance to nearest fountain shown in user's preferred units
- Manual refresh via button press updates location and fetches new data
- Works on Edge 540, 840, and 1040 devices
- Clear error states when no GPS or no internet connection

---

## 2. Core Features

### 2.1 GPS Location
- Obtain current device position using Toybox.Position
- Display "Acquiring GPS..." while waiting for fix
- Show error if GPS unavailable

### 2.2 Overpass API Query
- Query drinking water POIs within 5km radius of current position
- Overpass query targets:
  - `amenity=drinking_water`
  - `amenity=water_point`
  - `amenity=fountain` with `drinking_water=yes`
  - Any node with `drinking_water=yes`
- Use POST request to `https://overpass-api.de/api/interpreter`
- Parse JSON response to extract coordinates

### 2.3 Compass Display
- Calculate bearing from current position to nearest fountain
- Display arrow pointing toward fountain (relative to device heading if available)
- Show distance in km or miles based on device settings
- If no heading sensor, show static cardinal direction (N, NE, E, etc.)

### 2.4 Manual Refresh
- User presses SELECT button to trigger location update and new API fetch
- Display "Refreshing..." during fetch
- Update display with new results

### 2.5 Error Handling
- No GPS: "No GPS Signal"
- No internet: "No Connection"
- No fountains found: "None within 5km"
- API error: "Service Error"

---

## 3. Project Structure

```
Wasserstelle/
├── manifest.xml              # App config, permissions, supported devices
├── monkey.jungle             # Build configuration
├── SPEC.md                   # This specification
├── source/
│   ├── WasserstelleApp.mc    # Application entry point
│   ├── WasserstelleView.mc   # Main widget view (compass display)
│   ├── WasserstelleDelegate.mc # Input handling (button presses)
│   ├── OverpassService.mc    # HTTP requests to Overpass API
│   ├── LocationService.mc    # GPS position handling
│   └── GeoMath.mc            # Distance/bearing calculations
├── resources/
│   ├── strings/
│   │   └── strings.xml       # English strings
│   ├── drawables/
│   │   ├── drawables.xml
│   │   ├── launcher_icon.svg # Water drop icon
│   │   └── arrow.png         # Compass arrow graphic
│   └── layouts/
│       └── layout.xml        # Widget layout
└── tests/                    # Unit tests (if supported)
```

---

## 4. Code Style

### Monkey C Conventions
- Class names: PascalCase (`WasserstelleView`, `OverpassService`)
- Function names: camelCase (`calculateBearing`, `fetchNearbyWater`)
- Constants: SCREAMING_SNAKE_CASE (`MAX_RESULTS`, `SEARCH_RADIUS_M`)
- Variables: camelCase (`nearestFountain`, `currentPosition`)

### Type Annotations
- Use Monkey C type annotations where supported: `function foo(x as Number) as String`

### Module Organization
- Each `.mc` file contains one primary class
- Import only required Toybox modules
- Keep classes focused on single responsibility

### Comments
- Document public functions with purpose and parameters
- Inline comments only for non-obvious logic

---

## 5. Testing Strategy

### Manual Testing (Primary)
- Test in Garmin simulator for each target device (Edge 540/840/1040)
- Test scenarios:
  - Fresh launch with GPS fix
  - Launch without GPS
  - Successful API response with multiple fountains
  - API response with no fountains in range
  - Network timeout/error
  - Manual refresh button

### Simulator Testing
```bash
# Build for simulator
monkeyc -f monkey.jungle -o bin/Wasserstelle.prg -d edge540

# Run in simulator
connectiq
```

### On-Device Testing
- Sideload via USB to physical Edge device
- Test with real GPS and network conditions
- Verify compass arrow updates with device movement

---

## 6. Boundaries

### Always Do
- Validate GPS position before making API requests
- Handle all network error cases gracefully
- Respect Garmin memory limits (minimize string allocations)
- Use device's unit preferences (metric/imperial)
- Clean up resources in `onHide()`

### Ask First
- Adding additional POI types (repair stations, etc.)
- Changing search radius
- Adding caching/offline support
- Supporting additional device models
- Adding settings menu

### Never Do
- Make API requests without valid GPS position
- Block UI thread with synchronous operations
- Store user location persistently
- Exceed Garmin memory limits
- Ignore API rate limiting (Overpass has fair-use policy)

---

## 7. Technical Constraints

### Garmin Connect IQ Limitations
- **Memory:** Widgets have ~28KB memory limit on most devices
- **HTTP:** Must use `Communications.makeWebRequest()` - async only
- **JSON Parsing:** Built-in JSON parsing, but large responses may fail
- **Background:** Widgets don't run in background

### Required Permissions (manifest.xml)
```xml
<iq:permissions>
    <iq:uses-permission id="Communications"/>
    <iq:uses-permission id="Positioning"/>
    <iq:uses-permission id="Sensor"/>
</iq:permissions>
```

### Target Devices
- Edge 540 (`edge540`)
- Edge 840 (`edge840`)
- Edge 1040 (`edge1040`)

### API Details
- Endpoint: `https://overpass-api.de/api/interpreter`
- Method: POST
- Content-Type: `text/plain` (for query) or use GET with `data` parameter
- Response: JSON
- Rate limit: Fair use (~10,000 requests/day, reasonable intervals)

---

## 8. Acceptance Criteria

### MVP Complete When:
1. [ ] Widget launches and displays "Acquiring GPS..." initially
2. [ ] Once GPS acquired, shows "Searching..." while fetching from Overpass
3. [ ] Displays compass arrow pointing to nearest fountain
4. [ ] Shows distance to nearest fountain (e.g., "1.2 km")
5. [ ] SELECT button triggers manual refresh
6. [ ] Error states display appropriate messages
7. [ ] Builds and runs on Edge 540, 840, and 1040 simulators

### Nice-to-Have (Post-MVP):
- [ ] Show fountain name/description if available in OSM data
- [ ] Show count of total fountains found
- [ ] Settings for search radius
- [ ] Heading-relative arrow (requires magnetometer)
