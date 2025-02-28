//
//  WDSPExtensionAudioUnit.swift
//  WDSPExtension
//

import AVFoundation
import AudioToolbox
import CoreAudioKit
import os

/// Main audio unit class for the WDSP Dugan Automixer
public class WDSPExtensionAudioUnit: AUAudioUnit {

    // MARK: - Properties

    private var kernelPtr: UnsafeMutableRawPointer?
    private var inputBusArray: [AUAudioUnitBus] = []
    private var outputBusArray: [AUAudioUnitBus] = []
    private var meterUpdateTimer: Timer?

    // Logger for debugging
    private let logger = Logger(subsystem: "com.yourcompany.WDSP", category: "AudioUnit")

    // MARK: - Parameter Tree

    public override var parameterTree: AUParameterTree? {
        get { return super.parameterTree }
        set { super.parameterTree = newValue }
    }

    // MARK: - Initialization

    public override init(
        componentDescription: AudioComponentDescription,
        options: AudioComponentInstantiationOptions = []
    ) throws {

        // Initialize with parent class
        try super.init(componentDescription: componentDescription, options: options)

        // Create the parameter tree
        parameterTree = WDSPParameterSpecs.createAUParameterTree()

        // Create standard format for 4-channel operation (Dugan typically needs multiple channels)
        let format = AVAudioFormat(
            standardFormatWithSampleRate: 44100.0,
            channels: 4)

        guard let audioFormat = format else {
            throw NSError(
                domain: "com.yourcompany.WDSP",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Failed to create audio format"])
        }

        // Create the kernel via C bridge
        kernelPtr = WDSPKernel_create(audioFormat.sampleRate)

        guard kernelPtr != nil else {
            throw NSError(
                domain: "com.yourcompany.WDSP",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Failed to create DSP kernel"])
        }

        // Setup input bus
        let inputBus = try AUAudioUnitBus(format: audioFormat)
        inputBusArray = [inputBus]

        // Setup output bus
        let outputBus = try AUAudioUnitBus(format: audioFormat)
        outputBusArray = [outputBus]

        // Setup parameter callbacks
        setupParameterCallbacks()

        // Start meter update timer
        startMeterUpdateTimer()
    }

    deinit {
        // Clean up resources
        meterUpdateTimer?.invalidate()
        meterUpdateTimer = nil

        if let kernelPtr = kernelPtr {
            WDSPKernel_destroy(kernelPtr)
        }
    }

    // MARK: - AUAudioUnit Overrides

    public override var inputBusses: AUAudioUnitBusArray {
        return AUAudioUnitBusArray(audioUnit: self, busType: .input, busses: inputBusArray)
    }

    public override var outputBusses: AUAudioUnitBusArray {
        return AUAudioUnitBusArray(audioUnit: self, busType: .output, busses: outputBusArray)
    }

    public override var channelCapabilities: [NSNumber]? {
        return [4, 4]  // 4 input channels, 4 output channels
    }

    public override func allocateRenderResources() throws {
        try super.allocateRenderResources()

        // Initialize kernel with current sample rate
        if let kernelPtr = kernelPtr {
            WDSPKernel_initialize(kernelPtr, outputBusArray[0].format.sampleRate)
        }
    }

    public override func deallocateRenderResources() {
        // Stop timer before deallocating resources
        meterUpdateTimer?.invalidate()
        meterUpdateTimer = nil

        if let kernelPtr = kernelPtr {
            WDSPKernel_reset(kernelPtr)
        }
        super.deallocateRenderResources()
    }

    public override var internalRenderBlock: AUInternalRenderBlock {
        return {
            [weak self]
            actionFlags, timestamp, frameCount, outputBusNumber, outputData, realtimeEventListHead,
            pullInputBlock in

            guard let self = self, let kernelPtr = self.kernelPtr else {
                return kAudioUnitErr_NoConnection
            }

            // Allocate input buffer list
            let inputData = UnsafeMutablePointer<AudioBufferList>.allocate(capacity: 1)
            defer { inputData.deallocate() }

            // Initialize the buffer list structure (required for Swift)
            var bufferList = AudioBufferList()
            bufferList.mNumberBuffers = 0
            inputData.pointee = bufferList

            // Pull input if available
            var err: OSStatus = noErr
            if let pullInputBlock = pullInputBlock {
                err = pullInputBlock(actionFlags, timestamp, frameCount, 0, inputData)
                if err != noErr {
                    if err != kAudioUnitErr_NoConnection {
                        self.logger.error("Pull input error: \(err)")
                    }
                    // If no input is available, zero the output
                    for i in 0..<outputData.pointee.mNumberBuffers {
                        // Access the mBuffers array correctly using pointer arithmetic
                        let outputBuffer = UnsafeMutableAudioBufferListPointer(outputData)[Int(i)]
                        if let data = outputBuffer.mData {
                            memset(data, 0, Int(outputBuffer.mDataByteSize))
                        }
                    }
                    return noErr
                }
            } else {
                // No input available
                for i in 0..<outputData.pointee.mNumberBuffers {
                    // Access the mBuffers array correctly using pointer arithmetic
                    let outputBuffer = UnsafeMutableAudioBufferListPointer(outputData)[Int(i)]
                    if let data = outputBuffer.mData {
                        memset(data, 0, Int(outputBuffer.mDataByteSize))
                    }
                }
                return noErr
            }

            // Process the audio through our C++ implementation
            let status = WDSPKernel_processAudio(
                kernelPtr,
                timestamp,
                UInt32(frameCount),
                inputData,
                outputData
            )

            return status
        }
    }

    // MARK: - Parameter Methods

    private func setupParameterCallbacks() {
        // Set parameter value observer
        parameterTree?.implementorValueObserver = { [weak self] param, value in
            guard let self = self, let kernelPtr = self.kernelPtr else { return }

            // Convert AUParameterAddress to AudioUnitParameterID (they are compatible types)
            let paramID = AudioUnitParameterID(param.address)
            WDSPKernel_setParameter(kernelPtr, paramID, value)
        }

        // Set parameter value provider
        parameterTree?.implementorValueProvider = { [weak self] param in
            guard let self = self, let kernelPtr = self.kernelPtr else { return param.value }

            // Convert AUParameterAddress to AudioUnitParameterID
            let paramID = AudioUnitParameterID(param.address)
            return WDSPKernel_getParameter(kernelPtr, paramID)
        }

        // Set parameter string formatter - FIXED VERSION
        parameterTree?.implementorStringFromValueCallback = { param, valuePtr in
            // Safely unwrap the optional pointer and dereference it
            let rawValue = valuePtr?.pointee ?? param.value  // Fallback to param.value if nil

            // Convert Float (AUValue) to Double for string formatting
            let value = Double(rawValue)

            // Format based on parameter type
            switch param.unit {
            case .boolean:
                return value >= 0.5 ? "On" : "Off"
            case .decibels:
                return String(format: "%.1f dB", value)
            case .seconds:
                return String(format: "%.2f s", value)
            default:
                return String(format: "%.2f", value)
            }
        }
    }

    // MARK: - Meter Updates

    private func startMeterUpdateTimer() {
        // Update meters 10 times per second
        meterUpdateTimer = Timer.scheduledTimer(
            withTimeInterval: 0.1,
            repeats: true
        ) { [weak self] _ in
            self?.updateMeters()
        }
    }

    private func updateMeters() {
        guard let paramTree = self.parameterTree,
            let kernelPtr = self.kernelPtr
        else {
            return
        }

        // Update meters for all 4 channels
        for channel in 0..<4 {
            let baseAddress = channel * 5

            // Update input meter
            if let inputParam = paramTree.parameter(
                withAddress: AUParameterAddress(baseAddress + 3))
            {
                let inputLevel = WDSPKernel_getParameter(
                    kernelPtr, AudioUnitParameterID(baseAddress + 3))
                inputParam.value = inputLevel
            }

            // Update gain reduction meter
            if let gainParam = paramTree.parameter(withAddress: AUParameterAddress(baseAddress + 4))
            {
                let gainReduction = WDSPKernel_getParameter(
                    kernelPtr, AudioUnitParameterID(baseAddress + 4))
                gainParam.value = gainReduction
            }
        }
    }
}
