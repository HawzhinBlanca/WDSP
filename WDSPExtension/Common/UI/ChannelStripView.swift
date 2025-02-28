//
//  representing.swift
//  WDSP
//
//  Created by HAWZHIN on 27/02/2025.
//


import AppKit
import AudioToolbox

/**
 * View class representing controls for one channel of the Dugan Automixer.
 * 
 * Each channel strip contains:
 * - Weight control (vertical slider)
 * - Auto button (enables/disables automixing for this channel)
 * - Override button (gives this channel priority)
 * - Input level meter
 * - Gain reduction meter
 */
class ChannelStripView: NSView {
    // UI Controls
    private var titleLabel: NSTextField!
    private var weightSlider: NSSlider!
    private var autoButton: NSButton!
    private var overrideButton: NSButton!
    private var inputMeter: NSLevelIndicator!
    private var gainMeter: NSLevelIndicator!
    
    // Parameters
    private var weightParameter: AUParameter?
    private var autoParameter: AUParameter?
    private var overrideParameter: AUParameter?
    private var inputMeterParameter: AUParameter?
    private var gainMeterParameter: AUParameter?
    
    init(frame: NSRect, channel: Int) {
        super.init(frame: frame)
        setupUI(channel: channel)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    private func setupUI(channel: Int) {
        // Channel title
        titleLabel = NSTextField(labelWithString: "Channel \(channel + 1)")
        titleLabel.frame = NSRect(x: 5, y: frame.height - 25, width: frame.width - 10, height: 20)
        titleLabel.font = NSFont.boldSystemFont(ofSize: 12)
        titleLabel.alignment = .center
        titleLabel.isEditable = false
        titleLabel.isBezeled = false
        titleLabel.drawsBackground = false
        addSubview(titleLabel)
        
        // Weight slider (vertical)
        weightSlider = NSSlider(frame: NSRect(x: 10, y: 50, width: 20, height: 150))
        weightSlider.minValue = 0.0
        weightSlider.maxValue = 2.0
        weightSlider.floatValue = 1.0
        weightSlider.isVertical = true
        addSubview(weightSlider)
        
        // Weight label
        let weightLabel = NSTextField(labelWithString: "Weight")
        weightLabel.frame = NSRect(x: 5, y: 200, width: 50, height: 20)
        weightLabel.alignment = .center
        weightLabel.font = NSFont.systemFont(ofSize: 10)
        weightLabel.isEditable = false
        weightLabel.isBezeled = false
        weightLabel.drawsBackground = false
        addSubview(weightLabel)
        
        // Auto button
        autoButton = NSButton(frame: NSRect(x: 10, y: 30, width: 60, height: 18))
        autoButton.title = "Auto"
        autoButton.setButtonType(.switch)
        autoButton.state = .on
        addSubview(autoButton)
        
        // Override button
        overrideButton = NSButton(frame: NSRect(x: 10, y: 10, width: 70, height: 18))
        overrideButton.title = "Override"
        overrideButton.setButtonType(.switch)
        overrideButton.state = .off
        addSubview(overrideButton)
        
        // Input level meter (vertical)
        inputMeter = NSLevelIndicator(frame: NSRect(x: 40, y: 50, width: 15, height: 150))
        inputMeter.levelIndicatorStyle = .continuousCapacity
        inputMeter.minValue = -60.0
        inputMeter.maxValue = 0.0
        inputMeter.warningValue = -12.0
        inputMeter.criticalValue = -3.0
        addSubview(inputMeter)
        
        // Input meter label
        let inputLabel = NSTextField(labelWithString: "Input")
        inputLabel.frame = NSRect(x: 30, y: 200, width: 40, height: 20)
        inputLabel.alignment = .center
        inputLabel.font = NSFont.systemFont(ofSize: 10)
        inputLabel.isEditable = false
        inputLabel.isBezeled = false
        inputLabel.drawsBackground = false
        addSubview(inputLabel)
        
        // Gain reduction meter (vertical)
        gainMeter = NSLevelIndicator(frame: NSRect(x: 65, y: 50, width: 15, height: 150))
        gainMeter.levelIndicatorStyle = .continuousCapacity
        gainMeter.minValue = -30.0
        gainMeter.maxValue = 0.0
        addSubview(gainMeter)
        
        // Gain meter label
        let gainLabel = NSTextField(labelWithString: "Gain")
        gainLabel.frame = NSRect(x: 55, y: 200, width: 40, height: 20)
        gainLabel.alignment = .center
        gainLabel.font = NSFont.systemFont(ofSize: 10)
        gainLabel.isEditable = false
        gainLabel.isBezeled = false
        gainLabel.drawsBackground = false
        addSubview(gainLabel)
        
        // Add border
        wantsLayer = true
        layer?.borderWidth = 1.0
        layer?.borderColor = NSColor.darkGray.withAlphaComponent(0.3).cgColor
        layer?.cornerRadius = 4.0
    }
    
    func bindParameters(paramTree: AUParameterTree, channel: Int) {
        let baseAddress = channel * 5
        
        // Get parameters for this channel
        weightParameter = paramTree.parameter(withAddress: AUParameterAddress(baseAddress))
        autoParameter = paramTree.parameter(withAddress: AUParameterAddress(baseAddress + 1))
        overrideParameter = paramTree.parameter(withAddress: AUParameterAddress(baseAddress + 2))
        inputMeterParameter = paramTree.parameter(withAddress: AUParameterAddress(baseAddress + 3))
        gainMeterParameter = paramTree.parameter(withAddress: AUParameterAddress(baseAddress + 4))
        
        // Initial values
        if let weight = weightParameter {
            weightSlider.floatValue = weight.value
        }
        
        if let auto = autoParameter {
            autoButton.state = auto.value >= 0.5 ? .on : .off
        }
        
        if let override = overrideParameter {
            overrideButton.state = override.value >= 0.5 ? .on : .off
        }
        
        // Slider callback
        weightSlider.target = self
        weightSlider.action = #selector(weightChanged(_:))
        
        // Button callbacks
        autoButton.target = self
        autoButton.action = #selector(autoChanged(_:))
        
        overrideButton.target = self
        overrideButton.action = #selector(overrideChanged(_:))
    }
    
    func updateMeters() {
        if let input = inputMeterParameter {
            inputMeter.doubleValue = Double(input.value)
        }
        
        if let gain = gainMeterParameter {
            gainMeter.doubleValue = Double(gain.value)
        }
    }
    
    // MARK: - Actions
    
    @objc func weightChanged(_ sender: NSSlider) {
        weightParameter?.value = sender.floatValue
    }
    
    @objc func autoChanged(_ sender: NSButton) {
        autoParameter?.value = sender.state == .on ? 1.0 : 0.0
    }
    
    @objc func overrideChanged(_ sender: NSButton) {
        overrideParameter?.value = sender.state == .on ? 1.0 : 0.0
    }
}