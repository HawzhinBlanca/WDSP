#pragma once

#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreAudioKit/AUViewController.h>

// Forward declaration
class WDSPKernel;

NS_ASSUME_NONNULL_BEGIN

/**
 * @class WDSPAU
 * @brief Core Audio Unit class for the WDSP Dugan Automixer
 *
 * This Objective-C++ class implements the audio unit interface required by the
 * Audio Unit Extensions API. It handles parameter management, audio processing,
 * and bridging between the Swift UI and C++ implementation.
 */
@interface WDSPAU : AUAudioUnit

/**
 * @brief Returns the component description for the audio unit
 * @return AudioComponentDescription with the appropriate type, subtype and manufacturer
 */
+ (AudioComponentDescription)audioComponentDescription;

/**
 * @brief Initialize the audio unit with component description
 * @param componentDescription The AudioComponentDescription for this audio unit
 * @param options Audio component instantiation options
 * @param outError Error pointer to receive any initialization errors
 * @return Initialized audio unit instance or nil if initialization failed
 */
- (nullable instancetype)initWithComponentDescription:(AudioComponentDescription)componentDescription
                                              options:(AudioComponentInstantiationOptions)options
                                                error:(NSError **)outError NS_DESIGNATED_INITIALIZER;

/**
 * @brief Gets the view controller for the audio unit UI
 * @param completionHandler Called with the view controller when ready
 */
- (void)requestViewControllerWithCompletionHandler:(void (^)(NSViewController * __nullable viewController))completionHandler;

// Standard initializers unavailable
- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
