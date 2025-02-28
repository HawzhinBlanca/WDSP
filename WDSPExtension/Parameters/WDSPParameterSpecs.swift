import AudioToolbox
import CoreAudioKit

/**
 * Parameter specifications for the WDSP Dugan Automixer
 */
public class WDSPParameterSpecs {
    
    // Enum to define parameter addresses
    enum ParameterAddress: AUParameterAddress {
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
    }
    
    /**
     * Preset structure for saving and recalling settings
     */
    public class AutomixPreset {
        let name: String
        let parameterValues: [AUParameterAddress: Float]
        
        init(name: String, parameterValues: [AUParameterAddress: Float]) {
            self.name = name
            self.parameterValues = parameterValues
        }
        
        /**
         * Applies the preset to the parameter tree
         */
        func apply(to parameterTree: AUParameterTree) {
            for (address, value) in parameterValues {
                if let param = parameterTree.parameter(withAddress: address) {
                    param.value = value
                }
            }
        }
    }
    
    /**
     * Factory presets for common scenarios
     */
    public static let presets: [AutomixPreset] = [
        AutomixPreset(name: "Default", parameterValues: [
            0: 1.0, 1: 1.0, 2: 0.0,  // Channel 1: Weight 1.0, Auto On, Override Off
            5: 1.0, 6: 1.0, 7: 0.0,  // Channel 2: Weight 1.0, Auto On, Override Off
            10: 1.0, 11: 1.0, 12: 0.0, // Channel 3: Weight 1.0, Auto On, Override Off
            15: 1.0, 16: 1.0, 17: 0.0  // Channel 4: Weight 1.0, Auto On, Override Off
        ]),
        
        AutomixPreset(name: "Conference", parameterValues: [
            0: 1.2, 1: 1.0, 2: 0.0,  // Channel 1: Weight 1.2, Auto On, Override Off (host)
            5: 0.9, 6: 1.0, 7: 0.0,  // Channel 2: Weight 0.9, Auto On, Override Off
            10: 0.9, 11: 1.0, 12: 0.0, // Channel 3: Weight 0.9, Auto On, Override Off
            15: 0.9, 16: 1.0, 17: 0.0  // Channel 4: Weight 0.9, Auto On, Override Off
        ]),
        
        AutomixPreset(name: "Panel Discussion", parameterValues: [
            0: 1.5, 1: 1.0, 2: 0.0,  // Channel 1: Weight 1.5, Auto On, Override Off (moderator)
            5: 1.0, 6: 1.0, 7: 0.0,  // Channel 2: Weight 1.0, Auto On, Override Off
            10: 1.0, 11: 1.0, 12: 0.0, // Channel 3: Weight 1.0, Auto On, Override Off
            15: 1.0, 16: 1.0, 17: 0.0  // Channel 4: Weight 1.0, Auto On, Override Off
        ]),
        
        AutomixPreset(name: "Host with Guests", parameterValues: [
            0: 1.0, 1: 0.0, 2: 1.0,  // Channel 1: Weight 1.0, Auto Off, Override On (host)
            5: 1.0, 6: 1.0, 7: 0.0,  // Channel 2: Weight 1.0, Auto On, Override Off
            10: 1.0, 11: 1.0, 12: 0.0, // Channel 3: Weight 1.0, Auto On, Override Off
            15: 1.0, 16: 1.0, 17: 0.0  // Channel 4: Weight 1.0, Auto On, Override Off
        ]),
        
        AutomixPreset(name: "Equal Weight", parameterValues: [
            0: 1.0, 1: 1.0, 2: 0.0,  // All channels equal
            5: 1.0, 6: 1.0, 7: 0.0,
            10: 1.0, 11: 1.0, 12: 0.0,
            15: 1.0, 16: 1.0, 17: 0.0
        ])
    ]
    
    /**
     * Create factory presets in AUAudioUnit format
     */
    public static var factoryPresets: [AUAudioUnitPreset] {
        var auPresets = [AUAudioUnitPreset]()
        for (index, preset) in presets.enumerated() {
            let auPreset = AUAudioUnitPreset()
            auPreset.name = preset.name
            auPreset.number = Int(index)
            auPresets.append(auPreset)
        }
        return auPresets
    }
    
    /**
     * Create the parameter tree for the audio unit
     */
    static func createAUParameterTree() -> AUParameterTree {
        // Create all parameters
        let parameters = createAllParameters()
        
        // Create tree
        let paramTree = AUParameterTree.createTree(withChildren: parameters)
        
        return paramTree
    }
    
