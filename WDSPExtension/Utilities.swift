//
//  Utilities.swift
//  WDSP
//
//  Created by HAWZHIN on 28/02/2025.
//


import Foundation
import CoreAudio

/// Converts a string to a FourCharCode
/// Used for Audio Unit component identification
func fourCharCode(_ string: String) -> FourCharCode {
    var result: FourCharCode = 0
    let paddedString = string.padding(toLength: 4, withPad: " ", startingAt: 0)
    for char in paddedString.utf8 {
        result = (result << 8) | FourCharCode(char)
    }
    return result
}

/// Converts a FourCharCode to a human-readable string
/// Used for debugging and logging Audio Unit components
func fourCharCodeToString(_ code: FourCharCode) -> String {
    let chars: [CChar] = [
        CChar((code >> 24) & 0xFF),
        CChar((code >> 16) & 0xFF),
        CChar((code >> 8) & 0xFF),
        CChar(code & 0xFF),
        0 // Null terminator
    ]
    return String(cString: chars)
}