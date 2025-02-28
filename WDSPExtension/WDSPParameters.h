

// WDSPParameters.h
enum WDSPParam {
    // Channel 1
    kWeight1 = 0,
    kAutoEnable1,
    kOverride1,
    kInputMeter1,
    kGainReduction1,
    
    // Channel 2
    kWeight2,
    kAutoEnable2,
    kOverride2,
    kInputMeter2,
    kGainReduction2,
    
    // Channel 3
    kWeight3,
    kAutoEnable3,
    kOverride3,
    kInputMeter3,
    kGainReduction3,
    
    // Channel 4
    kWeight4,
    kAutoEnable4,
    kOverride4,
    kInputMeter4,
    kGainReduction4,
    
    kNumParams
};

static const WDSPParameterInfo kParameterInfo[] = {
    // Channel 1
    {kWeight1, "Weight 1", "", 0.0f, 2.0f, 1.0f, kAudioUnitParameterUnit_Generic, false},
    {kAutoEnable1, "Auto 1", "", 0.0f, 1.0f, 1.0f, kAudioUnitParameterUnit_Boolean, true},
    {kOverride1, "Override 1", "", 0.0f, 1.0f, 0.0f, kAudioUnitParameterUnit_Boolean, true},
    {kInputMeter1, "Input 1", "dB", -60.0f, 0.0f, -60.0f, kAudioUnitParameterUnit_DecimalLevel, false},
    {kGainReduction1, "Gain 1", "dB", -30.0f, 0.0f, 0.0f, kAudioUnitParameterUnit_DecimalLevel, false},
    
    // Channel 2
    {kWeight2, "Weight 2", "", 0.0f, 2.0f, 1.0f, kAudioUnitParameterUnit_Generic, false},
    {kAutoEnable2, "Auto 2", "", 0.0f, 1.0f, 1.0f, kAudioUnitParameterUnit_Boolean, true},
    {kOverride2, "Override 2", "", 0.0f, 1.0f, 0.0f, kAudioUnitParameterUnit_Boolean, true},
    {kInputMeter2, "Input 2", "dB", -60.0f, 0.0f, -60.0f, kAudioUnitParameterUnit_DecimalLevel, false},
    {kGainReduction2, "Gain 2", "dB", -30.0f, 0.0f, 0.0f, kAudioUnitParameterUnit_DecimalLevel, false},
    
    // Channel 3 & 4 follow same pattern...
};
