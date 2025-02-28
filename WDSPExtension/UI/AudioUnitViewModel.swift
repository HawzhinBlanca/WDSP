//
//  AudioUnitViewModel.swift
//  WDSP
//
//  Created by HAWZHIN on 28/02/2025.
//


import SwiftUI
import AudioToolbox
import CoreAudioKit

// This file should only be included in the EXTENSION target, not the main app
class AudioUnitViewModel {
    var showAudioControls: Bool = false
    var showMIDIContols: Bool = false
    var title: String = "-"
    var message: String = "No Audio Unit loaded..."
    var audioUnit: AUAudioUnit?
    var viewController: NSViewController?
    
    init(audioUnit: AUAudioUnit) {
        self.audioUnit = audioUnit
        self.title = "WDSP"
        self.message = "Audio Unit loaded"
        self.showAudioControls = true
        
        // Fetch the audio unit's view controller
        audioUnit.requestViewController { [weak self] viewController in
            self?.viewController = viewController
        }
    }
    
    init() {
        // Default initializer
    }
}