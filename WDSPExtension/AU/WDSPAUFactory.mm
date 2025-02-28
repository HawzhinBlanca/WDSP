#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import "WDSPAU.h"

// This is the factory function that creates instances of our custom Audio Unit
// This MUST match the name in Info.plist's factoryFunction field
extern "C" __attribute__((visibility("default"))) void* WDSPAUFactoryMain(const AudioComponentDescription* inDesc) {
    // Add comprehensive logging
    NSLog(@"[WDSP Factory] 🚀 Factory function called!");
    
    if (inDesc == NULL) {
        NSLog(@"[WDSP Factory] ❌ Error: Null AudioComponentDescription");
        return NULL;
    }
    
    // Log the component details
    NSLog(@"[WDSP Factory] Component type: %.4s", (char*)&inDesc->componentType);
    NSLog(@"[WDSP Factory] Component subtype: %.4s", (char*)&inDesc->componentSubType);
    NSLog(@"[WDSP Factory] Component manufacturer: %.4s", (char*)&inDesc->componentManufacturer);
    
    // Check for exact matches - use direct FourCharCode comparison
    BOOL isCorrectType = (inDesc->componentType == kAudioUnitType_Effect);  // 'aufx'
    BOOL isCorrectSubtype = (inDesc->componentSubType == 'WDSP');           // Must match Info.plist EXACTLY!
    BOOL isCorrectManufacturer = (inDesc->componentManufacturer == 'Demo'); // Must match Info.plist EXACTLY!
    
    NSLog(@"[WDSP Factory] Type match: %@", isCorrectType ? @"✅" : @"❌");
    NSLog(@"[WDSP Factory] Subtype match: %@", isCorrectSubtype ? @"✅" : @"❌");
    NSLog(@"[WDSP Factory] Manufacturer match: %@", isCorrectManufacturer ? @"✅" : @"❌");
    
    // Only create if all match
    if (isCorrectType && isCorrectSubtype && isCorrectManufacturer) {
        NSLog(@"[WDSP Factory] ✅ Matched our component! Creating audio unit...");
        
        // Create an instance of our audio unit
        NSError* error = nil;
        WDSPAU* result = [[WDSPAU alloc] initWithComponentDescription:*inDesc
                                                              options:0
                                                                error:&error];
        
        if (error || result == nil) {
            NSLog(@"[WDSP Factory] ❌ Failed to create WDSPAU: %@", error);
            return NULL;
        }
        
        NSLog(@"[WDSP Factory] ✅ Successfully created audio unit instance: %@", result);
        
        // Return the instance, transferring ownership to the caller
        return (__bridge_retained void*)result;
    }
    
    // Not our component
    NSLog(@"[WDSP Factory] ❌ Component description does not match our audio unit");
    return NULL;
}
