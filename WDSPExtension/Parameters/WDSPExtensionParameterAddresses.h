//
//  WDSPExtensionParameterAddresses.h
//  WDSPExtension
//
//  Created by HAWZHIN on 27/02/2025.
//

#pragma once

#include <AudioToolbox/AUParameters.h>

typedef NS_ENUM(AUParameterAddress, WDSPExtensionParameterAddress) {
    gain = 0
};

typedef NS_ENUM(AudioUnitParameterID, WDSPParameterAddress) {
    // Channel 1
    kWeight1 = 0,
    kAutoEnable1 = 1,
    kOverride1 = 2,
    kInputMeter1 = 3,
    kGainReduction1 = 4,
    
    // Channel 2
    kWeight2 = 5,
    kAutoEnable2 = 6,
    kOverride2 = 7,
    kInputMeter2 = 8,
    kGainReduction2 = 9,
    
    // Channel 3
    kWeight3 = 10,
    kAutoEnable3 = 11,
    kOverride3 = 12,
    kInputMeter3 = 13,
    kGainReduction3 = 14,
    
    // Channel 4
    kWeight4 = 15,
    kAutoEnable4 = 16,
    kOverride4 = 17,
    kInputMeter4 = 18,
    kGainReduction4 = 19,
    
    // Global parameters
    kMasterGain = 20,
    kAttackTime = 21,
    kReleaseTime = 22,
    kAdaptiveThreshold = 23,
    kPresetSelector = 24,
    
    // Total parameter count
    kNumParameters = 25
};
