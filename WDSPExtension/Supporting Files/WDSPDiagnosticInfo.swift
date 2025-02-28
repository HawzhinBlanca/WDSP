import AVFoundation
import Foundation

/// A struct mirroring the C++ WDSPDiagnosticInfoC struct for interop
struct WDSPDiagnosticInfoCStruct {
    var averageLoad: Float
    var peakLoad: Float
    var overloads: Int32
    var wasBypassEngaged: Bool
    var isBypassEngaged: Bool
    var inputLevel: Float
    var outputLevel: Float
}

/// Swift class to handle diagnostic information from the DSP kernel
public class WDSPDiagnosticInfo {
    // Properties matching the C++ struct
    public private(set) var averageLoad: Float = 0.0
    public private(set) var peakLoad: Float = 0.0
    public private(set) var overloads: Int = 0
    public private(set) var wasBypassEngaged: Bool = false
    public private(set) var isBypassEngaged: Bool = false
    public private(set) var inputLevel: Float = 0.0
    public private(set) var outputLevel: Float = 0.0

    // Internal property for C++ interop - using opaque pointer now
    private var kernelPtr: UnsafeMutableRawPointer?

    public init() {
        // Default initializer
    }

    /// Initialize from a WDSPDiagnosticInfoC struct
    internal init(from diagnosticInfo: WDSPDiagnosticInfoC) {
        self.averageLoad = diagnosticInfo.averageLoad
        self.peakLoad = diagnosticInfo.peakLoad
        self.overloads = Int(diagnosticInfo.overloads)
        self.wasBypassEngaged = diagnosticInfo.wasBypassEngaged
        self.isBypassEngaged = diagnosticInfo.isBypassEngaged
        self.inputLevel = diagnosticInfo.inputLevel
        self.outputLevel = diagnosticInfo.outputLevel
    }

    /// Update diagnostic information from the kernel
    public func updateFromKernel() {
        guard let kernel = kernelPtr else { return }

        // Get the diagnostic info from the kernel through a C++ bridge function
        let diagnosticInfo = wdsp_get_diagnostic_info(kernel)

        self.averageLoad = diagnosticInfo.averageLoad
        self.peakLoad = diagnosticInfo.peakLoad
        self.overloads = Int(diagnosticInfo.overloads)
        self.wasBypassEngaged = diagnosticInfo.wasBypassEngaged
        self.isBypassEngaged = diagnosticInfo.isBypassEngaged
        self.inputLevel = diagnosticInfo.inputLevel
        self.outputLevel = diagnosticInfo.outputLevel
    }

    /// Set the kernel pointer for later updates
    public func setKernelPointer(_ pointer: UnsafeMutableRawPointer) {
        self.kernelPtr = pointer
    }
}

// C function declarations for bridging with C++
// This is just for Swift's compiler - the actual implementation is in C++
@_silgen_name("wdsp_get_diagnostic_info")
internal func wdsp_get_diagnostic_info(_ kernel: UnsafeMutableRawPointer) -> WDSPDiagnosticInfoC
