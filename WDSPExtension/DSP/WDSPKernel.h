#pragma once

#include <AudioToolbox/AudioToolbox.h>
#include <AudioUnit/AudioUnit.h>
#include <memory>
#include <atomic>
#include <chrono>
#include <map>
#include <string>

// Forward declaration
class DuganProcessor;

/**
 * C++ struct to bridge diagnostic information to Swift
 * Contains metrics about DSP performance and audio levels
 */
struct WDSPDiagnosticInfoCpp {
    float averageLoad;        // Average CPU load (0.0-1.0)
    float peakLoad;           // Peak CPU load (0.0-1.0)
    int overloads;            // Count of processing overloads
    bool wasBypassEngaged;    // Previous bypass state
    bool isBypassEngaged;     // Current bypass state 
    float inputLevel;         // Input level in dB
    float outputLevel;        // Output level in dB (uses peak level measurement)
};

/**
 * @class WDSPKernel
 * @brief Audio processing kernel that interfaces with AUAudioUnit
 *
 * This class bridges the audio unit plugin infrastructure with the
 * core DSP implementation in DuganProcessor.
 */
class WDSPKernel {
public:
    /**
     * @brief Constructor with default sample rate
     */
    WDSPKernel();
    
    /**
     * @brief Destructor to clean up resources
     */
    ~WDSPKernel();
    
    /**
     * @brief Initialize the kernel with a given sample rate
     * @param sampleRate The audio sample rate
     */
    void initialize(double sampleRate);
    
    /**
     * @brief Set parameter value from audio unit
     * @param address Parameter address
     * @param value Parameter value
     */
    void setParameter(AudioUnitParameterID address, float value);
    
    /**
     * @brief Get parameter value for audio unit
     * @param address Parameter address
     * @return Current parameter value
     */
    float getParameter(AudioUnitParameterID address);
    
    /**
     * @brief Process audio through the Dugan algorithm
     * @param inBufferList Input audio buffers
     * @param outBufferList Output audio buffers
     * @param numFrames Number of frames to process
     * @return OSStatus indicating success or failure
     */
    OSStatus process(const AudioBufferList* inBufferList,
                   AudioBufferList* outBufferList,
                   UInt32 numFrames);
    
    // Add to WDSPKernel.h in the class declaration
    void setTimeConstants(float attackTime, float releaseTime);
    void setAdaptiveThreshold(float threshold);
    void setMasterGain(float gain);
    void applyPreset(int presetIndex);
    
    /**
     * @brief Reset the processor state
     */
    void reset();
    
    /**
     * @brief Set bypass state
     * @param bypass True to enable bypass, false for normal processing
     */
    void setBypass(bool bypass);
    
    /**
     * @brief Get current bypass state
     * @return True if bypassed, false otherwise
     */
    bool getBypass() const;
    
    /**
     * @brief Get DSP load as a percentage
     * @return DSP load (0.0-1.0)
     */
    float getDSPLoad() const;
    
    /**
     * @brief Get various statistics about the processor
     * @return Map of statistic names to values
     */
    std::map<std::string, float> getStatistics() const;
    
    /**
     * @brief Get peak level for a specific channel
     * @param channel Channel index
     * @return Peak level in dB
     */
    float getChannelPeakLevel(unsigned int channel) const;

    /**
     * @brief Get diagnostic information about kernel performance and state
     * @return WDSPDiagnosticInfoCpp struct with current diagnostics
     */
    WDSPDiagnosticInfoCpp getDiagnosticInfo() const;

private:
    std::unique_ptr<DuganProcessor> processor;
    double sampleRate;
    bool bypassState;
    float dspLoad;
    std::atomic<bool> processingActive;
    std::chrono::time_point<std::chrono::high_resolution_clock> processStartTime;
};
