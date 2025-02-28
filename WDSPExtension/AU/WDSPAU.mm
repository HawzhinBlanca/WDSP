#import "WDSPAU.h"
#import <AVFoundation/AVFoundation.h>
#import <CoreAudioKit/CoreAudioKit.h>
#include "WDSPKernel.h"

@interface WDSPAU () {
    // Private properties
    WDSPKernel* _kernel;
    AUAudioUnitBusArray* _inputBusArray;
    AUAudioUnitBusArray* _outputBusArray;
    AUParameterTree* _parameterTree;
}
@end

@implementation WDSPAU

// MARK: - Component Description
+ (AudioComponentDescription)audioComponentDescription {
    AudioComponentDescription desc;
    desc.componentType = kAudioUnitType_Effect;
    desc.componentSubType = 'wdsp';  // Four-char code for the plugin - lowercase!
    desc.componentManufacturer = 'Demo';
    desc.componentFlags = 0;
    desc.componentFlagsMask = 0;
    return desc;
}

// MARK: - Initialization
- (instancetype)initWithComponentDescription:(AudioComponentDescription)componentDescription
                                     options:(AudioComponentInstantiationOptions)options
                                       error:(NSError **)outError {
    
    self = [super initWithComponentDescription:componentDescription
                                       options:options
                                         error:outError];
    if (self) {
        // Create kernel
        _kernel = new WDSPKernel();
        if (!_kernel) {
            if (outError) {
                *outError = [NSError errorWithDomain:NSOSStatusErrorDomain
                                                code:kAudioUnitErr_FailedInitialization
                                            userInfo:nil];
            }
            return nil;
        }
        
        // Create standard format for 4-channel operation
        AVAudioFormat* format = [[AVAudioFormat alloc] initStandardFormatWithSampleRate:44100.0
                                                                               channels:4];
        
        // Setup input bus array
        NSError* error = nil;
        AUAudioUnitBus* inputBus = [[AUAudioUnitBus alloc] initWithFormat:format error:&error];
        if (!inputBus || error) {
            if (outError) {
                *outError = error;
            }
            return nil;
        }
        
        _inputBusArray = [[AUAudioUnitBusArray alloc] initWithAudioUnit:self
                                                                 busType:AUAudioUnitBusTypeInput
                                                                  busses:@[inputBus]];
        
        // Setup output bus array (same format as input)
        AUAudioUnitBus* outputBus = [[AUAudioUnitBus alloc] initWithFormat:format error:&error];
        if (!outputBus || error) {
            if (outError) {
                *outError = error;
            }
            return nil;
        }
        
        _outputBusArray = [[AUAudioUnitBusArray alloc] initWithAudioUnit:self
                                                                  busType:AUAudioUnitBusTypeOutput
                                                                   busses:@[outputBus]];
        
        // Set up parameters
        [self setupParameterTree];
    }
    return self;
}

- (void)dealloc {
    if (_kernel) {
        delete _kernel;
        _kernel = nullptr;
    }
}

// MARK: - AUAudioUnit Overrides
- (AUAudioUnitBusArray *)inputBusses {
    return _inputBusArray;
}

- (AUAudioUnitBusArray *)outputBusses {
    return _outputBusArray;
}

- (NSArray<NSNumber *> *)channelCapabilities {
    return @[@4, @4]; // 4 input channels, 4 output channels
}

- (BOOL)allocateRenderResourcesAndReturnError:(NSError **)outError {
    if (![super allocateRenderResourcesAndReturnError:outError]) {
        return NO;
    }
    
    // Initialize kernel with current sample rate
    if (_kernel && self.outputBusses.count > 0) {
        AUAudioUnitBus *outputBus = [self.outputBusses objectAtIndexedSubscript:0];
        _kernel->initialize(outputBus.format.sampleRate);
    }
    
    return YES;
}

- (void)deallocateRenderResources {
    if (_kernel) {
        _kernel->reset();
    }
    [super deallocateRenderResources];
}

