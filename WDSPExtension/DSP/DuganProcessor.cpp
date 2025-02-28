#include "DuganProcessor.h"
#include <algorithm>
#include <numeric>
#include <cmath>
#include <stdexcept>
#include <chrono>
#include <vector>
#include <cstring> // For memcpy

// Define the thread-local variable (this was missing and caused the linker error)
thread_local std::vector<float> DuganProcessor::threadLocalBuffer;

// SIMD optimizations
#if defined(__ARM_NEON)
#include <arm_neon.h>
#define HAVE_SIMD 1
#elif defined(__SSE__)
#include <immintrin.h>
#define HAVE_SIMD 1
#endif

DuganProcessor::DuganProcessor(float sampleRate)
    : sampleRate(sampleRate),
      attackCoeff(0.0f),
      releaseCoeff(0.0f),
      smoothingCoeff(0.0f)
{
    // Initialize time constants based on sample rate
    setAttackTime(kDefaultAttackTime);
    setReleaseTime(kDefaultReleaseTime);
    setSmoothingTime(kSmoothingTime);
    
    // Initialize channel states
    reset();
    
    // Initialize statistics
    currentStats = {0.0f, 0.0f, 0.0f, 0, 0.0f};
    
    // Initialize performance monitoring
    lastProcessTime = std::chrono::high_resolution_clock::now();
}

DuganProcessor::~DuganProcessor() {
    // No additional cleanup required
}

void DuganProcessor::initialize(float sampleRate) {
    std::lock_guard<std::mutex> lock(processMutex);
    
    this->sampleRate = sampleRate;
    
    // Update time constants for new sample rate
    setAttackTime(kDefaultAttackTime);
    setReleaseTime(kDefaultReleaseTime);
    setSmoothingTime(kSmoothingTime);
    
    // Reset all states
    reset();
}

void DuganProcessor::reset() {
    std::lock_guard<std::mutex> lock(processMutex);
    
    for (size_t ch = 0; ch < kMaxChannels; ++ch) {
        channels[ch].weight = 1.0f;
        channels[ch].autoEnabled = true;
        channels[ch].overrideEnabled = false;
        channels[ch].inputLevel = kNoiseFloorThreshold;
        channels[ch].gainReduction = 0.0f;
        channels[ch].peakLevel = kNoiseFloorThreshold;
        channels[ch].envelope = kMinLevel;
        channels[ch].smoothedGain = 1.0f;
        channels[ch].lastRMS = kMinLevel;
        channels[ch].peakHoldCounter = 0;
        channels[ch].active = false;
    }
    
    // Reset statistics
    {
        std::lock_guard<std::mutex> statsLock(statsMutex);
        currentStats = {0.0f, 0.0f, 0.0f, 0, 0.0f};
    }
}

void DuganProcessor::setBypass(bool bypass) {
    bypassEnabled.store(bypass);
}

void DuganProcessor::process(const float* const* inputs, float* const* outputs,
                           size_t numChannels, size_t numSamples) {
    // Start timing for performance monitoring
    auto startTime = std::chrono::high_resolution_clock::now();
    
    // Check for bypass mode
    if (bypassEnabled.load()) {
        // In bypass mode, copy inputs to outputs directly
        for (size_t ch = 0; ch < numChannels; ++ch) {
            if (!inputs[ch] || !outputs[ch]) continue;
            memcpy(outputs[ch], inputs[ch], numSamples * sizeof(float));
        }
        return;
    }
    
    // Process mutex is used only for parameter changes, not during audio processing
    // to avoid blocking the audio thread
    
    // Validate inputs
    if (!inputs || !outputs) {
        throw std::invalid_argument("Null input/output pointers");
    }
    
    // Limit number of channels to maximum supported
    numChannels = std::min(numChannels, kMaxChannels);
    
    if (numChannels == 0 || numSamples == 0) {
        return;
    }
    
    // Three-step process for Dugan algorithm:
    // 1. Update input levels and envelopes
    #if HAVE_SIMD
        updateLevelsOptimized(inputs, numChannels, numSamples);
    #else
        updateLevels(inputs, numChannels, numSamples);
    #endif
    
    // 2. Compute gain values based on Dugan algorithm
    computeGains(numChannels);
    
    // 3. Apply gains to audio
    applyGains(inputs, outputs, numChannels, numSamples);
    
    // Update processing load metric
    auto endTime = std::chrono::high_resolution_clock::now();
    auto duration = std::chrono::duration_cast<std::chrono::microseconds>(endTime - startTime).count();
    float processingTimeMs = duration / 1000.0f;
    float bufferTimeMs = (numSamples / sampleRate) * 1000.0f;
    
    // Calculate CPU load as percentage of buffer duration
    float loadPercentage = (processingTimeMs / bufferTimeMs) * 100.0f;
    processingLoad.store(loadPercentage);
    
    // Update statistics
    {
        std::lock_guard<std::mutex> statsLock(statsMutex);
        currentStats.processingLoad = loadPercentage;
    }
}

