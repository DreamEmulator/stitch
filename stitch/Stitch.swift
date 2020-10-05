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
    let orientation: UIDeviceOrientation
    
    init(video: URL, audio: MPMediaItem, duration: CMTime, orientation: UIDeviceOrientation){
        self.video = video
        self.audio = audio
        self.duration = duration
        self.orientation = orientation
    }
    
    func getVideoTransform() -> CGAffineTransform {
        switch orientation {
            case .portrait:
                return CGAffineTransform(rotationAngle: 90.degreesToRadians)
            case .portraitUpsideDown:
                return CGAffineTransform(rotationAngle: 180)
            case .landscapeLeft:
                return CGAffineTransform(rotationAngle: 0.degreesToRadians)
            case .landscapeRight:
                return CGAffineTransform(rotationAngle: 180.degreesToRadians)
            default:
                return CGAffineTransform(rotationAngle: 90.degreesToRadians)
        }
    }
    
    func stitch (){
    
//        Assets
        let videoAsset = AVAsset(url: video)
        guard let audioUrl = audio.assetURL else {
            return
        }
        let audioAsset = AVAsset(url: audioUrl.absoluteURL)
        
//        The composition
        let audioVideoComposition = AVMutableComposition()
        
//        The tracks of the composition
        let videoCompositionTrack = audioVideoComposition
            .addMutableTrack(withMediaType: .video, preferredTrackID: .init())!
        let audioCompositionTrack = audioVideoComposition
            .addMutableTrack(withMediaType: .audio, preferredTrackID: .init())!
        
//        Putting th assets onto the travks
        let videoAssetTrack = videoAsset.tracks(withMediaType: .video)[0]
        let audioAssetTrack = audioAsset.tracks(withMediaType: .audio).first
        let timeRange = CMTimeRange(start: .zero, duration: videoAsset.duration)
        
        do {
            try videoCompositionTrack.insertTimeRange(timeRange, of: videoAssetTrack, at: .zero)
            
//            Rotate the video according to the orienation
            print(orientation.rawValue)
            videoCompositionTrack.preferredTransform = getVideoTransform()
            
            if let audioAssetTrack = audioAssetTrack {
                try audioCompositionTrack.insertTimeRange(timeRange, of: audioAssetTrack, at: .zero)
            }
            
        } catch {
            print("Failed to insert timeranges")
        }
    
        
//        Create file url
        let outputFileName = NSUUID().uuidString
        let outputFilePath = (NSTemporaryDirectory() as NSString).appendingPathComponent((outputFileName as NSString).appendingPathExtension("mp4")!)
        let exportUrl = URL(fileURLWithPath: outputFilePath)
        
//     MARK:   Setup export session
        let exportSession = AVAssetExportSession(
            asset: audioVideoComposition,
            presetName: AVAssetExportPresetPassthrough
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
                            creationRequest.addResource(with: .video, fileURL: exportUrl, options: options)
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
                    print(exportSession?.error as Any)
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

extension BinaryInteger {
    var degreesToRadians: CGFloat { CGFloat(self) * .pi / 180 }
}

extension FloatingPoint {
    var degreesToRadians: Self { self * .pi / 180 }
    var radiansToDegrees: Self { self * 180 / .pi }
}
