# WDSP Dugan Automixer

A professional-grade automatic microphone mixer Audio Unit plugin for macOS based on Dan Dugan's automixing algorithm.

![WDSP Dugan Automixer Plugin UI](docs/images/plugin-screenshot.png)

## Overview

The WDSP Dugan Automixer automatically manages the gain of multiple microphone channels to maintain a consistent total gain, ensuring smooth transitions between speakers while minimizing background noise and feedback problems.

### Key Features

- **Constant Total Gain Mixing:** Maintains the same total gain regardless of how many microphones are active
- **4-Channel Support:** Mix up to 4 independent audio channels
- **Advanced Controls:** Per-channel weight adjustment, auto-enable, and override functionality
- **Visual Feedback:** Real-time metering for input levels and gain reduction
- **Preset Management:** Factory presets for common scenarios and user preset save/load
- **Statistics & Diagnostics:** Comprehensive performance metrics and analysis tools

## Requirements

- macOS 10.13 or higher
- Xcode 13.0 or higher (for building)
- A DAW or audio host that supports Audio Unit v3 plugins

## Building the Plugin

### From Xcode

1. Open the `WDSP.xcodeproj` file in Xcode
2. Select the "WDSPExtension" target
3. Select your development team in the Signing & Capabilities tab
4. Build the project (⌘B)

### From Command Line

```bash
xcodebuild -project WDSP.xcodeproj -target WDSPExtension -configuration Release
```

## Installation

After building, the Audio Unit will be located at:

```
~/Library/Audio/Plug-Ins/Components/WDSP.component
```

To install for all users, copy to:

```
/Library/Audio/Plug-Ins/Components/WDSP.component
```

You may need to restart your DAW or run the following command to register the Audio Unit:

```bash
killall -9 AudioComponentRegistrar
```

## Using the Plugin

### Basic Usage

1. Insert the plugin on a track or bus with multiple microphone signals
2. Each channel will automatically adjust its gain to maintain a constant total output level
3. Adjust the "Weight" sliders to prioritize certain channels if needed
4. Use the "Auto" switches to include/exclude channels from automatic mixing
5. Use the "Override" switches to give a channel priority over others

### Interface Guide

![Interface Guide](docs/images/interface-guide.png)

1. **Preset Selector:** Choose from factory presets or save/load your own
2. **Channel Strips:** Control each individual microphone channel
   - Weight slider: Adjust channel's relative priority (0.0-2.0)
   - Auto switch: Enable/disable automatic mixing for this channel
   - Override switch: Set this channel to override others
   - Input meter: Shows input signal level
   - Gain meter: Shows gain reduction applied by the automixer
3. **Statistics View:** Shows real-time performance metrics
4. **Advanced Settings:** Fine-tune DSP parameters
5. **Diagnostics:** View detailed system information

### Advanced Settings

Access the Advanced Settings panel to adjust:

- **Attack Time:** How quickly the automixer responds to rising signals (1-100ms)
- **Release Time:** How quickly the automixer responds to falling signals (10-1000ms)
- **Smoothing:** How smoothly gain changes are applied (1-500ms)

## Common Use Cases

- **Conference Calls:** Automatically mix multiple participants
- **Panel Discussions:** Ensure clear audio from all panelists
- **Broadcast:** Maintain consistent levels for interviews and roundtables
- **Houses of Worship:** Manage multiple microphones for speakers and performers

## Troubleshooting

If the plugin doesn't appear in your DAW:

1. Verify the plugin was built successfully
2. Check if the plugin passes validation:
   ```bash
   auval -v aufx WDSP Demo
   ```
3. Restart your DAW and computer
4. Check your DAW's plugin scanning/cache settings

## Technical Details

The plugin implements Dugan's automixing algorithm with optimizations:

- **SIMD Acceleration:** Uses vector processing for better performance
- **Thread Safety:** Carefully designed for reliable real-time performance
- **Low Latency:** Zero added latency for live use
- **Error Handling:** Graceful degradation and detailed diagnostics

## License

Copyright © 2025 WDSP Audio Software. All rights reserved.

---

*The Dugan Automixing algorithm is based on Dan Dugan's patent. This implementation is used with permission.*
