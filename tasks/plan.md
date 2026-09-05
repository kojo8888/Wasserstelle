# Wasserstelle Implementation Plan

## Dependency Graph

```
                    ┌─────────────────┐
                    │  manifest.xml   │ (permissions, devices)
                    └────────┬────────┘
                             │
              ┌──────────────┼──────────────┐
              │              │              │
              ▼              ▼              ▼
      ┌───────────┐  ┌─────────────┐  ┌──────────┐
      │ GeoMath   │  │ strings.xml │  │ drawables│
      │ (pure)    │  │ (resources) │  │ (arrow)  │
      └─────┬─────┘  └──────┬──────┘  └────┬─────┘
            │               │              │
            ▼               │              │
   ┌────────────────┐       │              │
   │LocationService │       │              │
   │ (GPS)          │       │              │
   └───────┬────────┘       │              │
           │                │              │
           ▼                │              │
  ┌─────────────────┐       │              │
  │ OverpassService │       │              │
  │ (HTTP + parse)  │       │              │
  └────────┬────────┘       │              │
           │                │              │
           └────────┬───────┴──────────────┘
                    │
                    ▼
           ┌────────────────┐
           │WasserstelleView│
           │ (compass UI)   │
           └───────┬────────┘
                   │
                   ▼
         ┌──────────────────┐
         │WasserstelleDelegate│
         │ (input handling)   │
         └─────────┬──────────┘
                   │
                   ▼
           ┌───────────────┐
           │WasserstelleApp│
           │ (entry point) │
           └───────────────┘
```

## Vertical Slices

Each task delivers a testable increment. We build bottom-up through the dependency graph.

---

## Phase 1: Foundation (Tasks 1-3)

### Task 1: Project Configuration
Set up manifest with permissions and target devices.

**Changes:**
- `manifest.xml` - Add Communications, Positioning, Sensor permissions; add Edge 840/1040

**Acceptance Criteria:**
- Project builds without errors for all three Edge devices
- No permission errors in simulator

**Verification:**
```bash
# Build for each device
monkeyc -f monkey.jungle -d edge540 -o bin/test540.prg
monkeyc -f monkey.jungle -d edge840 -o bin/test840.prg
monkeyc -f monkey.jungle -d edge1040 -o bin/test1040.prg
```

---

### Task 2: GeoMath Module
Pure math functions for distance and bearing calculations.

**Changes:**
- `source/GeoMath.mc` - New file with:
  - `calculateDistance(lat1, lon1, lat2, lon2)` - Haversine formula, returns meters
  - `calculateBearing(lat1, lon1, lat2, lon2)` - Returns degrees 0-360
  - `bearingToCardinal(bearing)` - Returns "N", "NE", etc.
  - `formatDistance(meters, useMetric)` - Returns "1.2 km" or "0.7 mi"

**Acceptance Criteria:**
- Functions compile without errors
- Known test values produce correct results (e.g., Munich to Berlin ~504km)

**Verification:**
- Build succeeds
- Manual verification with hardcoded test coordinates in simulator

---

### Task 3: Resources Setup
Create UI strings and arrow drawable.

**Changes:**
- `resources/strings/strings.xml` - Add all UI strings
- `resources/drawables/arrow.png` - Create simple arrow graphic (or SVG)
- `resources/drawables/drawables.xml` - Register arrow
- `resources/layouts/layout.xml` - Remove monkey placeholder

**Acceptance Criteria:**
- All strings accessible via `Rez.Strings.*`
- Arrow drawable loads without error

**Verification:**
- Build succeeds
- Strings appear in resource compiler output

---

## Phase 2: Services (Tasks 4-5)

### Task 4: LocationService
GPS position handling with state management.

**Changes:**
- `source/LocationService.mc` - New file with:
  - State enum: `WAITING`, `ACQUIRED`, `ERROR`
  - `initialize()` - Register position listener
  - `onPosition(info)` - Callback handler
  - `getPosition()` - Returns current lat/lon or null
  - `getState()` - Returns current state

**Acceptance Criteria:**
- Service starts listening on initialize
- State transitions correctly: WAITING → ACQUIRED when fix obtained
- Position accessible after acquisition

**Verification:**
- Simulator: Set GPS position, verify state changes
- Verify `getPosition()` returns correct coordinates

---

### Task 5: OverpassService
HTTP requests and JSON parsing.

