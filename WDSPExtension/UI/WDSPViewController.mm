// In WDSPViewController.mm

#import "WDSPViewController.h"
#import "WDSPView.h"
#import <CoreAudioKit/CoreAudioKit.h>

@interface WDSPViewController ()
@property (readwrite, nonatomic) AUAudioUnit *audioUnit; // ✅ Now writable
@end

@interface WDSPViewController () {
    AUAudioUnit* _audioUnit;
    AUParameterTree* _parameterTree;
}

@property (nonatomic, strong) WDSPView* mainView;
@end

@implementation WDSPViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Set fixed size for 4-channel interface
    self.preferredContentSize = NSMakeSize(600, 400);
    
    // Create main view
    self.mainView = [[WDSPView alloc] initWithFrame:self.view.bounds];
    self.mainView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    [self.view addSubview:self.mainView];
}

// This method is called by AudioUnitViewController.swift
- (AUAudioUnit *)createAudioUnitWithComponentDescription:(AudioComponentDescription)desc error:(NSError **)error {
    self.audioUnit = [[AUAudioUnit alloc] initWithComponentDescription:desc error:error];
    
    if (self.audioUnit) {
        // Get parameter tree
        _parameterTree = self.audioUnit.parameterTree;
        
        // Bind parameters to UI
        [self bindParameters];
    }
    
    return self.audioUnit;
}

- (void)bindParameters {
    // For each channel
    for (NSInteger ch = 0; ch < 4; ch++) {
        NSInteger baseAddress = ch * 5; // 5 parameters per channel
        
        // Get parameters for this channel
        AUParameter* weightParam = [_parameterTree parameterWithAddress:baseAddress];
        AUParameter* autoParam = [_parameterTree parameterWithAddress:baseAddress + 1];
        AUParameter* overrideParam = [_parameterTree parameterWithAddress:baseAddress + 2];
        AUParameter* inputParam = [_parameterTree parameterWithAddress:baseAddress + 3];
        AUParameter* gainParam = [_parameterTree parameterWithAddress:baseAddress + 4];
        
        // Setup channel strip with parameters
        [self.mainView setupChannelStrip:ch
                                 weight:weightParam
                                   auto:autoParam
                               override:overrideParam
                                  input:inputParam
                                   gain:gainParam];
    }
}

@end
