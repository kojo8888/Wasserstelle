#!/bin/bash
SDK="$HOME/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.2.0-2026-06-09-92a1605b2"
export PATH="$SDK/bin:$PATH"

open "$SDK/bin/ConnectIQ.app"
sleep 3
monkeydo bin/Wasserstelle-edge540.prg edge540
