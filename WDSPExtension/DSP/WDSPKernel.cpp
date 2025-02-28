#include "WDSPKernel.h"
#include "DuganProcessor.h"
#include <algorithm>
#include <cstring>
#include <chrono>
#include <cmath>
#include <iostream>

/**
 * Constructor initializes the kernel with default values
 */
WDSPKernel::WDSPKernel()
    : sampleRate(44100.0),
      bypassState(false),
      dspLoad(0.0f),
      processingActive(false)
{
    // Create processor with default sample rate
    processor = std::make_unique<DuganProcessor>(static_cast<float>(sampleRate));
}

/**
 * Destructor ensures clean resource release
 */
WDSPKernel::~WDSPKernel() {
    // Smart pointer automatically cleans up processor
}

/**
 * Initialize or reinitialize the kernel with a new sample rate
 */
void WDSPKernel::initialize(double sampleRate) {
    if (this->sampleRate != sampleRate || !processor) {
        this->sampleRate = sampleRate;
        processor = std::make_unique<DuganProcessor>(static_cast<float>(sampleRate));
    } else {
        processor->initialize(static_cast<float>(sampleRate));
    }
}

/**
 * Set parameter value from audio unit
 */
void WDSPKernel::setParameter(AudioUnitParameterID address, float value) {
    if (!processor) return;
    
    // Calculate channel and parameter type from address
    // 5 parameters per channel: weight, auto, override, input meter, gain reduction
    size_t channel = address / 5;
    size_t param = address % 5;
    
    // Special handling for global parameters
    if (address >= 20) {
        // Global parameters start from address 20
        switch (address) {
            case 20: // Master Gain
                setMasterGain(value);
                break;
            case 21: // Attack Time
                // Convert from seconds to milliseconds (UI shows seconds)
                setTimeConstants(value * 1000.0f, -1.0f); // -1 means "don't change"
                break;
            case 22: // Release Time
                // Convert from seconds to milliseconds (UI shows seconds)
                setTimeConstants(-1.0f, value * 1000.0f); // -1 means "don't change"
                break;
            case 23: // Adaptive Threshold
                setAdaptiveThreshold(value);
                break;
            case 24: // Preset selector
                applyPreset(static_cast<int>(value));
                break;
        }
        return;
    }
    
    // Ensure channel is in valid range
    if (channel >= DuganProcessor::kMaxChannels) {
        return;
    }
    
    // Channel specific parameters
    switch (param) {
        case 0: // Weight
            processor->setChannelWeight(channel, value);
            break;
        case 1: // Auto Enable
            processor->setChannelAutoEnabled(channel, value >= 0.5f);
            break;
        case 2: // Override
            processor->setChannelOverride(channel, value >= 0.5f);
            break;
        // Parameters 3 and 4 are meter values (read-only, no handling needed)
    }
}

/**
 * Get parameter value for audio unit
 */
float WDSPKernel::getParameter(AudioUnitParameterID address) {
    if (!processor) return 0.0f;
    
    // Handle global parameters (addresses 20+)
    if (address >= 20) {
        switch (address) {
            case 20: // Master Gain
                return processor->getMasterGain();
            case 21: // Attack Time (in seconds for UI)
                return processor->getAttackTime() / 1000.0f; // Convert ms to seconds
            case 22: // Release Time (in seconds for UI)
                return processor->getReleaseTime() / 1000.0f; // Convert ms to seconds
            case 23: // Adaptive Threshold
                return processor->getAdaptiveThreshold();
            case 24: // Preset selector
                return 0.0f; // Just return 0 as preset selector doesn't have persistent state
            default:
                return 0.0f;
        }
    }
    
    // Handle channel-specific parameters
    size_t channel = address / 5;
    size_t param = address % 5;
    
    // Ensure channel is in valid range
    if (channel >= DuganProcessor::kMaxChannels) {
        return 0.0f;
    }
    
    switch (param) {
        case 0: // Weight
            return processor->getChannelWeight(channel);
        case 1: // Auto Enable
            return processor->isChannelAutoEnabled(channel) ? 1.0f : 0.0f;
        case 2: // Override
            return processor->isChannelOverride(channel) ? 1.0f : 0.0f;
        case 3: // Input Meter
            return processor->getChannelInputLevel(channel);
        case 4: // Gain Reduction
            return processor->getChannelGainReduction(channel);
        default:
            return 0.0f;
    }
}

