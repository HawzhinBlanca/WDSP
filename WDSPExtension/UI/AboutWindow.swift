//
//  AboutWindowController.swift
//  WDSP
//
//  Created by HAWZHIN on 26/02/2025.
//


import AppKit
import os.log

/**
 * Window controller for the About window
 */
class AboutWindowController: NSWindowController {
    
    init() {
        // Create window
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 400),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "About WDSP Dugan Automixer"
        window.isReleasedWhenClosed = false
        
        // Create the about view
        let aboutView = AboutView(frame: window.contentView!.bounds)
        aboutView.autoresizingMask = [.width, .height]
        window.contentView?.addSubview(aboutView)
        
        super.init(window: window)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/**
 * View that displays information about the plugin
 */
class AboutView: NSView {
    private let logger = Logger(subsystem: "com.wdsp.automixer", category: "About")
    
    override init(frame: NSRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        // Set background
        wantsLayer = true
        layer?.backgroundColor = NSColor(calibratedWhite: 0.18, alpha: 1.0).cgColor
        
        // Create header section with logo
        let headerView = NSView(frame: NSRect(
            x: 0,
            y: frame.height - 120,
            width: frame.width,
            height: 120
        ))
        headerView.wantsLayer = true
        headerView.layer?.backgroundColor = NSColor(calibratedWhite: 0.12, alpha: 1.0).cgColor
        addSubview(headerView)
        
        // Title
        let titleLabel = NSTextField(labelWithString: "WDSP Dugan Automixer")
        titleLabel.frame = NSRect(x: 0, y: headerView.frame.height - 50, width: headerView.frame.width, height: 30)
        titleLabel.alignment = .center
        titleLabel.font = NSFont.boldSystemFont(ofSize: 20)
        titleLabel.textColor = NSColor.white
        titleLabel.isEditable = false
        titleLabel.isBezeled = false
        titleLabel.drawsBackground = false
        headerView.addSubview(titleLabel)
        
        // Version
        let versionLabel = NSTextField(labelWithString: "Version 1.0.0")
        versionLabel.frame = NSRect(x: 0, y: headerView.frame.height - 80, width: headerView.frame.width, height: 20)
        versionLabel.alignment = .center
        versionLabel.font = NSFont.systemFont(ofSize: 14)
        versionLabel.textColor = NSColor.lightGray
        versionLabel.isEditable = false
        versionLabel.isBezeled = false
        versionLabel.drawsBackground = false
        headerView.addSubview(versionLabel)
        
        // Copyright
        let copyrightLabel = NSTextField(labelWithString: "© 2025 WDSP Audio Software")
        copyrightLabel.frame = NSRect(x: 0, y: headerView.frame.height - 100, width: headerView.frame.width, height: 20)
        copyrightLabel.alignment = .center
        copyrightLabel.font = NSFont.systemFont(ofSize: 12)
        copyrightLabel.textColor = NSColor.lightGray
        copyrightLabel.isEditable = false
        copyrightLabel.isBezeled = false
        copyrightLabel.drawsBackground = false
        headerView.addSubview(copyrightLabel)
        
        // Create scrollable description area
        let scrollView = NSScrollView(frame: NSRect(
            x: 20,
            y: 80,
            width: frame.width - 40,
            height: frame.height - 210
        ))
        scrollView.hasVerticalScroller = true
        scrollView.borderType = .noBorder
        scrollView.autoresizingMask = [.width, .height]
        addSubview(scrollView)
        
        // Description text view
        let textView = NSTextView(frame: NSRect(
            x: 0,
            y: 0,
            width: scrollView.contentSize.width,
            height: scrollView.contentSize.height
        ))
        textView.textContainerInset = NSSize(width: 10, height: 10)
        textView.isEditable = false
        textView.isSelectable = true
        textView.isRichText = true
        textView.backgroundColor = NSColor(calibratedWhite: 0.22, alpha: 1.0)
        textView.textStorage?.append(createAttributedDescription())
        
        scrollView.documentView = textView
        
        // Buttons at the bottom
        createButtons()
    }
    
