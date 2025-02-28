//
//  AudioUnitViewModel.swift
//  WDSP
//
//  Created by HAWZHIN on 28/02/2025.
//


// If you can't move it, duplicate the file in WDSP/ with the same contents as in WDSPExtension/UI/AudioUnitViewModel.swift
import SwiftUI
import AudioToolbox
import CoreAudioKit

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