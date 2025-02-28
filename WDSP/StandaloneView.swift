//
//  StandaloneView.swift
//  WDSP
//
//  Created by HAWZHIN on 28/02/2025.
//


import SwiftUI
import AVFoundation
import AudioToolbox
import CoreAudio

struct StandaloneView: View {
    @EnvironmentObject var audioEngine: StandaloneAudioEngine
    
    var body: some View {
        VStack(spacing: 20) {
            Text("WDSP Dugan Automixer")
                .font(.largeTitle)
                .padding()
            
            if let errorMessage = audioEngine.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
            }
            
            if audioEngine.isLoading {
                ProgressView("Loading Audio Unit...")
                    .frame(width: 550, height: 350)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
            } else {
                Text("Audio Unit Not Available")
                    .frame(width: 550, height: 350)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
            }
            
            Button(action: {
                audioEngine.togglePlayback()
            }) {
                Text(audioEngine.isPlaying ? "Stop" : "Start")
                    .padding()
                    .frame(width: 150)
                    .background(audioEngine.isPlaying ? Color.red : Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            
            Button(action: {
                audioEngine.loadAudioUnit()
            }) {
                Text("Reload Audio Unit")
                    .padding()
                    .frame(width: 150)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            
            Text("Standalone Host Application")
                .font(.caption)
                .padding(.bottom, 20)
        }
        .frame(minWidth: 600, minHeight: 450)
    }
}

struct AUViewControllerWrapper: NSViewControllerRepresentable {
    let viewController: NSViewController
    
    func makeNSViewController(context: Context) -> NSViewController {
        return viewController
    }
    
    func updateNSViewController(_ nsViewController: NSViewController, context: Context) {
        // No updates needed
    }
}
