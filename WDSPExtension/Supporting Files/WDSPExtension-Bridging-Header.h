#ifndef WDSPExtension_Bridging_Header_h
#define WDSPExtension_Bridging_Header_h

// Import required CoreAudio frameworks
#import <AudioToolbox/AudioToolbox.h>
#import <AudioUnit/AudioUnit.h>
#import <CoreAudio/CoreAudioTypes.h>

// Define diagnostic info struct that matches the C++ struct
typedef struct {
    float averageLoad;
    float peakLoad;
    int overloads;
    bool wasBypassEngaged;
    bool isBypassEngaged;
    float inputLevel;
    float outputLevel;
} WDSPDiagnosticInfoC;

// Import C++ classes - forward declarations only
#ifdef __cplusplus
// Forward declarations
class WDSPKernel;

// Diagnostic information structure for Swift bridging
struct WDSPDiagnosticInfoCpp {
    float averageLoad;        // Average CPU load (0.0-1.0)
    float peakLoad;           // Peak CPU load (0.0-1.0)
    int overloads;            // Count of processing overloads
    bool wasBypassEngaged;    // Previous bypass state
    bool isBypassEngaged;     // Current bypass state
    float inputLevel;         // Input level in dB
    float outputLevel;        // Output level in dB
};
#else
// C-compatible struct definitions for Swift
typedef struct WDSPKernel WDSPKernel;

// Ensure the same structure is available in C mode
typedef struct {
    float averageLoad;
    float peakLoad;
    int overloads;
    bool wasBypassEngaged;
    bool isBypassEngaged;
    float inputLevel;
    float outputLevel;
} WDSPDiagnosticInfoC;

// Alias to maintain consistent naming in both C and C++ modes
typedef WDSPDiagnosticInfoC WDSPDiagnosticInfoCpp;
#endif

// C interface for the kernel to make it accessible from Swift
#ifdef __cplusplus
extern "C" {
#endif

/**
 * @brief Get diagnostic information from the kernel
 * @param kernel Pointer to the WDSPKernel instance
 * @return Diagnostic information structure
 */
WDSPDiagnosticInfoC wdsp_get_diagnostic_info(const WDSPKernel* kernel);

/**
 * @brief Get the value of a parameter from the kernel
 * @param kernel Pointer to the WDSPKernel instance
 * @param address Parameter address/ID
 * @return The parameter value
 */
float WDSPKernel_getParameter(void* kernel, AudioUnitParameterID address);

/**
 * @brief Set a parameter value in the kernel
 * @param kernel Pointer to the WDSPKernel instance
 * @param address Parameter address/ID
 * @param value The new parameter value
 */
void WDSPKernel_setParameter(void* kernel, AudioUnitParameterID address, float value);

/**
 * @brief Process audio through the Dugan algorithm
 * @param kernel Pointer to the WDSPKernel instance
 * @param timestamp Audio timestamp
 * @param frameCount Number of frames to process
 * @param inputBufferList Input audio buffer list
 * @param outputBufferList Output audio buffer list
 * @return OSStatus indicating success or error
 */
OSStatus WDSPKernel_processAudio(void* kernel,
                               const AudioTimeStamp* timestamp,
                               UInt32 frameCount,
                               AudioBufferList* inputBufferList,
                               AudioBufferList* outputBufferList);

/**
 * @brief Initialize the kernel with a sample rate
 * @param kernel Pointer to the WDSPKernel instance
 * @param sampleRate The audio sample rate to use
 */
void WDSPKernel_initialize(void* kernel, double sampleRate);

/**
 * @brief Reset the kernel state
 * @param kernel Pointer to the WDSPKernel instance
 */
void WDSPKernel_reset(void* kernel);

/**
 * @brief Create a new kernel instance
 * @param sampleRate The initial sample rate
 * @return Pointer to the created kernel, or NULL on failure
 */
void* WDSPKernel_create(double sampleRate);

/**
 * @brief Destroy a kernel instance
 * @param kernel Pointer to the WDSPKernel instance to destroy
 */
void WDSPKernel_destroy(void* kernel);

/**
 * @brief Set bypass state for the kernel
 * @param kernel Pointer to the WDSPKernel instance
 * @param bypass True to enable bypass, false for normal processing
 */
void WDSPKernel_setBypass(void* kernel, bool bypass);

/**
 * @brief Get bypass state from the kernel
 * @param kernel Pointer to the WDSPKernel instance
 * @return True if bypassed, false otherwise
 */
bool WDSPKernel_getBypass(void* kernel);

/**
 * @brief Set a preset on the kernel
 * @param kernel Pointer to the WDSPKernel instance
 * @param presetIndex Index of the preset to apply
 */
void WDSPKernel_applyPreset(void* kernel, int presetIndex);

/**
 * @brief Update the adaptive algorithm threshold
 * @param kernel Pointer to the WDSPKernel instance
 * @param threshold Threshold value in dB
 */
void WDSPKernel_setAdaptiveThreshold(void* kernel, float threshold);

/**
 * @brief Set processor's master gain
 * @param kernel Pointer to the WDSPKernel instance
 * @param gain Gain value in dB
 */
void WDSPKernel_setMasterGain(void* kernel, float gain);

/**
 * @brief Set time constants for the automixer
 * @param kernel Pointer to the WDSPKernel instance
 * @param attackMs Attack time in milliseconds
 * @param releaseMs Release time in milliseconds
 */
void WDSPKernel_setTimeConstants(void* kernel, float attackMs, float releaseMs);

/**
 * @brief Get DSP load as a percentage (0.0-1.0)
 * @param kernel Pointer to the WDSPKernel instance
 * @return DSP load between 0.0 and 1.0
 */
float WDSPKernel_getDSPLoad(void* kernel);

/**
 * @brief Get channel peak level
 * @param kernel Pointer to the WDSPKernel instance
 * @param channel Channel index
 * @return Peak level in dB
 */
float WDSPKernel_getChannelPeakLevel(void* kernel, unsigned int channel);

#ifdef __cplusplus
}
#endif

#endif /* WDSPExtension_Bridging_Header_h */
