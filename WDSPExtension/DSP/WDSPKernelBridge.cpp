#include "WDSPExtension-Bridging-Header.h"
#include "WDSPKernel.h"
#include <map>
#include <vector>
#include <cmath>
#include <cstring>
#include <stdexcept>
#include <new>

// A constant for the bridge file
#define WDSP_MAX_CHANNELS 8

#ifdef __cplusplus
extern "C" {
#endif

// Diagnostic info structures for C/C++ interop
struct WDSPDiagnosticInfoC {
    float averageLoad;        // Average CPU load (0.0-1.0)
    float peakLoad;           // Peak CPU load (0.0-1.0)
    int overloads;            // Count of processing overloads
    bool wasBypassEngaged;    // Previous bypass state
    bool isBypassEngaged;     // Current bypass state
    float inputLevel;         // Input level in dB
    float outputLevel;        // Output level in dB
};

// Create a new kernel instance
void* WDSPKernel_create(double sampleRate) {
    try {
        WDSPKernel* kernel = new WDSPKernel();
        if (kernel) {
            kernel->initialize(sampleRate);
            return kernel;
        }
    } catch (const std::exception& e) {
        // Handle any exceptions during creation
        fprintf(stderr, "Error creating WDSPKernel: %s\n", e.what());
    } catch (...) {
        // Handle any exceptions during creation
        fprintf(stderr, "Unknown error creating WDSPKernel\n");
    }
    return nullptr;
}

// Destroy a kernel instance
void WDSPKernel_destroy(void* kernel) {
    if (kernel) {
        try {
            delete static_cast<WDSPKernel*>(kernel);
        } catch (const std::exception& e) {
            fprintf(stderr, "Error destroying WDSPKernel: %s\n", e.what());
        } catch (...) {
            fprintf(stderr, "Unknown error destroying WDSPKernel\n");
        }
    }
}

// Initialize the kernel with a given sample rate
void WDSPKernel_initialize(void* kernel, double sampleRate) {
    if (kernel) {
        try {
            static_cast<WDSPKernel*>(kernel)->initialize(sampleRate);
        } catch (const std::exception& e) {
            fprintf(stderr, "Error initializing WDSPKernel: %s\n", e.what());
        } catch (...) {
            fprintf(stderr, "Unknown error initializing WDSPKernel\n");
        }
    }
}

// Process audio data through the kernel
OSStatus WDSPKernel_processAudio(void* kernel,
                               const AudioTimeStamp* timestamp,
                               UInt32 frameCount,
                               AudioBufferList* inputBufferList,
                               AudioBufferList* outputBufferList) {
    if (!kernel) return kAudioUnitErr_NoConnection;
    
    // Validate input parameters
    if (!inputBufferList || !outputBufferList) {
        return kAudioUnitErr_InvalidParameter;
    }
    
    // Process audio through the kernel
    try {
        return static_cast<WDSPKernel*>(kernel)->process(inputBufferList, outputBufferList, frameCount);
    } catch (const std::exception& e) {
        // Log error but don't crash
        fprintf(stderr, "Exception in audio processing: %s\n", e.what());
        return kAudioUnitErr_FailedInitialization;
    } catch (...) {
        fprintf(stderr, "Unknown exception in audio processing\n");
        return kAudioUnitErr_FailedInitialization;
    }
}

// Set a parameter value
void WDSPKernel_setParameter(void* kernel, AudioUnitParameterID address, float value) {
    if (kernel) {
        try {
            static_cast<WDSPKernel*>(kernel)->setParameter(address, value);
        } catch (const std::exception& e) {
            // Log parameter errors
            fprintf(stderr, "Error setting parameter %d to %f: %s\n", address, value, e.what());
        } catch (...) {
            fprintf(stderr, "Unknown error setting parameter %d to %f\n", address, value);
        }
    }
}

// Get a parameter value
float WDSPKernel_getParameter(void* kernel, AudioUnitParameterID address) {
    if (kernel) {
        try {
            return static_cast<WDSPKernel*>(kernel)->getParameter(address);
        } catch (const std::exception& e) {
            // Return default value on error
            fprintf(stderr, "Error getting parameter %d: %s\n", address, e.what());
            return 0.0f;
        } catch (...) {
            fprintf(stderr, "Unknown error getting parameter %d\n", address);
            return 0.0f;
        }
    }
    return 0.0f;
}

// Reset the kernel state
void WDSPKernel_reset(void* kernel) {
    if (kernel) {
        try {
            static_cast<WDSPKernel*>(kernel)->reset();
        } catch (const std::exception& e) {
            fprintf(stderr, "Error resetting kernel: %s\n", e.what());
        } catch (...) {
            fprintf(stderr, "Unknown error resetting kernel\n");
        }
    }
}

// Set bypass state
void WDSPKernel_setBypass(void* kernel, bool bypass) {
    if (kernel) {
        try {
            static_cast<WDSPKernel*>(kernel)->setBypass(bypass);
        } catch (const std::exception& e) {
            fprintf(stderr, "Error setting bypass: %s\n", e.what());
        } catch (...) {
            fprintf(stderr, "Unknown error setting bypass\n");
        }
    }
}

// Get bypass state
bool WDSPKernel_getBypass(void* kernel) {
    if (kernel) {
        try {
            return static_cast<WDSPKernel*>(kernel)->getBypass();
        } catch (const std::exception& e) {
            fprintf(stderr, "Error getting bypass: %s\n", e.what());
            return false;
        } catch (...) {
            fprintf(stderr, "Unknown error getting bypass\n");
            return false;
        }
    }
    return false;
}

// Set time constants
void WDSPKernel_setTimeConstants(void* kernel, float attackMs, float releaseMs) {
    if (kernel) {
        try {
            static_cast<WDSPKernel*>(kernel)->setTimeConstants(attackMs, releaseMs);
        } catch (const std::exception& e) {
            fprintf(stderr, "Error setting time constants: %s\n", e.what());
        } catch (...) {
            fprintf(stderr, "Unknown error setting time constants\n");
        }
    }
}

// Set adaptive threshold
void WDSPKernel_setAdaptiveThreshold(void* kernel, float threshold) {
    if (kernel) {
        try {
            static_cast<WDSPKernel*>(kernel)->setAdaptiveThreshold(threshold);
        } catch (const std::exception& e) {
            fprintf(stderr, "Error setting adaptive threshold: %s\n", e.what());
        } catch (...) {
            fprintf(stderr, "Unknown error setting adaptive threshold\n");
        }
    }
}

// Set master gain
void WDSPKernel_setMasterGain(void* kernel, float gain) {
    if (kernel) {
        try {
            static_cast<WDSPKernel*>(kernel)->setMasterGain(gain);
        } catch (const std::exception& e) {
            fprintf(stderr, "Error setting master gain: %s\n", e.what());
        } catch (...) {
            fprintf(stderr, "Unknown error setting master gain\n");
        }
    }
}

// Apply preset
void WDSPKernel_applyPreset(void* kernel, int presetIndex) {
    if (kernel) {
        try {
            static_cast<WDSPKernel*>(kernel)->applyPreset(presetIndex);
        } catch (const std::exception& e) {
            fprintf(stderr, "Error applying preset: %s\n", e.what());
        } catch (...) {
            fprintf(stderr, "Unknown error applying preset\n");
        }
    }
}

// Get DSP load
float WDSPKernel_getDSPLoad(void* kernel) {
    if (kernel) {
        try {
            return static_cast<WDSPKernel*>(kernel)->getDSPLoad();
        } catch (const std::exception& e) {
            fprintf(stderr, "Error getting DSP load: %s\n", e.what());
            return 0.0f;
        } catch (...) {
            fprintf(stderr, "Unknown error getting DSP load\n");
            return 0.0f;
        }
    }
    return 0.0f;
}

// Get channel peak level
float WDSPKernel_getChannelPeakLevel(void* kernel, unsigned int channel) {
    if (kernel) {
        try {
            return static_cast<WDSPKernel*>(kernel)->getChannelPeakLevel(channel);
        } catch (const std::exception& e) {
            fprintf(stderr, "Error getting channel peak level: %s\n", e.what());
            return -60.0f;
        } catch (...) {
            fprintf(stderr, "Unknown error getting channel peak level\n");
            return -60.0f;
        }
    }
    return -60.0f;
}

// C bridge function for Swift interoperability
// Note: This function avoids calling getDiagnosticInfo() directly to prevent const-related compiler issues
WDSPDiagnosticInfoC wdsp_get_diagnostic_info(const WDSPKernel* kernel) {
    // Initialize with default values
    WDSPDiagnosticInfoC result;
    memset(&result, 0, sizeof(result)); // Zero-initialize for safety
    
    // Set default values for audio levels
    result.inputLevel = -100.0f;
    result.outputLevel = -100.0f;
    
    // If kernel is null, return defaults
    if (!kernel) {
        return result;
    }
    
    try {
        // Manually get metrics from kernel methods
        result.averageLoad = kernel->getDSPLoad();
        result.peakLoad = result.averageLoad; // Use same value
        result.isBypassEngaged = kernel->getBypass();
        result.wasBypassEngaged = result.isBypassEngaged;
        
        // Try to get audio level from first channel
        try {
            if (kernel->getChannelPeakLevel(0) > -100.0f) {
                result.outputLevel = kernel->getChannelPeakLevel(0);
                // Rough estimation of input level (slightly lower than output)
                result.inputLevel = result.outputLevel - 3.0f;
            }
        } catch (...) {
            // Keep default values for levels
        }
    } catch (...) {
        // On any error, use defaults
    }
    
    return result;
}

#ifdef __cplusplus
}
#endif