void DuganProcessor::updateLevels(const float* const* inputs, size_t numChannels, size_t numSamples) {
    // For each channel, compute RMS level and update envelope
    for (size_t ch = 0; ch < numChannels; ++ch) {
        if (!inputs[ch]) {
            continue; // Skip null inputs
        }
        
        const float* input = inputs[ch];
        float& envelope = channels[ch].envelope;
        
        // Compute RMS level
        float sumSquared = 0.0f;
        float peakSample = 0.0f;
        
        for (size_t i = 0; i < numSamples; ++i) {
            float sample = input[i];
            float absSample = std::fabs(sample);
            sumSquared += sample * sample;
            peakSample = std::max(peakSample, absSample);
        }
        
        float rms = numSamples > 0 ? std::sqrt(sumSquared / numSamples) : 0.0f;
        
        // Store for statistics
        channels[ch].lastRMS = rms;
        
        // Apply appropriate time constant based on whether signal is rising or falling
        float coeff = (rms > envelope) ? attackCoeff : releaseCoeff;
        
        // Update envelope follower with smoothing
        envelope = computeEnvelope(rms, envelope, coeff);
        
        // Convert to dB for metering, ensuring it's above minimum level
        float levelDb = 20.0f * std::log10(std::max(envelope, kMinLevel));
        levelDb = std::clamp(levelDb, kNoiseFloorThreshold, 0.0f);  // Limit to -60 to 0 dB range for metering
        
        // Store level for metering
        channels[ch].inputLevel = levelDb;
        
        // Handle peak metering with 2-second hold time
        float peakDb = 20.0f * std::log10(std::max(peakSample, kMinLevel));
        peakDb = std::clamp(peakDb, kNoiseFloorThreshold, 0.0f);
        
        float currentPeak = channels[ch].peakLevel;
        if (peakDb > currentPeak) {
            channels[ch].peakLevel = peakDb;
            channels[ch].peakHoldCounter = static_cast<int>(2.0f * sampleRate / numSamples); // 2-second hold
        } else if (channels[ch].peakHoldCounter > 0) {
            channels[ch].peakHoldCounter--;
        } else {
            // Peak hold time expired, decay peak by 3dB per update
            float decayedPeak = currentPeak - 3.0f;
            // Don't let it go below current level
            decayedPeak = std::max(decayedPeak, levelDb);
            channels[ch].peakLevel = decayedPeak;
        }
    }
}