    private static func createAllParameters() -> [AUParameter] {
        var parameters: [AUParameter] = []
        
        // For each channel, create 5 parameters
        for channel in 0..<4 {
            let baseAddress = channel * 5
            
            // Weight parameter (0.0 - 2.0)
            let weight = AUParameterTree.createParameter(
                withIdentifier: "weight\(channel + 1)",
                name: "Weight \(channel + 1)",
                address: AUParameterAddress(baseAddress),
                min: 0.0,
                max: 2.0,
                unit: .generic,
                unitName: nil,
                flags: [.flag_IsWritable, .flag_IsReadable],
                valueStrings: nil,
                dependentParameters: nil)
            weight.value = 1.0 // Default value
            
            // Global controls
            let masterGain = AUParameterTree.createParameter(
                withIdentifier: "masterGain",
                name: "Master Gain",
                address: AUParameterAddress(WDSPParameterAddress.masterGain.rawValue),
                min: 0.0,
                max: 2.0,
                unit: .generic,
                unitName: nil,
                flags: [.flag_IsWritable, .flag_IsReadable],
                valueStrings: nil,
                dependentParameters: nil)
            masterGain.value = 1.0 // Default value

            let attackTime = AUParameterTree.createParameter(
                withIdentifier: "attackTime",
                name: "Attack Time",
                address: AUParameterAddress(WDSPParameterAddress.attackTime.rawValue),
                min: 0.001,
                max: 0.1,
                unit: .seconds,
                unitName: "s",
                flags: [.flag_IsWritable, .flag_IsReadable],
                valueStrings: nil,
                dependentParameters: nil)
            attackTime.value = 0.01 // Default value

            let releaseTime = AUParameterTree.createParameter(
                withIdentifier: "releaseTime",
                name: "Release Time",
                address: AUParameterAddress(WDSPParameterAddress.releaseTime.rawValue),
                min: 0.01,
                max: 0.5,
                unit: .seconds,
                unitName: "s",
                flags: [.flag_IsWritable, .flag_IsReadable],
                valueStrings: nil,
                dependentParameters: nil)
            releaseTime.value = 0.1 // Default value

            let adaptiveThreshold = AUParameterTree.createParameter(
                withIdentifier: "threshold",
                name: "Adaptive Threshold",
                address: AUParameterAddress(WDSPParameterAddress.adaptiveThreshold.rawValue),
                min: -60.0,
                max: -20.0,
                unit: .decibels,
                unitName: "dB",
                flags: [.flag_IsWritable, .flag_IsReadable],
                valueStrings: nil,
                dependentParameters: nil)
            adaptiveThreshold.value = -40.0 // Default value

            // Add these parameters to your parameters array
            parameters.append(contentsOf: [masterGain, attackTime, releaseTime, adaptiveThreshold])
            
            // Auto enable parameter (boolean)
            let auto = AUParameterTree.createParameter(
                withIdentifier: "auto\(channel + 1)",
                name: "Auto \(channel + 1)",
                address: AUParameterAddress(baseAddress + 1),
                min: 0.0,
                max: 1.0,
                unit: .boolean,
                unitName: nil,
                flags: [.flag_IsWritable, .flag_IsReadable],
                valueStrings: nil,
                dependentParameters: nil)
            auto.value = 1.0 // Default to enabled
            
            // Override parameter (boolean)
            let override = AUParameterTree.createParameter(
                withIdentifier: "override\(channel + 1)",
                name: "Override \(channel + 1)",
                address: AUParameterAddress(baseAddress + 2),
                min: 0.0,
                max: 1.0,
                unit: .boolean,
                unitName: nil,
                flags: [.flag_IsWritable, .flag_IsReadable],
                valueStrings: nil,
                dependentParameters: nil)
            override.value = 0.0 // Default to disabled
            
            // Input meter parameter (read-only)
            let inputMeter = AUParameterTree.createParameter(
                withIdentifier: "input\(channel + 1)",
                name: "Input \(channel + 1)",
                address: AUParameterAddress(baseAddress + 3),
                min: -60.0,
                max: 0.0,
                unit: .decibels,
                unitName: "dB",
                flags: [.flag_IsReadable],
                valueStrings: nil,
                dependentParameters: nil)
            inputMeter.value = -60.0 // Default to minimum
            
            // Gain reduction meter parameter (read-only)
            let gainReduction = AUParameterTree.createParameter(
                withIdentifier: "gain\(channel + 1)",
                name: "Gain \(channel + 1)",
                address: AUParameterAddress(baseAddress + 4),
                min: -30.0,
                max: 0.0,
                unit: .decibels,
                unitName: "dB",
                flags: [.flag_IsReadable],
                valueStrings: nil,
                dependentParameters: nil)
            gainReduction.value = 0.0 // Default to no reduction
            
            parameters.append(contentsOf: [weight, auto, override, inputMeter, gainReduction])
        }
        
        return parameters
    }
    
    /**
     * Get a user-friendly description of a parameter
     */
    static func getParameterInfo(forAddress address: AUParameterAddress) -> (name: String, isReadOnly: Bool) {
        let channel = Int(address) / 5 + 1
        let paramType = Int(address) % 5
        
        switch paramType {
        case 0:
            return ("Weight for channel \(channel)", false)
        case 1:
            return ("Auto mixing for channel \(channel)", false)
        case 2:
            return ("Override for channel \(channel)", false)
        case 3:
            return ("Input level for channel \(channel)", true)
        case 4:
            return ("Gain reduction for channel \(channel)", true)
        default:
            return ("Unknown parameter", false)
        }
    }
    
    /**
     * Get a localized string value for a parameter
     */
    static func formatValue(forParameter parameter: AUParameter, value: Float) -> String {
        let paramType = Int(parameter.address) % 5
        
        switch paramType {
        case 0: // Weight
            return String(format: "%.2f", value)
        case 1: // Auto
            return value >= 0.5 ? "On" : "Off"
        case 2: // Override
            return value >= 0.5 ? "On" : "Off"
        case 3: // Input level
            return String(format: "%.1f dB", value)
        case 4: // Gain reduction
            return String(format: "%.1f dB", value)
        default:
            return String(format: "%.2f", value)
        }
    }
    
    /**
     * Convert user preset data to/from dictionary for saving/loading
     */
    static func dictionaryFromParameterValues(_ values: [AUParameterAddress: Float]) -> [String: Float] {
        var dict = [String: Float]()
        for (address, value) in values {
            dict[String(address)] = value
        }
        return dict
    }
    
    static func parameterValuesFromDictionary(_ dict: [String: Float]) -> [AUParameterAddress: Float] {
        var values = [AUParameterAddress: Float]()
        for (key, value) in dict {
            if let address = AUParameterAddress(key) {
                values[address] = value
            }
        }
        return values
    }
}
