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
        let audioAsset = AVAsset(url: audio.assetURL!.absoluteURL)
        
        let audioVideoComposition = AVMutableComposition()
        
        let videoCompositionTrack = audioVideoComposition
            .addMutableTrack(withMediaType: .video, preferredTrackID: .init())!
        
        let audioCompositionTrack = audioVideoComposition
            .addMutableTrack(withMediaType: .audio, preferredTrackID: .init())!
        
        let videoAssetTrack = videoAsset.tracks(withMediaType: .video)[0]
        let audioAssetTrack = audioAsset.tracks(withMediaType: .audio).first
        let timeRange = CMTimeRange(start: .zero, duration: videoAsset.duration)
        
        do {
            
            try videoCompositionTrack.insertTimeRange(timeRange, of: videoAssetTrack, at: .zero)
            
            if let audioAssetTrack = audioAssetTrack {
                try audioCompositionTrack.insertTimeRange(timeRange, of: audioAssetTrack, at: .zero)
            }
        } catch {
            print("Failed to insert timeranges")
        }
        
        let exportUrl = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
            .appendingPathComponent("\(Date().timeIntervalSince1970)-video.mp4")

        let compatiblePresets = AVAssetExportSession.exportPresets(compatibleWith: audioVideoComposition)
        var preset: String = AVAssetExportPresetPassthrough
        if compatiblePresets.contains(AVAssetExportPreset1920x1080) { preset = AVAssetExportPreset1920x1080 }
        
        let exportSession = AVAssetExportSession(
            asset: audioVideoComposition,
            presetName: preset
        )
        
        exportSession?.outputFileType = .mp4
        exportSession?.outputURL = exportUrl
        exportSession!.timeRange = timeRange
        
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
                    print("Status completed")
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
                    print(exportSession?.error)
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
