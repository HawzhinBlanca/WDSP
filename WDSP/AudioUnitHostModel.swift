import Foundation
import AVFoundation
import AudioToolbox
import os

class AudioUnitHostModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published private(set) var isPlaying = false
    @Published private(set) var viewModel: AudioUnitViewModel?
    @Published var audioUnitNumber = 0
    
    // MARK: - Private Properties
    private let engine = AVAudioEngine()
    private let mixer = AVAudioMixerNode()
    private var audioUnit: AUAudioUnit?
    private var instrumentPlayer: AVAudioUnit?
    private var nodes: [AVAudioNode] = []
    private let logger = Logger(subsystem: "com.yourcompany.WDSP", category: "Host")
    
    // MARK: - Audio Format Settings
    private let inputFormat = AVAudioFormat(standardFormatWithSampleRate: 44100.0,
                                          channels: 4)
    private let outputFormat = AVAudioFormat(standardFormatWithSampleRate: 44100.0,
                                           channels: 4)
    
    // MARK: - Initialization
    init() {
        setupAudioEngine()
    }
    
    // MARK: - Public Methods
    func loadAudioUnit() {
        var desc = AudioComponentDescription()
        desc.componentType = kAudioUnitType_Effect
        desc.componentSubType = fourCharCode("WDSP")
        desc.componentManufacturer = fourCharCode("Demo")
        desc.componentFlags = 0
        desc.componentFlagsMask = 0
        
        // Fix: Remove trailing closure and use explicit parameter instead
        AVAudioUnit.instantiate(with: desc, options: [], completionHandler: { [weak self] avAudioUnit, error in
            guard let self = self,
                  let avAudioUnit = avAudioUnit else {
                self?.logger.error("Failed to load Audio Unit: \(String(describing: error))")
                return
            }
            
            // Fix: Use explicit dispatch parameter instead of trailing closure
            DispatchQueue.main.async(execute: {
                self.connectAudioUnit(avAudioUnit)
            })
        })
    }
    
    func togglePlayback() {
        if engine.isRunning {
            stopPlayback()
        } else {
            startPlayback()
        }
    }
    
    // MARK: - Private Methods
    private func setupAudioEngine() {
        engine.attach(mixer)
        engine.connect(mixer, to: engine.mainMixerNode, format: outputFormat)
        engine.prepare()
    }
    
    private func startPlayback() {
        do {
            try engine.start()
            isPlaying = true
        } catch {
            logger.error("Failed to start playback: \(error.localizedDescription)")
        }
    }
    
    private func stopPlayback() {
        engine.stop()
        isPlaying = false
    }
    
    private func connectAudioUnit(_ avAudioUnit: AVAudioUnit) {
        self.instrumentPlayer = avAudioUnit
        
        nodes.forEach { engine.detach($0) }
        nodes.removeAll()
        
        engine.attach(avAudioUnit)
        engine.connect(avAudioUnit, to: mixer, format: outputFormat)
        nodes.append(avAudioUnit)
        
        let optionalAU: AUAudioUnit? = avAudioUnit.auAudioUnit
        if let au = optionalAU {
            self.audioUnit = au
            self.viewModel = AudioUnitViewModel(audioUnit: au)
            
            do {
                try au.allocateRenderResources()
            } catch {
                logger.error("Failed to allocate render resources")
            }
        } else {
            logger.error("Failed to get AUAudioUnit")
        }
    }
    
    // Utility functions
    private func fourCharCode(_ string: String) -> FourCharCode {
        var result: FourCharCode = 0
        let paddedString = string.padding(toLength: 4, withPad: " ", startingAt: 0)
        for char in paddedString.utf8 {
            result = (result << 8) | FourCharCode(char)
        }
        return result
    }
}
