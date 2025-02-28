import AVFoundation
import AppKit
import AudioToolbox
import CoreAudioKit
import Foundation
import SwiftUI

// MARK: - Common Enums

/// Enum to track audio unit loading state
enum AULoadState {
    case uninitialized
    case initialized
    case failed
}

// MARK: - Four-character code utilities

/// Convert a string to a FourCharCode (OSType)
func fourCharCode(_ string: String) -> FourCharCode {
    var result: FourCharCode = 0
    let paddedString = string.padding(toLength: 4, withPad: " ", startingAt: 0)
    for char in paddedString.utf8 {
        result = (result << 8) | FourCharCode(char)
    }
    return result
}

/// Convert a FourCharCode to a readable string
func fourCharCodeToString(_ code: FourCharCode) -> String {
    let chars: [CChar] = [
        CChar((code >> 24) & 0xFF),
        CChar((code >> 16) & 0xFF),
        CChar((code >> 8) & 0xFF),
        CChar(code & 0xFF),
        0,  // Null terminator
    ]
    return String(cString: chars)
}

// MARK: - UI Components

/// Custom power button style
struct PowerButtonStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            Image(systemName: configuration.isOn ? "power.circle.fill" : "power.circle")
                .foregroundColor(configuration.isOn ? .green : .red)
                .font(.system(size: 28))
                .symbolRenderingMode(.hierarchical)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