/**
 * Process audio through the Dugan algorithm
 * This is the core real-time audio callback
 */
OSStatus WDSPKernel::process(const AudioBufferList* inBufferList,
                           AudioBufferList* outBufferList,
                           UInt32 numFrames) {
    if (!processor) return kAudioUnitErr_NoConnection;
    
    // Validate frames to process
    if (numFrames == 0) return noErr;
    
    // Skip processing if bypassed
    if (bypassState) {
        // Just copy input to output
        for (UInt32 i = 0; i < inBufferList->mNumberBuffers; ++i) {
            if (i >= outBufferList->mNumberBuffers) break; // Prevent buffer overrun
            
            const AudioBuffer& inBuffer = inBufferList->mBuffers[i];
            AudioBuffer& outBuffer = outBufferList->mBuffers[i];
            
            // Make sure we don't copy more than the destination can hold
            UInt32 bytesToCopy = std::min(inBuffer.mDataByteSize, outBuffer.mDataByteSize);
            if (bytesToCopy > 0 && inBuffer.mData && outBuffer.mData) {
                memcpy(outBuffer.mData, inBuffer.mData, bytesToCopy);
            }
        }
        return noErr;
    }
    
    // Start timing for DSP load calculation
    processingActive = true;
    auto startTime = std::chrono::high_resolution_clock::now();
    
    // Determine how many channels we can process
    UInt32 inputBufferCount = inBufferList ? inBufferList->mNumberBuffers : 0;
    UInt32 outputBufferCount = outBufferList ? outBufferList->mNumberBuffers : 0;
    
    if (inputBufferCount == 0 || outputBufferCount == 0) {
        // No input or output buffers, nothing to do
        return noErr;
    }
    
    // Limit to minimum of input and output buffer counts
    UInt32 bufferCount = std::min(inputBufferCount, outputBufferCount);
    bufferCount = std::min(bufferCount, static_cast<UInt32>(DuganProcessor::kMaxChannels));
    
    // Temporary arrays for input/output pointers
    const float* inputPtrs[DuganProcessor::kMaxChannels] = {nullptr};
    float* outputPtrs[DuganProcessor::kMaxChannels] = {nullptr};
    
    // Setup input/output buffer pointers
    for (UInt32 i = 0; i < bufferCount; ++i) {
        // Get input buffer
        const AudioBuffer& inBuffer = inBufferList->mBuffers[i];
        
        // Get output buffer
        AudioBuffer& outBuffer = outBufferList->mBuffers[i];
        
        // Validate buffer size
        if (inBuffer.mDataByteSize < (numFrames * sizeof(float)) ||
            !inBuffer.mData || !outBuffer.mData) {
            
            // Input buffer too small or invalid pointers, handle error gracefully
            // Zero the corresponding output buffer
            if (outBuffer.mData && outBuffer.mDataByteSize >= (numFrames * sizeof(float))) {
                memset(outBuffer.mData, 0, numFrames * sizeof(float));
            }
            
            // Skip this channel
            continue;
        }
        
        // Ensure output buffer is large enough
        if (outBuffer.mDataByteSize < (numFrames * sizeof(float))) {
            // Output buffer too small, skip this channel
            continue;
        }
        
        // Set up pointers for processing
        inputPtrs[i] = static_cast<const float*>(inBuffer.mData);
        outputPtrs[i] = static_cast<float*>(outBuffer.mData);
    }
    
    // Zero any remaining output channels
    for (UInt32 i = bufferCount; i < outputBufferCount; ++i) {
        AudioBuffer& outBuffer = outBufferList->mBuffers[i];
        if (outBuffer.mData && outBuffer.mDataByteSize >= (numFrames * sizeof(float))) {
            float* output = static_cast<float*>(outBuffer.mData);
            memset(output, 0, numFrames * sizeof(float));
        }
    }
    
    try {
        // Process audio through the Dugan processor
        processor->process(
            inputPtrs,
            outputPtrs,
            bufferCount,
            numFrames
        );
    } catch (const std::exception& e) {
        // Log error but continue
        fprintf(stderr, "Exception in Dugan processing: %s\n", e.what());
        
        // In case of error, copy input to output for graceful degradation
        for (UInt32 i = 0; i < bufferCount; ++i) {
            if (inputPtrs[i] && outputPtrs[i]) {
                memcpy(outputPtrs[i], inputPtrs[i], numFrames * sizeof(float));
            }
        }
    }
    
    // Finish timing and calculate DSP load
    auto endTime = std::chrono::high_resolution_clock::now();
    std::chrono::duration<float> processingTime = endTime - startTime;
    
    // Calculate available time for processing this buffer at current sample rate
    float bufferDuration = static_cast<float>(numFrames) / static_cast<float>(sampleRate);
    
    // Calculate DSP load as percentage of available time
    float currentLoad = processingTime.count() / bufferDuration;
    
    // Smooth the DSP load value with a simple IIR filter
    dspLoad = dspLoad * 0.9f + currentLoad * 0.1f;
    
    processingActive = false;
    return noErr;
}

