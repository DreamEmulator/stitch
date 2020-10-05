//
//  Stitch.swift
//  stitch
//
//  Created by Sebastiaan Hols on 04/10/2020.
//

import Foundation
import AVFoundation
import MediaPlayer
import Photos

class Stitch {
    let video: URL
    let duration: CMTime
    let audio: MPMediaItem
    
    init(video: URL, audio: MPMediaItem, duration: CMTime){
        self.video = video
        self.audio = audio
        self.duration = duration
    }
    
    func stitch (){
        
        let videoAsset = AVAsset(url: video)
        let musicAsset = AVAsset(url: audio.assetURL!)
        
        let audioVideoComposition = AVMutableComposition()
        
        let videoCompositionTrack = audioVideoComposition
            .addMutableTrack(withMediaType: .video, preferredTrackID: .init())!
        
        let audioCompositionTrack = audioVideoComposition
            .addMutableTrack(withMediaType: .audio, preferredTrackID: .init())!
        
        let videoAssetTrack = videoAsset.tracks(withMediaType: .video)[0]
        let audioAssetTrack = videoAsset.tracks(withMediaType: .audio).first

        do {
            let timeRange = CMTimeRange(start: .zero, duration: videoAsset.duration)
            
            try videoCompositionTrack.insertTimeRange(timeRange, of: videoAssetTrack, at: .zero)
            
            if let audioAssetTrack = audioAssetTrack {
                try audioCompositionTrack.insertTimeRange(timeRange, of: audioAssetTrack, at: .zero)
            }
        } catch {
            print("Failed to insert timeranges")
        }
        
//        let outputFileName = NSUUID().uuidString
//        let outputFilePath = (NSTemporaryDirectory() as NSString).appendingPathComponent((outputFileName as NSString).appendingPathExtension("mp4")!)
        
        let exportUrl = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
            .appendingPathComponent("\(Date().timeIntervalSince1970)-video.mp4")

        let exportSession = AVAssetExportSession(
            asset: audioVideoComposition,
            presetName: AVAssetExportPresetHighestQuality
        )
        
        exportSession?.outputFileType = .m4v
        exportSession?.outputURL = exportUrl
        
        exportSession?.exportAsynchronously(completionHandler: {
            guard let status = exportSession?.status else { return }
            switch status {
                case .completed:
                    //        Add to PhotoLibrary
                    do{
                        PHPhotoLibrary.shared().performChanges({
                            let options = PHAssetResourceCreationOptions()
                            options.shouldMoveFile = true
                            let creationRequest = PHAssetCreationRequest.forAsset()
                            creationRequest.addResource(with: .video, fileURL: exportUrl!, options: options)
                        }, completionHandler: { success, error in
                            if !success {
                                print("Stitch couldn't save the movie to your photo library: \(String(describing: error))")
                            }
                        }
                        )
                    }
                    break
                case .unknown:
                    print("Status unknown")
                    break
                case .waiting:
                    print("Status waiting")
                    break
                case .exporting:
                    print("Status exporting")
                    break
                case .failed:
                    print("Status failed")
                    print(exportSession)
                    break
                case .cancelled:
                    print("Status cancelled")
                    break
                @unknown default:
                    print("Status default")
                    break
            }
        })
        
    }
}