    private func createAttributedDescription() -> NSAttributedString {
        let result = NSMutableAttributedString()
        
        // Title style
        let titleStyle = [
            NSAttributedString.Key.font: NSFont.boldSystemFont(ofSize: 14),
            NSAttributedString.Key.foregroundColor: NSColor.white
        ]
        
        // Body style
        let bodyStyle = [
            NSAttributedString.Key.font: NSFont.systemFont(ofSize: 12),
            NSAttributedString.Key.foregroundColor: NSColor.white
        ]
        
        // Add description
        result.append(NSAttributedString(string: "About the Dugan Automixer\n\n", attributes: titleStyle))
        result.append(NSAttributedString(string: "The WDSP Dugan Automixer is based on Dan Dugan's patented automatic mixing algorithm. It automatically maintains a consistent total gain across multiple microphones, ensuring smooth transitions between speakers while minimizing background noise and feedback.\n\n", attributes: bodyStyle))
        
        // Key features
        result.append(NSAttributedString(string: "Key Features:\n\n", attributes: titleStyle))
        result.append(NSAttributedString(string: "• Constant Total Gain (NOM=1): Ensures the combined output level equals a single open microphone.\n", attributes: bodyStyle))
        result.append(NSAttributedString(string: "• Per-Channel Weight Control: Adjust the relative sensitivity of each channel.\n", attributes: bodyStyle))
        result.append(NSAttributedString(string: "• Override Functionality: Let selected channels take priority when needed.\n", attributes: bodyStyle))
        result.append(NSAttributedString(string: "• Real-time Metering: Visual feedback for input levels and gain reduction.\n", attributes: bodyStyle))
        result.append(NSAttributedString(string: "• Preset Management: Save and recall your favorite settings.\n\n", attributes: bodyStyle))
        
        // Use cases
        result.append(NSAttributedString(string: "Common Use Cases:\n\n", attributes: titleStyle))
        result.append(NSAttributedString(string: "• Conference Calls: Automatically mix multiple participants.\n", attributes: bodyStyle))
        result.append(NSAttributedString(string: "• Panel Discussions: Ensure clear audio from all panelists.\n", attributes: bodyStyle))
        result.append(NSAttributedString(string: "• Broadcast: Maintain consistent levels for interviews and roundtables.\n", attributes: bodyStyle))
        result.append(NSAttributedString(string: "• Houses of Worship: Manage multiple microphones for speakers and performers.\n\n", attributes: bodyStyle))
        
        // Credits
        result.append(NSAttributedString(string: "Credits:\n\n", attributes: titleStyle))
        result.append(NSAttributedString(string: "Algorithm based on Dan Dugan's automixing patent.\nDSP implementation and UI design by WDSP Audio Software.\n\n", attributes: bodyStyle))
        
        return result
    }
    
    private func createButtons() {
        // Documentation button
        let docsButton = NSButton(frame: NSRect(
            x: 30,
            y: 20,
            width: 120,
            height: 30
        ))
        docsButton.title = "Documentation"
        docsButton.bezelStyle = .rounded
        docsButton.target = self
        docsButton.action = #selector(openDocumentation(_:))
        addSubview(docsButton)
        
        // Website button
        let websiteButton = NSButton(frame: NSRect(
            x: (frame.width / 2) - 60,
            y: 20,
            width: 120,
            height: 30
        ))
        websiteButton.title = "Website"
        websiteButton.bezelStyle = .rounded
        websiteButton.target = self
        websiteButton.action = #selector(openWebsite(_:))
        addSubview(websiteButton)
        
        // Support button
        let supportButton = NSButton(frame: NSRect(
            x: frame.width - 150,
            y: 20,
            width: 120,
            height: 30
        ))
        supportButton.title = "Support"
        supportButton.bezelStyle = .rounded
        supportButton.target = self
        supportButton.action = #selector(openSupport(_:))
        addSubview(supportButton)
    }
    
    // MARK: - Actions
    
    @objc func openDocumentation(_ sender: NSButton) {
        if let url = URL(string: "https://www.wdsp-audio.com/docs/dugan-automixer") {
            NSWorkspace.shared.open(url)
            logger.info("Opening documentation URL")
        }
    }
    
    @objc func openWebsite(_ sender: NSButton) {
        if let url = URL(string: "https://www.wdsp-audio.com") {
            NSWorkspace.shared.open(url)
            logger.info("Opening website URL")
        }
    }
    
    @objc func openSupport(_ sender: NSButton) {
        if let url = URL(string: "https://www.wdsp-audio.com/support") {
            NSWorkspace.shared.open(url)
            logger.info("Opening support URL")
        }
    }
}

// Extension to AudioUnitViewController to add an about button
extension AudioUnitViewController {
    func addAboutButton() {
        let aboutButton = NSButton(frame: NSRect(
            x: 20,
            y: view.bounds.height - 92,
            width: 80,
            height: 24
        ))
        aboutButton.title = "About"
        aboutButton.bezelStyle = .rounded
        aboutButton.target = self
        aboutButton.action = #selector(showAbout(_:))
        aboutButton.autoresizingMask = [.maxXMargin]
        view.addSubview(aboutButton)
    }
    
    @objc func showAbout(_ sender: NSButton) {
        let windowController = AboutWindowController()
        windowController.showWindow(sender)
        
        // Keep a reference to the window controller
        NSApp.windows.first?.windowController = windowController
    }
}