// MARK: - Parameter Setup
- (void)setupParameterTree {
    // Create parameters for each channel
    NSMutableArray<AUParameterNode *> *parameters = [NSMutableArray array];
    
    // For each channel (4 channels)
    for (NSInteger ch = 0; ch < 4; ch++) {
        NSInteger baseAddress = ch * 5;
        
        // Weight parameter (0.0 - 2.0)
        AUParameter *weight = [AUParameterTree createParameterWithIdentifier:[NSString stringWithFormat:@"weight%ld", (long)(ch + 1)]
                                                                        name:[NSString stringWithFormat:@"Weight %ld", (long)(ch + 1)]
                                                                     address:baseAddress
                                                                         min:0.0
                                                                         max:2.0
                                                                        unit:kAudioUnitParameterUnit_Generic
                                                                    unitName:nil
                                                                       flags:kAudioUnitParameterFlag_IsReadable | kAudioUnitParameterFlag_IsWritable
                                                                valueStrings:nil
                                                         dependentParameters:nil];
        weight.value = 1.0; // Default value
        [parameters addObject:weight];
        
        // Auto enable parameter (boolean)
        AUParameter *autoEnable = [AUParameterTree createParameterWithIdentifier:[NSString stringWithFormat:@"auto%ld", (long)(ch + 1)]
                                                                            name:[NSString stringWithFormat:@"Auto %ld", (long)(ch + 1)]
                                                                         address:baseAddress + 1
                                                                             min:0.0
                                                                             max:1.0
                                                                            unit:kAudioUnitParameterUnit_Boolean
                                                                        unitName:nil
                                                                           flags:kAudioUnitParameterFlag_IsReadable | kAudioUnitParameterFlag_IsWritable
                                                                    valueStrings:nil
                                                             dependentParameters:nil];
        autoEnable.value = 1.0; // Default to enabled
        [parameters addObject:autoEnable];
        
        // Override parameter (boolean)
        AUParameter *override = [AUParameterTree createParameterWithIdentifier:[NSString stringWithFormat:@"override%ld", (long)(ch + 1)]
                                                                          name:[NSString stringWithFormat:@"Override %ld", (long)(ch + 1)]
                                                                       address:baseAddress + 2
                                                                           min:0.0
                                                                           max:1.0
                                                                          unit:kAudioUnitParameterUnit_Boolean
                                                                      unitName:nil
                                                                         flags:kAudioUnitParameterFlag_IsReadable | kAudioUnitParameterFlag_IsWritable
                                                                  valueStrings:nil
                                                           dependentParameters:nil];
        override.value = 0.0; // Default to disabled
        [parameters addObject:override];
        
        // Input meter parameter (read-only)
        AUParameter *inputMeter = [AUParameterTree createParameterWithIdentifier:[NSString stringWithFormat:@"input%ld", (long)(ch + 1)]
                                                                            name:[NSString stringWithFormat:@"Input %ld", (long)(ch + 1)]
                                                                         address:baseAddress + 3
                                                                             min:-60.0
                                                                             max:0.0
                                                                            unit:kAudioUnitParameterUnit_Decibels
                                                                        unitName:@"dB"
                                                                           flags:kAudioUnitParameterFlag_IsReadable
                                                                    valueStrings:nil
                                                             dependentParameters:nil];
        inputMeter.value = -60.0; // Default to minimum
        [parameters addObject:inputMeter];
        
        // Gain reduction meter parameter (read-only)
        AUParameter *gainReduction = [AUParameterTree createParameterWithIdentifier:[NSString stringWithFormat:@"gain%ld", (long)(ch + 1)]
                                                                               name:[NSString stringWithFormat:@"Gain %ld", (long)(ch + 1)]
                                                                            address:baseAddress + 4
                                                                                min:-30.0
                                                                                max:0.0
                                                                               unit:kAudioUnitParameterUnit_Decibels
                                                                           unitName:@"dB"
                                                                              flags:kAudioUnitParameterFlag_IsReadable
                                                                       valueStrings:nil
                                                                dependentParameters:nil];
        gainReduction.value = 0.0; // Default to no reduction
        [parameters addObject:gainReduction];
    }
    
    // Create parameter tree
    _parameterTree = [AUParameterTree createTreeWithChildren:parameters];
    
    // Set parameter callbacks
    __weak WDSPAU *weakSelf = self;
    
    // Parameter value observer callback
    _parameterTree.implementorValueObserver = ^(AUParameter *param, AUValue value) {
        WDSPAU *strongSelf = weakSelf;
        if (strongSelf && strongSelf->_kernel) {
            AudioUnitParameterID paramID = (AudioUnitParameterID)param.address;
            strongSelf->_kernel->setParameter(paramID, value);
        }
    };
    
    // Parameter value provider callback
    _parameterTree.implementorValueProvider = ^AUValue(AUParameter *param) {
        WDSPAU *strongSelf = weakSelf;
        if (strongSelf && strongSelf->_kernel) {
            AudioUnitParameterID paramID = (AudioUnitParameterID)param.address;
            return strongSelf->_kernel->getParameter(paramID);
        }
        return param.value;
    };
    
    // Parameter string from value callback
    _parameterTree.implementorStringFromValueCallback = ^NSString *(AUParameter *param, const AUValue *valuePtr) {
        AUValue value = valuePtr != NULL ? *valuePtr : param.value;
        
        switch (param.unit) {
            case kAudioUnitParameterUnit_Boolean:
                return value >= 0.5 ? @"On" : @"Off";
            case kAudioUnitParameterUnit_Decibels:
                return [NSString stringWithFormat:@"%.1f dB", value];
            default:
                return [NSString stringWithFormat:@"%.2f", value];
        }
    };
    
    // Set parameter tree
    self.parameterTree = _parameterTree;
}

- (void)requestViewControllerWithCompletionHandler:(nonnull void (^)(NSViewController * _Nullable __strong))completionHandler {
}

@end
