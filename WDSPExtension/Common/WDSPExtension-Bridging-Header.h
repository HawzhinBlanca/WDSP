#ifndef WDSPExtension_Bridging_Header_h
#define WDSPExtension_Bridging_Header_h

// Import required CoreAudio frameworks
#import <AudioToolbox/AudioToolbox.h>
#import <AudioUnit/AudioUnit.h>
#import <CoreAudio/CoreAudioTypes.h>

// Add forward declarations
class WDSPKernel;

#ifdef __cplusplus
extern "C" {
#endif

// Add function declarations
void WDSPKernel_setTimeConstants(void* kernel, float attackTime, float releaseTime);
void WDSPKernel_setAdaptiveThreshold(void* kernel, float threshold);
void WDSPKernel_setMasterGain(void* kernel, float gain);
void WDSPKernel_applyPreset(void* kernel, int presetIndex);
float WDSPKernel_getParameter(void* kernel, AudioUnitParameterID address);
void WDSPKernel_setParameter(void* kernel, AudioUnitParameterID address, float value);
OSStatus WDSPKernel_processAudio(void* kernel, const AudioTimeStamp* timestamp, UInt32 frameCount,
                               AudioBufferList* inputBufferList, AudioBufferList* outputBufferList);
void WDSPKernel_initialize(void* kernel, double sampleRate);
void WDSPKernel_reset(void* kernel);
void* WDSPKernel_create(double sampleRate);
void WDSPKernel_destroy(void* kernel);

// Core functions
void WDSPKernel_setBypass(void* kernel, bool bypass);
bool WDSPKernel_getBypass(void* kernel);
float WDSPKernel_getDSPLoad(void* kernel);
float WDSPKernel_getChannelPeakLevel(void* kernel, unsigned int channel);

#ifdef __cplusplus
}
#endif

#endif /* WDSPExtension_Bridging_Header_h */
