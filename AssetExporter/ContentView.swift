import SwiftUI
import AVKit

var customLoaderDelegate: AssetExporterResourceLoaderDelegate?

struct ContentView: View {
    // standard player used in all examples
    let player = AVPlayer()
    @State var audioURL: String = "https://www.podtrac.com/pts/redirect.mp3/pdst.fm/e/chrt.fm/track/FACB75/traffic.megaphone.fm/NEXTDP6425035030.mp3?updated=1714419615"

    var body: some View {

        VStack {
            VideoPlayer(player: player)
            TextField("URL", text: $audioURL)
                .disableAutocorrection(true)
                .border(.secondary)
                .padding()
            // Example 1: Default player setup with no extras
            Button("Default Player") {
                player.replaceCurrentItem(with: AVPlayerItem(url: URL(string: audioURL)!))
                player.play()
            }.padding()

            // Example 2: Setup with custom resource loader delegate
            Button("Player with custom resource loader") {
                // must not use "https" or "http", the custom loader delegate will not be called!
                let asset = AVURLAsset(url: URL(string: "custom-\(audioURL)")!)
                customLoaderDelegate = AssetExporterResourceLoaderDelegate(userAgent: "")
                asset.resourceLoader.setDelegate(customLoaderDelegate, queue: .global(qos: .default))
                player.replaceCurrentItem(with: AVPlayerItem(asset: asset))
                player.play()
            }.padding()

            // Example 3: Parallel Export session
            Button("Player with parallel export session") {
                // must not use "https" or "http", the custom loader delegate will not be called!
                let asset = AVURLAsset(url: URL(string: audioURL)!)
                let item = AVPlayerItem(asset: asset)
                Task {
                    await AssetExporter.exportSession(forItem: item)
                }
                player.replaceCurrentItem(with: item)
                player.play()
            }.padding()
        }

    }

}
