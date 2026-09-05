# Wasserstelle Task List

## Phase 1: Foundation

- [x] **Task 1: Project Configuration**
  - Updated manifest.xml with permissions (Communications, Positioning, Sensor)
  - Added Edge 840 and Edge 1040 to target devices
  - Verified builds for all three devices

- [x] **Task 2: GeoMath Module**
  - Created source/GeoMath.mc
  - Implemented calculateDistance() using Haversine
  - Implemented calculateBearing()
  - Implemented bearingToCardinal()
  - Implemented formatDistance() with metric/imperial

- [x] **Task 3: Resources Setup**
  - Added UI strings to strings.xml
  - Created arrow.svg drawable
  - Updated drawables.xml
  - Cleaned up layout.xml

---

## Phase 2: Services

- [x] **Task 4: LocationService**
  - Created source/LocationService.mc
  - Implemented GPS position listening
  - Implemented state management (WAITING/ACQUIRED/ERROR)

- [x] **Task 5: OverpassService**
  - Created source/OverpassService.mc
  - Built Overpass query for drinking water
  - Implemented makeWebRequest() call
  - Parsed JSON response
  - Extracted nearest fountain with distance calculation

---

## Checkpoint 1: PASSED
- [x] LocationService compiles and provides GPS interface
- [x] OverpassService compiles and fetches/parses data
- [x] GeoMath calculates correct distance/bearing

---

## Phase 3: UI

- [x] **Task 6: WasserstelleView**
  - Rewrote source/WasserstelleView.mc
  - Draws compass arrow pointing to fountain
  - Displays distance text
  - Shows cardinal direction
  - Handles all display states

- [x] **Task 7: WasserstelleDelegate**
  - Created source/WasserstelleDelegate.mc
  - Handles SELECT button for refresh
  - Handles BACK button for exit

---

## Phase 4: Integration

- [x] **Task 8: Full Integration**
  - Updated source/WasserstelleApp.mc
  - Created and wired all services
  - Passed services to View and Delegate
  - Built successfully for all three Edge devices

---

## Checkpoint 2: MVP COMPLETE
- [x] Widget launches with "Acquiring GPS..."
- [x] Shows "Searching..." when fetching
- [x] Displays compass arrow to nearest fountain
- [x] Shows distance (e.g., "1.2 km")
- [x] SELECT button triggers refresh
- [x] Error states work correctly
- [x] Builds on Edge 540, 840, 1040
