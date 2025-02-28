// WDSPView.h
#import <Cocoa/Cocoa.h>
#import <AudioToolbox/AudioToolbox.h>

@interface ChannelStrip : NSView

@property (nonatomic, strong) NSSlider *weightSlider;
@property (nonatomic, strong) NSButton *autoButton;
@property (nonatomic, strong) NSButton *overrideButton;
@property (nonatomic, strong) NSLevelIndicator *inputMeter;
@property (nonatomic, strong) NSLevelIndicator *gainMeter;
@property (nonatomic, strong) NSTextField *channelLabel;

- (id)initWithFrame:(NSRect)frame channel:(NSInteger)channel;
- (void)bindParameters:(AUParameter*)weight auto:(AUParameter*)autoEnable
                override:(AUParameter*)override input:(AUParameter*)input gain:(AUParameter*)gain;

@end

@interface WDSPView : NSView

- (void)setupChannelStrip:(NSInteger)channel
                  weight:(AUParameter*)weight
                    auto:(AUParameter*)autoEnable
                override:(AUParameter*)override
                   input:(AUParameter*)input
                    gain:(AUParameter*)gain;

@end
