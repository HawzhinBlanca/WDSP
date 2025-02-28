#import "WDSPView.h"

@implementation ChannelStrip

- (id)initWithFrame:(NSRect)frame channel:(NSInteger)channel {
    self = [super initWithFrame:frame];
    if (self) {
        // Channel label
        _channelLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(5, frame.size.height - 25, 90, 20)];
        [_channelLabel setStringValue:[NSString stringWithFormat:@"Channel %ld", channel + 1]];
        [_channelLabel setEditable:NO];
        [_channelLabel setBezeled:NO];
        [_channelLabel setDrawsBackground:NO];
        [self addSubview:_channelLabel];
        
        // Weight slider - using vertical orientation
        _weightSlider = [[NSSlider alloc] initWithFrame:NSMakeRect(10, 50, 20, 200)];
        [_weightSlider setMinValue:0.0];
        [_weightSlider setMaxValue:2.0];
        [_weightSlider setFloatValue:1.0];
        #if MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_12
            [_weightSlider setVertical:YES];
        #else
            [(NSSliderCell*)[_weightSlider cell] setControlSize:NSControlSizeRegular];
            [(NSSliderCell*)[_weightSlider cell] setSliderType:NSLinearSlider];
        #endif
        [self addSubview:_weightSlider];
        
        // Auto button
        _autoButton = [[NSButton alloc] initWithFrame:NSMakeRect(5, 30, 60, 18)];
        [_autoButton setTitle:@"Auto"];
        [_autoButton setButtonType:NSButtonTypeSwitch];
        [_autoButton setState:NSControlStateValueOn];
        [self addSubview:_autoButton];
        
        // Override button
        _overrideButton = [[NSButton alloc] initWithFrame:NSMakeRect(5, 10, 70, 18)];
        [_overrideButton setTitle:@"Override"];
        [_overrideButton setButtonType:NSButtonTypeSwitch];
        [self addSubview:_overrideButton];
        
        // Input meter
        _inputMeter = [[NSLevelIndicator alloc] initWithFrame:NSMakeRect(40, 50, 15, 200)];
        [_inputMeter setLevelIndicatorStyle:NSLevelIndicatorStyleContinuousCapacity];
        [_inputMeter setMinValue:-60.0];
        [_inputMeter setMaxValue:0.0];
        [_inputMeter setWarningValue:-12.0];
        [_inputMeter setCriticalValue:-3.0];
        [self addSubview:_inputMeter];
        
        // Gain reduction meter
        _gainMeter = [[NSLevelIndicator alloc] initWithFrame:NSMakeRect(60, 50, 15, 200)];
        [_gainMeter setLevelIndicatorStyle:NSLevelIndicatorStyleContinuousCapacity];
        [_gainMeter setMinValue:-30.0];
        [_gainMeter setMaxValue:0.0];
        [self addSubview:_gainMeter];
    }
    return self;
}

- (void)bindParameters:(AUParameter*)weight auto:(AUParameter*)autoEnable
                override:(AUParameter*)override input:(AUParameter*)input gain:(AUParameter*)gain {
    // Bind weight slider
    [_weightSlider bind:@"value"
              toObject:weight
           withKeyPath:@"value"
               options:nil];
    
    // Bind auto button
    [_autoButton bind:@"value"
            toObject:autoEnable
         withKeyPath:@"value"
             options:nil];
    
    // Bind override button
    [_overrideButton bind:@"value"
                toObject:override
             withKeyPath:@"value"
                 options:nil];
    
    // Setup meter update timer
    [NSTimer scheduledTimerWithTimeInterval:0.05
                                  repeats:YES
                                    block:^(NSTimer* timer) {
        [self->_inputMeter setDoubleValue:input.value];
        [self->_gainMeter setDoubleValue:gain.value];
    }];
}

@end


@implementation WDSPView {
    NSMutableArray<ChannelStrip*>* _channels;
}

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _channels = [NSMutableArray arrayWithCapacity:4];
        self.wantsLayer = YES;
        self.layer.backgroundColor = [NSColor colorWithCalibratedWhite:0.2 alpha:1.0].CGColor;
    }
    return self;
}

- (void)setupChannelStrip:(NSInteger)channel
                  weight:(AUParameter*)weight
                    auto:(AUParameter*)autoEnable
                override:(AUParameter*)override
                   input:(AUParameter*)input
                    gain:(AUParameter*)gain {
    NSRect stripFrame = NSMakeRect(100 * channel + 20, 10, 80, 380);
    ChannelStrip* strip = [[ChannelStrip alloc] initWithFrame:stripFrame channel:channel];
    [_channels addObject:strip];
    [self addSubview:strip];
    
    [strip bindParameters:weight auto:autoEnable override:override input:input gain:gain];
}

@end
