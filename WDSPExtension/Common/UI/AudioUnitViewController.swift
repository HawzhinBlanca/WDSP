import CoreAudioKit
import AppKit

/**
 * Main view controller for the WDSP Dugan Automixer audio unit
 */
public class AudioUnitViewController: AUViewController, AUAudioUnitFactory {
    
    // Audio unit
    var audioUnit: WDSPExtensionAudioUnit?
    
    // UI elements
    private var containerView: NSView!
    private var channelStrips: [ChannelStripView] = []
    private var meterUpdateTimer: Timer?
    
    // MARK: - Lifecycle Methods
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set preferred content size for the plugin window
        preferredContentSize = NSSize(width: 550, height: 300)
        
        // Create main container
        setupMainContainer()
        
        // Create title
        setupTitle()
        
        // Setup dummy channels (will be properly initialized when audio unit is created)
        for i in 0..<4 {
            createChannelStrip(channel: i)
        }
    }
    
    public override func viewWillDisappear() {
        super.viewWillDisappear()
        // Stop the meter update timer when the view disappears
        meterUpdateTimer?.invalidate()
        meterUpdateTimer = nil
    }
    
    // MARK: - AUAudioUnitFactory
    
    public func createAudioUnit(with componentDescription: AudioComponentDescription) throws -> AUAudioUnit {
        // Create the audio unit
        audioUnit = try WDSPExtensionAudioUnit(componentDescription: componentDescription, options: [])
        
        guard let au = audioUnit else {
            throw NSError(domain: NSOSStatusErrorDomain, code: Int(kAudioComponentErr_InstanceInvalidated))
        }
        
        // Setup the UI with parameters once the audio unit is created
        DispatchQueue.main.async {
            // Now we can bind the UI to the audio unit's parameter tree
            if let paramTree = au.parameterTree {
                self.bindParametersToUI(paramTree: paramTree)
                self.startMetersUpdate()
            }
        }
        
        return au
    }
    
    // MARK: - Private Methods
    
    private func setupMainContainer() {
        containerView = NSView(frame: NSRect(
            x: 10,
            y: 40,
            width: view.bounds.width - 20,
            height: view.bounds.height - 80
        ))
        containerView.autoresizingMask = [.width, .height]
        view.addSubview(containerView)
        
        // Set background color
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.lightGray.withAlphaComponent(0.2).cgColor
    }
    
    private func setupTitle() {
        let titleLabel = NSTextField(labelWithString: "WDSP Dugan Automixer")
        titleLabel.frame = NSRect(
            x: 0,
            y: view.bounds.height - 40,
            width: view.bounds.width,
            height: 30
        )
        titleLabel.alignment = .center
        titleLabel.font = NSFont.boldSystemFont(ofSize: 16)
        titleLabel.isEditable = false
        titleLabel.isBezeled = false
        titleLabel.drawsBackground = false
        titleLabel.autoresizingMask = [.width]
        view.addSubview(titleLabel)
        
        // Add subtitle
        let subtitleLabel = NSTextField(labelWithString: "Constant Total Gain Automatic Mixer")
        subtitleLabel.frame = NSRect(
            x: 0,
            y: view.bounds.height - 60,
            width: view.bounds.width,
            height: 20
        )
        subtitleLabel.alignment = .center
        subtitleLabel.font = NSFont.systemFont(ofSize: 12)
        subtitleLabel.textColor = NSColor.darkGray
        subtitleLabel.isEditable = false
        subtitleLabel.isBezeled = false
        subtitleLabel.drawsBackground = false
        subtitleLabel.autoresizingMask = [.width]
        view.addSubview(subtitleLabel)
    }
    
    private func createChannelStrip(channel: Int) {
        let stripWidth = (containerView.bounds.width / 4) - 10
        let stripRect = NSRect(
            x: CGFloat(channel) * (containerView.bounds.width / 4) + 5,
            y: 5,
            width: stripWidth,
            height: containerView.bounds.height - 10
        )
        
        let stripView = ChannelStripView(frame: stripRect, channel: channel)
        stripView.autoresizingMask = [.height]
        containerView.addSubview(stripView)
        
        channelStrips.append(stripView)
    }
    
    private func bindParametersToUI(paramTree: AUParameterTree) {
        // For each channel strip, bind the parameters
        for (index, stripView) in channelStrips.enumerated() {
            stripView.bindParameters(paramTree: paramTree, channel: index)
        }
    }
    
    private func startMetersUpdate() {
        // Update meters 20 times per second
        meterUpdateTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            self?.updateAllMeters()
        }
    }
    
    private func updateAllMeters() {
        for stripView in channelStrips {
            stripView.updateMeters()
        }
    }
}