#if HAVE_SIMD
void DuganProcessor::updateLevelsOptimized(const float* const* inputs, size_t numChannels, size_t numSamples) {
    // SIMD optimized version of updateLevels
    for (size_t ch = 0; ch < numChannels; ++ch) {
        if (!inputs[ch]) {
            continue; // Skip null inputs
        }
        
        const float* input = inputs[ch];
        float& envelope = channels[ch].envelope;
        
        float sumSquared = 0.0f;
        float peakSample = 0.0f;
        
        // Ensure we have enough space in thread-local buffer
        if (threadLocalBuffer.size() < numSamples) {
            threadLocalBuffer.resize(numSamples);
        }
        
        #if defined(__ARM_NEON)
        // ARM NEON SIMD implementation
        size_t i = 0;
        float32x4_t sum4 = vdupq_n_f32(0.0f);
        float32x4_t peak4 = vdupq_n_f32(0.0f);
        
        // Process 4 samples at a time
        for (; i + 3 < numSamples; i += 4) {
            float32x4_t samples = vld1q_f32(&input[i]);
            float32x4_t squares = vmulq_f32(samples, samples);
            sum4 = vaddq_f32(sum4, squares);
            
            float32x4_t abs_samples = vabsq_f32(samples);
            peak4 = vmaxq_f32(peak4, abs_samples);
        }
        
        // Extract results from vector registers
        float sum_array[4];
        float peak_array[4];
        vst1q_f32(sum_array, sum4);
        vst1q_f32(peak_array, peak4);
        
        sumSquared = sum_array[0] + sum_array[1] + sum_array[2] + sum_array[3];
        peakSample = std::max(std::max(peak_array[0], peak_array[1]),
                            std::max(peak_array[2], peak_array[3]));
        
        // Process remaining samples
        for (; i < numSamples; ++i) {
            float sample = input[i];
            sumSquared += sample * sample;
            peakSample = std::max(peakSample, std::fabs(sample));
        }
        #elif defined(__SSE__)
        // SSE SIMD implementation
        size_t i = 0;
        __m128 sum4 = _mm_setzero_ps();
        __m128 peak4 = _mm_setzero_ps();
        
        // Process 4 samples at a time
        for (; i + 3 < numSamples; i += 4) {
            __m128 samples = _mm_loadu_ps(&input[i]);
            __m128 squares = _mm_mul_ps(samples, samples);
            sum4 = _mm_add_ps(sum4, squares);
            
            // Get absolute values
            __m128 abs_mask = _mm_set1_ps(-0.0f);
            __m128 abs_samples = _mm_andnot_ps(abs_mask, samples);
            peak4 = _mm_max_ps(peak4, abs_samples);
        }
        
        // Extract results from vector registers
        float sum_array[4];
        float peak_array[4];
        _mm_storeu_ps(sum_array, sum4);
        _mm_storeu_ps(peak_array, peak4);
        
        sumSquared = sum_array[0] + sum_array[1] + sum_array[2] + sum_array[3];
        peakSample = std::max(std::max(peak_array[0], peak_array[1]),
                            std::max(peak_array[2], peak_array[3]));
        
        // Process remaining samples
        for (; i < numSamples; ++i) {
            float sample = input[i];
            sumSquared += sample * sample;
            peakSample = std::max(peakSample, std::fabs(sample));
        }
        #endif
        
        // Same processing as non-optimized version for the envelope and metering
        float rms = numSamples > 0 ? std::sqrt(sumSquared / numSamples) : 0.0f;
        
        channels[ch].lastRMS = rms;
        
        float coeff = (rms > envelope) ? attackCoeff : releaseCoeff;
        envelope = computeEnvelope(rms, envelope, coeff);
        
        float levelDb = 20.0f * std::log10(std::max(envelope, kMinLevel));
        levelDb = std::clamp(levelDb, kNoiseFloorThreshold, 0.0f);
        
        channels[ch].inputLevel = levelDb;
        
        float peakDb = 20.0f * std::log10(std::max(peakSample, kMinLevel));
        peakDb = std::clamp(peakDb, kNoiseFloorThreshold, 0.0f);
        
        float currentPeak = channels[ch].peakLevel;
        if (peakDb > currentPeak) {
            channels[ch].peakLevel = peakDb;
            channels[ch].peakHoldCounter = static_cast<int>(2.0f * sampleRate / numSamples);
        } else if (channels[ch].peakHoldCounter > 0) {
            channels[ch].peakHoldCounter--;
        } else {
            float decayedPeak = currentPeak - 3.0f;
            decayedPeak = std::max(decayedPeak, levelDb);
            channels[ch].peakLevel = decayedPeak;
        }
    }
}
#endif

float DuganProcessor::getAttackTime() const {
    // Convert coefficient back to time in milliseconds
    if (attackCoeff > 0.0f && attackCoeff < 1.0f) {
        return -1000.0f * logf(1.0f - attackCoeff) / sampleRate;
    }
    return 10.0f; // Default value
}

