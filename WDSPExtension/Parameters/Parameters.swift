// Replace the entire Parameters.swift file with this corrected version:

import AudioToolbox
import Foundation

// Define parameter addresses
enum WDSPParameterAddress: AUParameterAddress {
    // Channel 1
    case weight1 = 0
    case autoEnable1 = 1
    case override1 = 2
    case inputMeter1 = 3
    case gainReduction1 = 4
    
    // Channel 2
    case weight2 = 5
    case autoEnable2 = 6
    case override2 = 7
    case inputMeter2 = 8
    case gainReduction2 = 9
    
    // Channel 3
    case weight3 = 10
    case autoEnable3 = 11
    case override3 = 12
    case inputMeter3 = 13
    case gainReduction3 = 14
    
    // Channel 4
    case weight4 = 15
    case autoEnable4 = 16
    case override4 = 17
    case inputMeter4 = 18
    case gainReduction4 = 19
    
    // Global parameters
    case masterGain = 20
    case attackTime = 21
    case releaseTime = 22
    case adaptiveThreshold = 23
    case presetSelector = 24
}

// Static parameter addresses for C++ interop
struct WDSPParameters {
    // Global parameters
    static let masterGain = WDSPParameterAddress.masterGain.rawValue
    static let attackTime = WDSPParameterAddress.attackTime.rawValue
    static let releaseTime = WDSPParameterAddress.releaseTime.rawValue
    static let adaptiveThreshold = WDSPParameterAddress.adaptiveThreshold.rawValue
    static let presetSelector = WDSPParameterAddress.presetSelector.rawValue
}
