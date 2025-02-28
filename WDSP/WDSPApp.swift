import SwiftUI
import AVFoundation
import AudioToolbox

// Alternative approach using a direct main() function
// This doesn't require @main at all, avoiding the issue entirely

struct WDSPApp: App {
    @StateObject private var audioEngine = StandaloneAudioEngine()
    
    var body: some Scene {
        WindowGroup {
            StandaloneView()
                .environmentObject(audioEngine)
                .onAppear {
                    audioEngine.loadAudioUnit()
                }
        }
    }
}

// Using a regular main function instead of @main attribute
func main() {
    WDSPApp.main()
}
