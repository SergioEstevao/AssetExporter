import SwiftUI
import AVKit

var customLoaderDelegate: AssetExporterResourceLoaderDelegate?

struct ContentView: View {
    // standard player used in all examples
    let player = AVPlayer()
    @State var audioURL: String =
        //"https://traffic.libsyn.com/secure/wellkeptwallet/Episode_134_-_Jillian.mp3?dest-id=142551"
        //"https://traffic.libsyn.com/secure/wellkeptwallet/123_-_How_She_Became_Financially_Independent_By_Living_Overseas.mp3?dest-id=142551"
        "https://sarahwallinhuff.com/wp-content/uploads/2024/06/Unit-2-b-AUDIO-2.mp3" //"https://www.podtrac.com/pts/redirect.mp3/pdst.fm/e/chrt.fm/track/FACB75/traffic.megaphone.fm/NEXTDP6425035030.mp3?updated=1714419615"

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
                player.pause()
                let asset = AVURLAsset(url: URL(string: audioURL)!)
                let item = AVPlayerItem(asset: asset)
                player.replaceCurrentItem(with: item)
                player.play()
                Task {
                    await AssetExporter.exportSession(forItem: item)
                }
            }.padding()
        }

    }

}