/**
 * Reset the processor state
 */
void WDSPKernel::reset() {
    if (processor) {
        processor->reset();
    }
}

/**
 * Set bypass state
 */
void WDSPKernel::setBypass(bool bypass) {
    bypassState = bypass;
    if (processor) {
        processor->setBypass(bypass);
    }
}

/**
 * Get bypass state
 */
bool WDSPKernel::getBypass() const {
    return bypassState;
}

/**
 * Apply preset to automixer parameters
 *
 * @param presetIndex Index of the preset to apply (0-3)
 */
void WDSPKernel::applyPreset(int presetIndex) {
    if (!processor) return;
    
    // Define a few common presets
    switch (presetIndex) {
        case 0: // Default - Balanced
            for (size_t ch = 0; ch < DuganProcessor::kMaxChannels; ++ch) {
                processor->setChannelWeight(ch, 1.0f);
                processor->setChannelAutoEnabled(ch, true);
                processor->setChannelOverride(ch, false);
            }
            processor->setAttackTime(0.01f);  // 10ms attack
            processor->setReleaseTime(0.1f);  // 100ms release
            processor->setAdaptiveThreshold(-40.0f); // Default threshold
            processor->setMasterGain(0.0f);   // 0dB gain
            break;
            
        case 1: // Conference - Fast response
            for (size_t ch = 0; ch < DuganProcessor::kMaxChannels; ++ch) {
                processor->setChannelWeight(ch, 1.0f);
                processor->setChannelAutoEnabled(ch, true);
                processor->setChannelOverride(ch, false);
            }
            processor->setAttackTime(0.005f);  // 5ms attack
            processor->setReleaseTime(0.05f);  // 50ms release
            processor->setAdaptiveThreshold(-45.0f); // More sensitive threshold
            processor->setMasterGain(0.0f);
            break;
            
        case 2: // Music - Smooth transitions
            for (size_t ch = 0; ch < DuganProcessor::kMaxChannels; ++ch) {
                processor->setChannelWeight(ch, 1.0f);
                processor->setChannelAutoEnabled(ch, true);
                processor->setChannelOverride(ch, false);
            }
            processor->setAttackTime(0.02f);   // 20ms attack
            processor->setReleaseTime(0.2f);   // 200ms release
            processor->setAdaptiveThreshold(-35.0f); // Less sensitive threshold
            processor->setMasterGain(0.0f);
            break;
            
        case 3: // Presentation - Main mic focus (ch 1)
            for (size_t ch = 0; ch < DuganProcessor::kMaxChannels; ++ch) {
                processor->setChannelWeight(ch, ch == 0 ? 1.5f : 0.8f);
                processor->setChannelAutoEnabled(ch, true);
                processor->setChannelOverride(ch, ch == 0);  // Ch 1 override on
            }
            processor->setAttackTime(0.01f);
            processor->setReleaseTime(0.15f);
            processor->setAdaptiveThreshold(-40.0f);
            processor->setMasterGain(0.0f);
            break;
    }
}

/**
 * Set time constants for envelope followers
 *
 * @param attackTime Attack time in milliseconds (-1 to keep current value)
 * @param releaseTime Release time in milliseconds (-1 to keep current value)
 */
void WDSPKernel::setTimeConstants(float attackTime, float releaseTime) {
    if (!processor) return;
    
    // Only update the values that aren't set to -1
    if (attackTime >= 0.0f) {
        // Convert from ms to seconds for processor
        processor->setAttackTime(attackTime / 1000.0f);
    }
    
    if (releaseTime >= 0.0f) {
        // Convert from ms to seconds for processor
        processor->setReleaseTime(releaseTime / 1000.0f);
    }
}