float DuganProcessor::getReleaseTime() const {
    // Convert coefficient back to time in milliseconds
    if (releaseCoeff > 0.0f && releaseCoeff < 1.0f) {
        return -1000.0f * logf(1.0f - releaseCoeff) / sampleRate;
    }
    return 100.0f; // Default value
}
void DuganProcessor::applyGains(const float* const* inputs, float* const* outputs,
                              size_t numChannels, size_t numSamples) {
    // Use optimized version when possible, otherwise fall back to regular implementation
    #if defined(__APPLE__) || defined(__SSE__) || defined(__AVX__)
        applyGainsOptimized(inputs, outputs, numChannels, numSamples);
    #else
        applyGainsRegular(inputs, outputs, numChannels, numSamples);
    #endif
}

// Regular implementation (used as fallback)
void DuganProcessor::applyGainsRegular(const float* const* inputs, float* const* outputs,
                                     size_t numChannels, size_t numSamples) {
    // Apply calculated gains to each channel
    for (size_t ch = 0; ch < numChannels; ++ch) {
        if (!inputs[ch] || !outputs[ch]) {
            continue; // Skip null inputs/outputs
        }
        
        const float* input = inputs[ch];
        float* output = outputs[ch];
        const float gain = channels[ch].smoothedGain;
        
        // Apply gain to audio samples
        for (size_t i = 0; i < numSamples; ++i) {
            output[i] = input[i] * gain;
        }
    }
}

// SIMD optimized implementation
void DuganProcessor::applyGainsOptimized(const float* const* inputs, float* const* outputs,
                                         size_t numChannels, size_t numSamples) {
    // Apply calculated gains to each channel with SIMD optimization
    for (size_t ch = 0; ch < numChannels; ++ch) {
        if (!inputs[ch] || !outputs[ch]) {
            continue; // Skip null inputs/outputs
        }
        
        const float* input = inputs[ch];
        float* output = outputs[ch];
        const float gain = channels[ch].smoothedGain;
        
        // Use platform-specific SIMD optimization
#if defined(__AVX__)
        // AVX optimization for 8-float vectors
        const __m256 gainVec = _mm256_set1_ps(gain);
        const size_t vectorSize = 8;
        const size_t vectorizedLength = (numSamples / vectorSize) * vectorSize;
        
        // Process 8 samples at a time
        for (size_t i = 0; i < vectorizedLength; i += vectorSize) {
            __m256 inputVec = _mm256_loadu_ps(&input[i]);
            __m256 outputVec = _mm256_mul_ps(inputVec, gainVec);
            _mm256_storeu_ps(&output[i], outputVec);
        }
        
        // Process remaining samples
        for (size_t i = vectorizedLength; i < numSamples; ++i) {
            output[i] = input[i] * gain;
        }
#elif defined(__SSE__)
        // SSE optimization for 4-float vectors
        const __m128 gainVec = _mm_set1_ps(gain);
        const size_t vectorSize = 4;
        const size_t vectorizedLength = (numSamples / vectorSize) * vectorSize;
        
        // Process 4 samples at a time
        for (size_t i = 0; i < vectorizedLength; i += vectorSize) {
            __m128 inputVec = _mm_loadu_ps(&input[i]);
            __m128 outputVec = _mm_mul_ps(inputVec, gainVec);
            _mm_storeu_ps(&output[i], outputVec);
        }
        
        // Process remaining samples
        for (size_t i = vectorizedLength; i < numSamples; ++i) {
            output[i] = input[i] * gain;
        }
#elif defined(__APPLE__) && defined(__ARM_NEON)
        // Apple Silicon NEON optimization for 4-float vectors
        const float32x4_t gainVec = vdupq_n_f32(gain);
        const size_t vectorSize = 4;
        const size_t vectorizedLength = (numSamples / vectorSize) * vectorSize;
        
        // Process 4 samples at a time
        for (size_t i = 0; i < vectorizedLength; i += vectorSize) {
            float32x4_t inputVec = vld1q_f32(&input[i]);
            float32x4_t outputVec = vmulq_f32(inputVec, gainVec);
            vst1q_f32(&output[i], outputVec);
        }
        
        // Process remaining samples
        for (size_t i = vectorizedLength; i < numSamples; ++i) {
            output[i] = input[i] * gain;
        }
#else
        // Fallback to regular processing if no SIMD is available
        for (size_t i = 0; i < numSamples; ++i) {
            output[i] = input[i] * gain;
        }
#endif
    }
}


