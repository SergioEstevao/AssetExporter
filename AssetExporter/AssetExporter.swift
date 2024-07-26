import Foundation
import AVFoundation

struct AssetExporter {

    static func exportSession(forItem item: AVPlayerItem) async {
        let composition = AVMutableComposition()
        //        while item.status != .readyToPlay {
        //            try? await Task.sleep(for: .seconds(1))
        //        }
        guard let compositionAudioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID:  CMPersistentTrackID(kCMPersistentTrackID_Invalid)),
              let sourceAudioTrack = try? await item.asset.loadTracks(withMediaType: .audio).first else {
            print("Failed to create audio track")
            return
        }
        do {
            let duration = try await item.asset.load(.duration)
            try compositionAudioTrack.insertTimeRange(CMTimeRangeMake(start: .zero, duration: duration), of: sourceAudioTrack, at: CMTime.zero)
        } catch {
            print("Failed to create audio track: \(error)")
            return
        }
        
        guard let exporter = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetAppleM4A) else {
            print("Failed to create export session")
            return
        }

        let fileExtension = UTType(AVFileType.m4a.rawValue)?.preferredFilenameExtension ?? "m4a"
        let fileName = (item.asset as! AVURLAsset).url.lastPathComponent.replacingOccurrences(of: (item.asset as! AVURLAsset).url.pathExtension, with: fileExtension)
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
        exporter.shouldOptimizeForNetworkUse = true
        await exporter.export()
        print("Exporter did finish: \(outputURL)")
        if let error = exporter.error {
            print("Exporter error: \(error)")
        }

        if exporter.status == .cancelled {
            print("Export cancelled")
            return
        }

        if exporter.status == .failed {
            print("Exporter failed")
            return
        }
    }

}