/**
 * Set adaptive threshold for activity detection
 *
 * @param threshold Threshold value in dB (typically -60 to -20)
 */
void WDSPKernel::setAdaptiveThreshold(float threshold) {
    if (processor) {
        processor->setAdaptiveThreshold(threshold);
    }
}

/**
 * Set master output gain
 *
 * @param gain Gain value in dB (-12 to +12 typical range)
 */
void WDSPKernel::setMasterGain(float gain) {
    if (processor) {
        processor->setMasterGain(gain);
    }
}

/**
 * Get current DSP load as a percentage (0-1)
 */
float WDSPKernel::getDSPLoad() const {
    return dspLoad;
}

/**
 * Get various statistics about the processor
 * Useful for displaying information to the user
 */
std::map<std::string, float> WDSPKernel::getStatistics() const {
    std::map<std::string, float> stats;
    
    stats["dsp_load"] = dspLoad;
    stats["sample_rate"] = static_cast<float>(sampleRate);
    
    // Add more statistics as needed
    if (processor) {
        // Global stats
        stats["active_channels"] = static_cast<float>(processor->getActiveChannelCount());
        stats["master_reduction"] = processor->getMasterGainReduction();
        stats["adaptive_threshold"] = processor->getAdaptiveThreshold();
        stats["total_weighted_level"] = processor->getTotalWeightedLevel();
        
        // Channel-specific stats
        for (size_t ch = 0; ch < DuganProcessor::kMaxChannels; ++ch) {
            std::string prefix = "ch" + std::to_string(ch+1) + "_";
            stats[prefix + "input"] = processor->getChannelInputLevel(ch);
            stats[prefix + "gain"] = processor->getChannelGainReduction(ch);
            stats[prefix + "weight"] = processor->getChannelWeight(ch);
            stats[prefix + "auto"] = processor->isChannelAutoEnabled(ch) ? 1.0f : 0.0f;
            stats[prefix + "override"] = processor->isChannelOverride(ch) ? 1.0f : 0.0f;
            stats[prefix + "peak"] = processor->getChannelPeakLevel(ch);
        }
    }
    
    return stats;
}

/**
 * Get peak level for a specified channel
 */
float WDSPKernel::getChannelPeakLevel(unsigned int channel) const {
    if (!processor || channel >= DuganProcessor::kMaxChannels) {
        return -60.0f;  // Return minimum level
    }
    
    return processor->getChannelPeakLevel(channel);
}

/**
 * Get diagnostic information about the kernel
 */
WDSPDiagnosticInfoCpp WDSPKernel::getDiagnosticInfo() const {
    // Initialize all fields to safe defaults
    WDSPDiagnosticInfoCpp info = {};
    info.inputLevel = -100.0f;  // Set to minimum by default
    info.outputLevel = -100.0f;
    
    // Set current processing state
    info.averageLoad = dspLoad;
    info.peakLoad = dspLoad;  // Could be refined to track peak load independently
    info.overloads = 0;       // We could track overloads if needed
    info.wasBypassEngaged = bypassState;
    info.isBypassEngaged = bypassState;
    
    // Only try to access processor if it exists
    if (processor != nullptr) {
        try {
            // Access channel 0 (first channel)
            const unsigned int channel = 0;
            
            // Get input level from first channel
            info.inputLevel = processor->getChannelInputLevel(channel);
            
            // Note: DuganProcessor doesn't have getChannelOutputLevel,
            // so we use getChannelPeakLevel as the closest equivalent
            info.outputLevel = processor->getChannelPeakLevel(channel);
            
            // Debug output to console
            std::cout << "WDSP Diagnostic info - Input: " << info.inputLevel 
                      << " dB, Output (Peak): " << info.outputLevel 
                      << " dB, CPU: " << info.averageLoad * 100.0f 
                      << "%, Bypass: " << (info.isBypassEngaged ? "On" : "Off") 
                      << std::endl;
        } catch (...) {
            // In case of any exception reading from processor
            std::cout << "Exception in getDiagnosticInfo while reading levels" << std::endl;
        }
    } else {
        // Debug output for null processor
        std::cout << "Diagnostic info error: Processor is null" << std::endl;
    }
    
    return info;
}
