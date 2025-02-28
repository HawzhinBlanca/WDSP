//
//  WDSPViewController.h
//  WDSP
//
//  Created by HAWZHIN on 24/02/2025.
//


#import <Cocoa/Cocoa.h>
#import <AudioToolbox/AudioToolbox.h>

@class AUAudioUnit;

NS_ASSUME_NONNULL_BEGIN

/**
 * Main view controller for the WDSP Dugan Automixer UI
 *
 * This Objective-C++ class manages the UI for the audio plugin and communicates
 * with the audio unit through the parameter tree. It creates a channel strip
 * for each channel and binds the UI controls to their parameters.
 */
@interface WDSPViewController : NSViewController

/**
 * Create the audio unit with the given component description
 * 
 * This is called by AudioUnitViewController.swift to create the audio unit
 * and bind the parameters to the UI.
 */
- (nullable AUAudioUnit *)createAudioUnitWithComponentDescription:(AudioComponentDescription)desc 
                                                           error:(NSError **)error;

@property (nonatomic, readonly) AUAudioUnit *audioUnit;

@end

NS_ASSUME_NONNULL_END