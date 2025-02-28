#pragma once

#include <vector>
#include <memory>
#include <cmath>
#include <atomic>
#include <array>
#include <mutex>
#include <thread>

/**
 * @class DuganProcessor
 * @brief Professional implementation of Dan Dugan's automatic mixer algorithm
 *
 * This processor implements the classic Dugan gain sharing algorithm for automatic
 * mixing of multiple microphone inputs. It maintains constant total gain regardless
 * of how many microphones are active, preventing feedback and noise buildup while
 * providing smooth transitions between speakers.
 *
 * The implementation supports channel weighting, override functionality, and metering
 * with advanced statistical analysis for optimal gain control.
 */
class DuganProcessor {
public:
    // Constants for DSP processing
    static constexpr float kMinLevel = 1e-6f;         // -120 dB noise floor
    static constexpr float kMaxWeight = 2.0f;         // Maximum channel weight
    static constexpr float kDefaultWeight = 1.0f;     // Default weight value
    static constexpr size_t kMaxChannels = 4;         // Maximum supported channels
    static constexpr float kDefaultAttackTime = 0.01f;  // 10ms attack time
    static constexpr float kDefaultReleaseTime = 0.1f;  // 100ms release time
    static constexpr float kSmoothingTime = 0.05f;    // 50ms parameter smoothing
    static constexpr float kNoiseFloorThreshold = -60.0f; // Noise floor in dB

    /**
     * @struct ChannelState
     * @brief Contains per-channel state data for the automixer
     */
    struct ChannelState {
        std::atomic<float> weight{kDefaultWeight};    // Channel weight (0.0 - 2.0)
        std::atomic<bool> autoEnabled{true};          // Auto mixing enabled
        std::atomic<bool> override{false};            // Override status
        std::atomic<float> inputLevel{0.0f};          // Current input level (dB)
        std::atomic<float> gainReduction{0.0f};       // Current gain reduction in dB
        std::atomic<float> peakLevel{0.0f};           // Peak level (dB) for metering
        float envelope{0.0f};                         // Envelope follower state
        float smoothedGain{1.0f};                     // Smoothed gain value
        float lastRMS{0.0f};                          // Last RMS value for statistics
        float peakHoldCounter{0};                     // Counter for peak hold
    };
    float getTotalWeightedLevel() const;
    int getActiveChannelCount() const;
    float getMasterGainReduction() const;
    double getCPULoad() const;
    float getAdaptiveThreshold() const;
    float getMasterGain() const;
    float getAttackTime() const;
    float getReleaseTime() const;

    /**
     * @brief Constructor
     * @param sampleRate The audio sample rate
     */
    explicit DuganProcessor(float sampleRate);
    
    /**
     * @brief Destructor
     */
    ~DuganProcessor();
    
    /**
     * @brief Initialize the processor with a new sample rate
     * @param sampleRate The audio sample rate
     */
    void initialize(float sampleRate);
    
    /**
     * @brief Process audio through the Dugan algorithm
     * @param inputs Array of input channel pointers
     * @param outputs Array of output channel pointers
     * @param numChannels Number of channels to process
     * @param numSamples Number of samples per channel
     */
    void process(const float* const* inputs, float* const* outputs,
                size_t numChannels, size_t numSamples);
    
    /**
     * @brief Reset all processor state
     */
    void reset();
    
    /**
     * @brief Set bypass mode
     * @param bypass True to bypass processing
     */
    void setBypass(bool bypass);
    
    // Parameter setters
    void setChannelWeight(size_t channel, float weight);
    void setChannelAutoEnabled(size_t channel, bool enabled);
    void setChannelOverride(size_t channel, bool override);
    void setAttackTime(float timeInSeconds);
    void setReleaseTime(float timeInSeconds);
    void setSmoothingTime(float timeInSeconds);
    void setAdaptiveThreshold(float threshold);
    void setMasterGain(float gain);
    
    // State getters
    float getChannelInputLevel(size_t channel) const;
    float getChannelGainReduction(size_t channel) const;
    float getChannelPeakLevel(size_t channel) const;
    bool isChannelAutoEnabled(size_t channel) const;
    bool isChannelOverride(size_t channel) const;
    float getChannelWeight(size_t channel) const;
    
    // Performance statistics
    struct Statistics {
        float averageGainReduction;
        float peakGainReduction;
        float averageInputLevel;
        int activeChannels;
        float processingLoad;
    };

    /**
     * @brief Reset all peak meters
     *
     * This resets all channel peak meters to their minimum value.
     * Useful when starting a new session or when levels have changed significantly.
     */
    void resetPeakMeters();
    
    /**
     * @brief Get processing statistics
     * @return Statistics struct with current performance metrics
     */
    Statistics getStatistics() const;

private:
    // Thread-local storage for temporary buffers
    static thread_local std::vector<float> threadLocalBuffer;
    
    // Internal processing methods
    void updateLevels(const float* const* inputs, size_t numChannels, size_t numSamples);
    void updateLevelsOptimized(const float* const* inputs, size_t numChannels, size_t numSamples);
    void computeGains(size_t numChannels);
    void applyGains(const float* const* inputs, float* const* outputs, size_t numChannels, size_t numSamples);
    float computeEnvelope(float input, float envelope, float coeff) const;
    float smoothGain(float currentGain, float targetGain, float coeff) const;
    
    // Optimized gain application using SIMD when available
    void applyGainsOptimized(const float* const* inputs, float* const* outputs,
                            size_t numChannels, size_t numSamples);
    
    // Regular gain application for fallback
    void applyGainsRegular(const float* const* inputs, float* const* outputs,
                          size_t numChannels, size_t numSamples);
                          
    // Added missing member variables
    float adaptiveThreshold = -40.0f;
    float masterGain = 0.0f;
    float totalWeightedLevel = 0.0f;
    int activeChannelCount = 0;
    float masterGainReduction = 0.0f;
    std::atomic<bool> bypassEnabled{false};
    float attackCoeff = 0.0f;
    float releaseCoeff = 0.0f;
    float smoothingCoeff = 0.0f;
    bool channelActive[kMaxChannels] = {false};
    
    // Statistics tracking
    mutable std::mutex statsMutex;
    Statistics currentStats;
    
    // Thread safety for parameter access
    mutable std::mutex processMutex;
    
    // Performance monitoring
    std::atomic<float> processingLoad{0.0f};
    std::chrono::high_resolution_clock::time_point lastProcessTime;
    std::atomic<double> cpuLoad{0.0};
    
    // General settings
    float sampleRate = 44100.0f;

    // Channel data array
    struct Channel {
        float inputLevel = -60.0f;       // Current input level in dB
        float gainReduction = 0.0f;      // Current gain reduction in dB
        float weight = 1.0f;             // Channel weight
        bool autoEnabled = true;         // Auto mode enabled
        bool overrideEnabled = false;    // Override state (renamed from 'override' to avoid C++ keyword)
        float envelope = 0.0f;           // Signal envelope
        float smoothedGain = 1.0f;       // Smoothed gain value
        bool active = false;             // Whether the channel is active
        float peakLevel = -60.0f;        // Peak level for metering
        int peakHoldCounter = 0;         // Counter for peak hold time
        float lastRMS = 0.0f;            // Last RMS value
    };

    // Array of channels
    Channel channels[kMaxChannels];
    
    // Prevent copying
    DuganProcessor(const DuganProcessor&) = delete;
    DuganProcessor& operator=(const DuganProcessor&) = delete;
};