float DuganProcessor::computeEnvelope(float input, float envelope, float coeff) const {
    // First-order IIR filter for smooth envelope following
    return envelope * coeff + input * (1.0f - coeff);
}

float DuganProcessor::smoothGain(float currentGain, float targetGain, float coeff) const {
    // Apply smoothing to gain changes to prevent zipper noise
    return currentGain * coeff + targetGain * (1.0f - coeff);
}

// Parameter setters with thread safety and validation
void DuganProcessor::setChannelWeight(size_t channel, float weight) {
    if (channel < kMaxChannels) {
        channels[channel].weight = std::max(0.0f, std::min(10.0f, weight));
    }
}

void DuganProcessor::setChannelAutoEnabled(size_t channel, bool enabled) {
    if (channel < kMaxChannels) {
        channels[channel].autoEnabled = enabled;
    }
}

void DuganProcessor::setChannelOverride(size_t channel, bool override) {
    if (channel < kMaxChannels) {
        channels[channel].overrideEnabled = override;
    }
}

void DuganProcessor::setAttackTime(float timeInSeconds) {
    std::lock_guard<std::mutex> lock(processMutex);
    float time = std::clamp(timeInSeconds, 0.001f, 1.0f);  // Limit range
    attackCoeff = std::exp(-1.0f / (time * sampleRate));
}

void DuganProcessor::setReleaseTime(float timeInSeconds) {
    std::lock_guard<std::mutex> lock(processMutex);
    float time = std::clamp(timeInSeconds, 0.01f, 2.0f);  // Limit range
    releaseCoeff = std::exp(-1.0f / (time * sampleRate));
}

void DuganProcessor::setSmoothingTime(float timeInSeconds) {
    std::lock_guard<std::mutex> lock(processMutex);
    float time = std::clamp(timeInSeconds, 0.001f, 0.5f);  // Limit range
    smoothingCoeff = std::exp(-1.0f / (time * sampleRate));
}

// State getters with thread safety
float DuganProcessor::getChannelInputLevel(size_t channel) const {
    if (channel >= kMaxChannels) {
        return kNoiseFloorThreshold;  // Return minimum level for invalid channel
    }
    return channels[channel].inputLevel;
}

float DuganProcessor::getChannelGainReduction(size_t channel) const {
    if (channel >= kMaxChannels) {
        return 0.0f;  // Return no reduction for invalid channel
    }
    return channels[channel].gainReduction;
}

float DuganProcessor::getChannelPeakLevel(size_t channel) const {
    if (channel >= kMaxChannels) {
        return kNoiseFloorThreshold;
    }
    return channels[channel].peakLevel;
}

bool DuganProcessor::isChannelAutoEnabled(size_t channel) const {
    if (channel >= kMaxChannels) {
        return false;
    }
    return channels[channel].autoEnabled;
}

bool DuganProcessor::isChannelOverride(size_t channel) const {
    if (channel >= kMaxChannels) {
        return false;
    }
    return channels[channel].overrideEnabled;
}

float DuganProcessor::getChannelWeight(size_t channel) const {
    if (channel >= kMaxChannels) {
        return 1.0f;
    }
    return channels[channel].weight;
}

DuganProcessor::Statistics DuganProcessor::getStatistics() const {
    std::lock_guard<std::mutex> statsLock(statsMutex);
    return currentStats;
}
// Modify the setMasterGain method
void DuganProcessor::setMasterGain(float gain) {
    std::lock_guard<std::mutex> lock(processMutex);
    masterGain = std::clamp(gain, -12.0f, 12.0f);
}