**Changes:**
- `source/OverpassService.mc` - New file with:
  - State enum: `IDLE`, `FETCHING`, `SUCCESS`, `ERROR`
  - `fetchNearbyWater(lat, lon, callback)` - Initiates request
  - `onResponse(responseCode, data)` - Handles response
  - `parseResponse(data)` - Extracts fountain array [{lat, lon, name}]
  - `getNearestFountain()` - Returns closest to given position

**Acceptance Criteria:**
- Builds Overpass query string correctly for 5km radius
- Parses valid JSON response into fountain array
- Handles HTTP errors (non-200, timeout)
- Handles empty results

**Verification:**
- Simulator with network: Verify real API call succeeds
- Mock response: Parse sample JSON correctly

---

## Checkpoint 1: Services Integration Test

Before proceeding, verify:
1. LocationService acquires position in simulator
2. OverpassService fetches real data from Overpass API
3. GeoMath calculates correct distance/bearing between position and fountain

---

## Phase 3: UI (Tasks 6-7)

### Task 6: WasserstelleView - Compass Display
Main view with compass arrow and distance.

**Changes:**
- `source/WasserstelleView.mc` - Rewrite to:
  - Display states: "Acquiring GPS...", "Searching...", compass view, error states
  - Draw compass arrow rotated to bearing
  - Display distance text
  - Display cardinal direction
  - Handle `onUpdate(dc)` to render current state

**Acceptance Criteria:**
- Shows "Acquiring GPS..." on launch
- Shows "Searching..." when fetching
- Displays arrow pointing correct direction
- Shows formatted distance
- Error messages display correctly

**Verification:**
- Simulator: Step through each state visually
- Arrow rotation matches hardcoded test bearing

---

### Task 7: WasserstelleDelegate - Input Handling
Button press handling for manual refresh.

**Changes:**
- `source/WasserstelleDelegate.mc` - New file with:
  - `onSelect()` - Triggers refresh
  - Calls back to view to initiate new fetch

**Acceptance Criteria:**
- SELECT button triggers refresh action
- View updates to "Refreshing..." state

**Verification:**
- Simulator: Press SELECT, verify state change

---

## Phase 4: Integration (Task 8)

### Task 8: WasserstelleApp - Full Integration
Wire everything together in the app entry point.

**Changes:**
- `source/WasserstelleApp.mc` - Update to:
  - Create LocationService on start
  - Create OverpassService
  - Pass services to View
  - Return View with Delegate
  - Clean up on stop

**Acceptance Criteria:**
- Full flow works: Launch → GPS → Fetch → Display → Refresh
- All error states handled
- Memory usage acceptable

**Verification:**
- Full end-to-end test in simulator
- Test on each device model
- Memory profiler shows acceptable usage

---

## Checkpoint 2: MVP Complete

Verify all acceptance criteria from SPEC.md:
1. [ ] Widget launches and displays "Acquiring GPS..." initially
2. [ ] Once GPS acquired, shows "Searching..." while fetching from Overpass
3. [ ] Displays compass arrow pointing to nearest fountain
4. [ ] Shows distance to nearest fountain (e.g., "1.2 km")
5. [ ] SELECT button triggers manual refresh
6. [ ] Error states display appropriate messages
7. [ ] Builds and runs on Edge 540, 840, and 1040 simulators

---

## Build Order Summary

```
1. manifest.xml (permissions, devices)    ─┐
2. GeoMath.mc (pure functions)            ─┼─ Phase 1: Foundation
3. Resources (strings, arrow)             ─┘
   ══════════════════════════════════════
4. LocationService.mc (GPS)               ─┐
5. OverpassService.mc (HTTP)              ─┘─ Phase 2: Services
   ══════════════════════════════════════
   ★ CHECKPOINT 1: Services work
   ══════════════════════════════════════
6. WasserstelleView.mc (compass UI)       ─┐
7. WasserstelleDelegate.mc (input)        ─┘─ Phase 3: UI
   ══════════════════════════════════════
8. WasserstelleApp.mc (integration)       ─── Phase 4: Integration
   ══════════════════════════════════════
   ★ CHECKPOINT 2: MVP complete
```

## Risk Mitigation

| Risk | Mitigation |
|------|------------|
| Overpass API response too large for memory | Limit query to 10 closest results using `[out:json][maxsize:50000]` |
| No GPS in simulator | Use simulator's GPS injection feature |
| Network unavailable | Test error paths explicitly |
| Arrow rendering complex | Start with simple triangle, enhance later |
