#pragma once

#include <AudioToolbox/AudioToolbox.h>

#ifdef __cplusplus
extern "C" {
#endif

// Set bypass state for the kernel
void WDSPKernel_setBypass(void* kernel, bool bypass);

// Get bypass state from the kernel
bool WDSPKernel_getBypass(void* kernel);

// Set a preset on the kernel
void WDSPKernel_applyPreset(void* kernel, int presetIndex);

// Update the adaptive algorithm threshold
void WDSPKernel_setAdaptiveThreshold(void* kernel, float threshold);

// Set processor's master gain
void WDSPKernel_setMasterGain(void* kernel, float gain);

// Set time constants for the automixer
void WDSPKernel_setTimeConstants(void* kernel, float attackMs, float releaseMs);

// Get DSP load as a percentage (0.0-1.0)
float WDSPKernel_getDSPLoad(void* kernel);

#ifdef __cplusplus
}
#endif
