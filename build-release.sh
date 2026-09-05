#!/bin/bash
# Build for real device (disables test mode)

SDK="$HOME/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.2.0-2026-06-09-92a1605b2"
export PATH="$SDK/bin:$PATH"

# Disable test mode
sed -i '' 's/_useTestMode = true/_useTestMode = false/' source/WasserstelleView.mc

# Build for all devices
echo "Building for Edge 530..."
monkeyc -f monkey.jungle -d edge530 -y developer_key.der -r -o bin/Wasserstelle-edge530.prg

echo "Building for Edge 540..."
monkeyc -f monkey.jungle -d edge540 -y developer_key.der -r -o bin/Wasserstelle-edge540.prg

echo "Building for Edge 840..."
monkeyc -f monkey.jungle -d edge840 -y developer_key.der -r -o bin/Wasserstelle-edge840.prg

echo "Building for Edge 1040..."
monkeyc -f monkey.jungle -d edge1040 -y developer_key.der -r -o bin/Wasserstelle-edge1040.prg

# Re-enable test mode for development
sed -i '' 's/_useTestMode = false/_useTestMode = true/' source/WasserstelleView.mc

echo ""
echo "Release builds ready in bin/"
echo "Copy the .prg file to your Edge device: GARMIN/APPS/"
