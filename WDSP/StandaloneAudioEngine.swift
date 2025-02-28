import SwiftUI
import AVFoundation
import AudioToolbox
import CoreAudio

class StandaloneAudioEngine: ObservableObject {
    private let engine = AVAudioEngine()
    private let mixer = AVAudioMixerNode()
    private var audioUnit: AUAudioUnit?
    
    @Published var isPlaying = false
    @Published var viewController: NSViewController?
    @Published var isLoading = true
    @Published var errorMessage: String?
    
    init() {
        setupAudioEngine()
    }
    
    func setupAudioEngine() {
        // Connect engine nodes
        engine.attach(mixer)
        engine.connect(mixer, to: engine.mainMixerNode, format: nil)
        
        // Prepare engine
        engine.prepare()
        print("Audio engine initialized")
    }
    
    func loadAudioUnit() {
        isLoading = true
        errorMessage = nil
        
        // Define our audio unit - ensure these match Info.plist
        var desc = AudioComponentDescription()
        desc.componentType = kAudioUnitType_Effect
        desc.componentSubType = fourCharCode("WDSP")
        desc.componentManufacturer = fourCharCode("Demo")
        desc.componentFlags = 0
        desc.componentFlagsMask = 0
        
        // Log component details for debugging
        print("Loading audio unit with type: \(fourCharCodeToString(desc.componentType))")
        print("Loading audio unit with subtype: \(fourCharCodeToString(desc.componentSubType))")
        print("Loading audio unit with manufacturer: \(fourCharCodeToString(desc.componentManufacturer))")
        
        // First check if component is registered
        let component = AudioComponentFindNext(nil, &desc)
        if component == nil {
            print("No matching audio unit component found")
            DispatchQueue.main.async {
                self.isLoading = false
                self.errorMessage = "Audio Unit not found. Check Info.plist configuration."
            }
            return
        }
        
        // Load the audio unit
        AVAudioUnit.instantiate(with: desc, options: []) { [weak self] avAudioUnit, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                if let error = error {
                    print("Error loading Audio Unit: \(error.localizedDescription)")
                    self.errorMessage = "Error: \(error.localizedDescription)"
                    self.isLoading = false
                    return
                }
                
                guard let avAudioUnit = avAudioUnit else {
                    print("Failed to create AVAudioUnit")
                    self.errorMessage = "Failed to create Audio Unit"
                    self.isLoading = false
                    return
                }
                
                print("Successfully loaded Audio Unit")
                self.attachAudioUnit(avAudioUnit)
                
                // Request view controller for UI
                avAudioUnit.auAudioUnit.requestViewController { [weak self] viewController in
                    guard let self = self else { return }
                    
                    DispatchQueue.main.async {
                        self.viewController = viewController
                        self.isLoading = false
                        if viewController == nil {
                            self.errorMessage = "No UI available for this Audio Unit"
                        }
                    }
                }
            }
        }
    }
    
    func attachAudioUnit(_ avAudioUnit: AVAudioUnit) {
        self.audioUnit = avAudioUnit.auAudioUnit
        
        // Attach and connect the audio unit
        engine.attach(avAudioUnit)
        
        // Connect test tone generator -> AU -> mixer
        connectTestToneGenerator(to: avAudioUnit)
        engine.connect(avAudioUnit, to: mixer, format: nil)
    }
    
    func connectTestToneGenerator(to avAudioUnit: AVAudioUnit) {
        // Create simple test tone generator for standalone testing
        let format = avAudioUnit.inputFormat(forBus: 0)
        let frameCount = UInt32(format.sampleRate * 0.1) // 100ms buffer
        
        for channel in 0..<4 {
            let player = AVAudioPlayerNode()
            engine.attach(player)
            
            // Create a buffer with test tone
            let buffer = createTestBuffer(format: format,
                                          frameCount: frameCount,
                                          frequency: 300.0 + Double(channel) * 100.0,
                                          amplitude: 0.2)
            
            // Connect player -> audioUnit
            engine.connect(player, to: avAudioUnit, format: format)
            
            // Schedule buffer to play repeatedly
            player.scheduleBuffer(buffer, at: nil, options: .loops, completionHandler: nil)
            player.play()
        }
    }
    
    private func createTestBuffer(format: AVAudioFormat, frameCount: UInt32, frequency: Double, amplitude: Double) -> AVAudioPCMBuffer {
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
        let sampleRate = format.sampleRate
        
        // Fill the buffer with a sine wave
        for frame in 0..<Int(frameCount) {
            let value = Float(amplitude * sin(2.0 * .pi * frequency * Double(frame) / sampleRate))
            for channel in 0..<format.channelCount {
                buffer.floatChannelData?[Int(channel)][frame] = value
            }
        }
        
        buffer.frameLength = frameCount
        return buffer
    }
    
    func togglePlayback() {
        if engine.isRunning {
            engine.stop()
            isPlaying = false
        } else {
            do {
                try engine.start()
                isPlaying = true
            } catch {
                print("Error starting engine: \(error.localizedDescription)")
                errorMessage = "Error starting playback: \(error.localizedDescription)"
            }
        }
    }
}