// Update the computeGains method to use the member variables
void DuganProcessor::computeGains(size_t numChannels) {
    // Calculate total weighted level and check for override channels
    totalWeightedLevel = 0.0f;
    activeChannelCount = 0;
    bool anyOverride = false;
    
    // First pass: check for override channels and calculate total weighted level
    for (size_t ch = 0; ch < numChannels; ++ch) {
        const auto& channel = channels[ch];
        
        // Check if any channel is in override mode
        if (channel.overrideEnabled) {
            anyOverride = true;
        }
        
        if (channel.autoEnabled) {
            // Convert dB level back to linear for gain calculations
            float linearLevel = std::pow(10.0f, channel.inputLevel / 20.0f);
            
            // Apply weight to level calculation (key feature of Dugan algorithm)
            totalWeightedLevel += linearLevel * channel.weight;
            
            // Count channel as active if level is above threshold
            if (channel.inputLevel > adaptiveThreshold) {
                activeChannelCount++;
            }
        }
    }
    
    // Ensure minimum level to prevent division by zero
    totalWeightedLevel = std::max(totalWeightedLevel, kMinLevel);
    
    // Track statistics for gain reduction
    float totalGainReduction = 0.0f;
    float maxGainReduction = 0.0f;
    float totalInputLevel = 0.0f;
    
    // Second pass: compute gain for each channel using Dugan formula
    for (size_t ch = 0; ch < numChannels; ++ch) {
        auto& channel = channels[ch];
        float targetGain = 0.0f;
        
        if (anyOverride) {
            // If any channel is in override mode
            if (channel.overrideEnabled) {
                // Override channels get full gain
                targetGain = 1.0f;
            } else {
                // Non-override channels get attenuated significantly
                targetGain = 0.1f; // -20 dB
            }
        } else if (!channel.autoEnabled) {
            // Manual mode: pass through at unity gain
            targetGain = 1.0f;
        } else {
            // Auto mode: apply Dugan algorithm
            // Convert dB level back to linear for calculations
            float linearLevel = std::pow(10.0f, channel.inputLevel / 20.0f);
            const float weight = channel.weight;
            
            // Core Dugan formula: gain = sqrt(channel_level * weight / total_level)
            // This maintains NOM=1 (Number of Open Mics = 1)
            targetGain = std::sqrt((linearLevel * weight) / totalWeightedLevel);
            
            // Apply NOM attenuation if many channels are active
            if (activeChannelCount > 1) {
                // Slightly reduce overall gain to maintain unity gain
                targetGain *= 0.9f;
            }
        }
        
        // Apply master gain (convert from dB to linear multiplier)
        float masterGainMultiplier = std::pow(10.0f, masterGain / 20.0f);
        targetGain *= masterGainMultiplier;
        
        // Smooth gain changes to avoid artifacts
        channel.smoothedGain = smoothGain(channel.smoothedGain, targetGain, smoothingCoeff);
        
        // Store gain reduction in dB for metering
        const float gainReduction = -20.0f * std::log10(std::max(channel.smoothedGain, kMinLevel));
        float clampedGainReduction = std::clamp(gainReduction, -30.0f, 0.0f);
        channel.gainReduction = clampedGainReduction;
        
        // Update statistics
        totalGainReduction += clampedGainReduction;
        maxGainReduction = std::min(maxGainReduction, clampedGainReduction); // More negative = more reduction
        totalInputLevel += channel.inputLevel;
    }
    
    // Update statistics
    {
        std::lock_guard<std::mutex> statsLock(statsMutex);
        currentStats.averageGainReduction = numChannels > 0 ? totalGainReduction / numChannels : 0.0f;
        currentStats.peakGainReduction = maxGainReduction;
        currentStats.averageInputLevel = numChannels > 0 ? totalInputLevel / numChannels : kNoiseFloorThreshold;
        currentStats.activeChannels = activeChannelCount;
    }
}

void DuganProcessor::setAdaptiveThreshold(float threshold) {
    // Clamp threshold to reasonable values (e.g., -60dB to -20dB)
    adaptiveThreshold = std::max(-60.0f, std::min(-20.0f, threshold));
}

float DuganProcessor::getAdaptiveThreshold() const {
    return adaptiveThreshold;
}

float DuganProcessor::getMasterGain() const {
    return masterGain;
}

int DuganProcessor::getActiveChannelCount() const {
    int count = 0;
    for (size_t ch = 0; ch < kMaxChannels; ++ch) {
        if (channels[ch].active) {
            count++;
        }
    }
    return count;
}

float DuganProcessor::getTotalWeightedLevel() const {
    return totalWeightedLevel;
}

float DuganProcessor::getMasterGainReduction() const {
    return masterGainReduction;
}
