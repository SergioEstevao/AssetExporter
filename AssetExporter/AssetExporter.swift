import Foundation
import AVFoundation

struct AssetExporter {

    static func exportSession(forItem item: AVPlayerItem) async {
        let composition = AVMutableComposition()
        let compositionAudioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: CMPersistentTrackID(kCMPersistentTrackID_Invalid))

        while item.status != .readyToPlay {
            try? await Task.sleep(for: .seconds(1))
        }

        do {
            let sourceAudioTrack = try await item.asset.loadTracks(withMediaType: .audio).first!
            try compositionAudioTrack?.insertTimeRange(CMTimeRange(start: .zero, end: .indefinite), of: sourceAudioTrack, at: .zero)
        } catch {
            print("Failed to create audio track: \(error)")
            return
        }

        guard let exporter = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetAppleM4A) else {
            print("Failed to create export session")
            return
        }

        let fileName = (item.asset as! AVURLAsset).url.lastPathComponent.replacingOccurrences(of: (item.asset as! AVURLAsset).url.pathExtension, with: "m4a")
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last!
        let outputURL = documentsDirectory.appendingPathComponent(fileName)

        if FileManager.default.fileExists(atPath: outputURL.path) {
            do {
                try FileManager.default.removeItem(at: outputURL)
            } catch let error {
                print("Failed to delete file with error: \(error)")
            }
        }

        exporter.outputURL = outputURL
        exporter.outputFileType = AVFileType.m4a

        await exporter.export()
        print("Exporter did finish: \(outputURL)")
        if let error = exporter.error {
            print("Exporter error: \(error)")
        }
    }

}
