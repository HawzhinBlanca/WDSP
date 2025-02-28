import SwiftUI
import AudioToolbox

/**
 * Advanced settings panel for the WDSP Dugan Automixer
 * This view provides access to additional settings not available in the main interface,
 * including time constants, adaptive threshold adjustment, and master gain.
 */
class AdvancedSettingsViewController: NSViewController {
    
    // References to audio unit and kernel
    weak var audioUnit: AUAudioUnit?
    internal var kernelPtr: UnsafeMutableRawPointer? // Changed to internal access
    
    // UI controls
    private var attackSlider: NSSlider!
    private var releaseSlider: NSSlider!
    private var thresholdSlider: NSSlider!
    private var masterGainSlider: NSSlider!
    
    // Current values
    private var attackMs: Float = 10.0  // 10ms default
    private var releaseMs: Float = 100.0 // 100ms default
    private var threshold: Float = -40.0 // -40dB default
    private var masterGain: Float = 0.0  // 0dB default
    
    // Timer for updating UI
    private var updateTimer: Timer?
    
    init(audioUnit: AUAudioUnit?, kernelPointer: UnsafeMutableRawPointer?) {
        self.audioUnit = audioUnit
        self.kernelPtr = kernelPointer
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 340, height: 260))
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor(calibratedWhite: 0.92, alpha: 1.0).cgColor
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        
        // Start timer to periodically update UI
        updateTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updateUI()
        }
    }
    
    deinit {
        updateTimer?.invalidate()
    }
    
    private func setupUI() {
        // Title
        let titleLabel = NSTextField(labelWithString: "Advanced Settings")
        titleLabel.frame = NSRect(x: 20, y: view.frame.height - 40, width: view.frame.width - 40, height: 24)
        titleLabel.font = NSFont.boldSystemFont(ofSize: 16)
        titleLabel.alignment = .center
        view.addSubview(titleLabel)
        
        // Time constants section
        let timeLabel = NSTextField(labelWithString: "Time Constants")
        timeLabel.frame = NSRect(x: 20, y: view.frame.height - 80, width: 120, height: 20)
        timeLabel.font = NSFont.boldSystemFont(ofSize: 13)
        view.addSubview(timeLabel)
        
        // Attack time
        let attackLabel = NSTextField(labelWithString: "Attack (ms):")
        attackLabel.frame = NSRect(x: 30, y: view.frame.height - 110, width: 90, height: 20)
        attackLabel.alignment = .right
        view.addSubview(attackLabel)
        
        attackSlider = NSSlider(frame: NSRect(x: 130, y: view.frame.height - 110, width: 120, height: 20))
        attackSlider.minValue = 1.0  // 1ms
        attackSlider.maxValue = 50.0 // 50ms
        attackSlider.floatValue = attackMs
        attackSlider.target = self
        attackSlider.action = #selector(attackChanged(_:))
        view.addSubview(attackSlider)
        
        let attackValueLabel = NSTextField(frame: NSRect(x: 260, y: view.frame.height - 110, width: 40, height: 20))
        attackValueLabel.isEditable = false
        attackValueLabel.stringValue = String(format: "%.1f", attackMs)
        attackValueLabel.tag = 100 // Tag for updating later
        view.addSubview(attackValueLabel)
        
        // Release time
        let releaseLabel = NSTextField(labelWithString: "Release (ms):")
        releaseLabel.frame = NSRect(x: 30, y: view.frame.height - 140, width: 90, height: 20)
        releaseLabel.alignment = .right
        view.addSubview(releaseLabel)
        
        releaseSlider = NSSlider(frame: NSRect(x: 130, y: view.frame.height - 140, width: 120, height: 20))
        releaseSlider.minValue = 10.0   // 10ms
        releaseSlider.maxValue = 500.0  // 500ms
        releaseSlider.floatValue = releaseMs
        releaseSlider.target = self
        releaseSlider.action = #selector(releaseChanged(_:))
        view.addSubview(releaseSlider)
        
        let releaseValueLabel = NSTextField(frame: NSRect(x: 260, y: view.frame.height - 140, width: 40, height: 20))
        releaseValueLabel.isEditable = false
        releaseValueLabel.stringValue = String(format: "%.1f", releaseMs)
        releaseValueLabel.tag = 101 // Tag for updating later
        view.addSubview(releaseValueLabel)
        
        // Threshold
        let thresholdLabel = NSTextField(labelWithString: "Threshold (dB):")
        thresholdLabel.frame = NSRect(x: 30, y: view.frame.height - 180, width: 90, height: 20)
        thresholdLabel.alignment = .right
        view.addSubview(thresholdLabel)
        
        thresholdSlider = NSSlider(frame: NSRect(x: 130, y: view.frame.height - 180, width: 120, height: 20))
        thresholdSlider.minValue = -60.0  // -60dB
        thresholdSlider.maxValue = -20.0  // -20dB
        thresholdSlider.floatValue = threshold
        thresholdSlider.target = self
        thresholdSlider.action = #selector(thresholdChanged(_:))
        view.addSubview(thresholdSlider)
        
        let thresholdValueLabel = NSTextField(frame: NSRect(x: 260, y: view.frame.height - 180, width: 40, height: 20))
        thresholdValueLabel.isEditable = false
        thresholdValueLabel.stringValue = String(format: "%.1f", threshold)
        thresholdValueLabel.tag = 102 // Tag for updating later
        view.addSubview(thresholdValueLabel)
        
        // Master gain
        let gainLabel = NSTextField(labelWithString: "Master Gain (dB):")
        gainLabel.frame = NSRect(x: 30, y: view.frame.height - 210, width: 90, height: 20)
        gainLabel.alignment = .right
        view.addSubview(gainLabel)
        
        masterGainSlider = NSSlider(frame: NSRect(x: 130, y: view.frame.height - 210, width: 120, height: 20))
        masterGainSlider.minValue = -12.0  // -12dB
        masterGainSlider.maxValue = 12.0   // +12dB
        masterGainSlider.floatValue = masterGain
        masterGainSlider.target = self
        masterGainSlider.action = #selector(masterGainChanged(_:))
        view.addSubview(masterGainSlider)
        
        let gainValueLabel = NSTextField(frame: NSRect(x: 260, y: view.frame.height - 210, width: 40, height: 20))
        gainValueLabel.isEditable = false
        gainValueLabel.stringValue = String(format: "%.1f", masterGain)
        gainValueLabel.tag = 103 // Tag for updating later
        view.addSubview(gainValueLabel)
        
        // Preset buttons
        let presetLabel = NSTextField(labelWithString: "Presets:")
        presetLabel.frame = NSRect(x: 20, y: 20, width: 70, height: 20)
        view.addSubview(presetLabel)
        
        let presetButtons = [
            ("Default", 0),
            ("Conference", 1),
            ("Music", 2),
            ("Presentation", 3)
        ]
        
        var xPos = 90
        for (title, tag) in presetButtons {
            let button = NSButton(frame: NSRect(x: xPos, y: 20, width: 90, height: 24))
            button.title = title
            button.bezelStyle = .rounded
            button.target = self
            button.tag = tag
            button.action = #selector(presetButtonClicked(_:))
            view.addSubview(button)
            xPos += 100
        }
    }
    
    private func updateUI() {
        // Update value labels with current slider values
        if let attackLabel = view.viewWithTag(100) as? NSTextField {
            attackLabel.stringValue = String(format: "%.1f", attackMs)
        }
        
        if let releaseLabel = view.viewWithTag(101) as? NSTextField {
            releaseLabel.stringValue = String(format: "%.1f", releaseMs)
        }
        
        if let thresholdLabel = view.viewWithTag(102) as? NSTextField {
            thresholdLabel.stringValue = String(format: "%.1f", threshold)
        }
        
        if let gainLabel = view.viewWithTag(103) as? NSTextField {
            gainLabel.stringValue = String(format: "%.1f", masterGain)
        }
    }
    
    // MARK: - Actions
    
    @objc func attackChanged(_ sender: NSSlider) {
        attackMs = sender.floatValue
        if let kernelPtr = kernelPtr {
            WDSPKernel_setTimeConstants(kernelPtr, attackMs, releaseMs)
        }
    }
    
    @objc func releaseChanged(_ sender: NSSlider) {
        releaseMs = sender.floatValue
        if let kernelPtr = kernelPtr {
            WDSPKernel_setTimeConstants(kernelPtr, attackMs, releaseMs)
        }
    }
    
    @objc func thresholdChanged(_ sender: NSSlider) {
        threshold = sender.floatValue
        if let kernelPtr = kernelPtr {
            WDSPKernel_setAdaptiveThreshold(kernelPtr, threshold)
        }
    }
    
    @objc func masterGainChanged(_ sender: NSSlider) {
        masterGain = sender.floatValue
        if let kernelPtr = kernelPtr {
            WDSPKernel_setMasterGain(kernelPtr, masterGain)
        }
    }
    
    @objc func presetButtonClicked(_ sender: NSButton) {
        let presetIndex = sender.tag
        if let kernelPtr = kernelPtr {
            WDSPKernel_applyPreset(kernelPtr, Int32(presetIndex))
            
            // Update UI to reflect preset values
            // This would normally query the kernel for the current values
            // but for simplicity, we'll use preset values
            switch presetIndex {
            case 0: // Default
                attackMs = 10.0
                releaseMs = 100.0
            case 1: // Conference
                attackMs = 5.0
                releaseMs = 50.0
            case 2: // Music
                attackMs = 20.0
                releaseMs = 200.0
            case 3: // Presentation
                attackMs = 10.0
                releaseMs = 150.0
            default:
                break
            }
            
            // Update sliders to match preset values
            attackSlider.floatValue = attackMs
            releaseSlider.floatValue = releaseMs
            
            // Update UI labels
            updateUI()
        }
    }
}
