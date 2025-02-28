//
//  WDSPExtension-Bridging-Header.h
//  WDSPExtension
//
//  Created for WDSP Extension.
//

#ifndef WDSPExtension_Bridging_Header_h
#define WDSPExtension_Bridging_Header_h

// Forward declare the WDSPKernel class
class WDSPKernel;

// Define the C diagnostic info struct for Swift interop
typedef struct {
    float averageLoad;
    float peakLoad;
    int overloads;
    bool wasBypassEngaged;
    bool isBypassEngaged;
    float inputLevel;
    float outputLevel;
} WDSPDiagnosticInfoC;

// Declare the C function for getting diagnostic info
#ifdef __cplusplus
extern "C" {
#endif
    WDSPDiagnosticInfoC wdsp_get_diagnostic_info(const WDSPKernel* kernel);
#ifdef __cplusplus
}
#endif

#endif /* WDSPExtension_Bridging_Header_h */ 