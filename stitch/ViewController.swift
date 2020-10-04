//
//  ViewController.swift
//  stitch
//
//  Created by Sebastiaan Hols on 03/10/2020.
//

import UIKit
import MediaPlayer
import AVFoundation
import Photos

class ViewController: UIViewController, MPMediaPickerControllerDelegate, AVCaptureFileOutputRecordingDelegate {
    

//    MARK: Music
    let musicPlayer = MPMusicPlayerController.systemMusicPlayer
    var track: MPMediaItem?;

    @IBOutlet weak var trackInfo: UIView!
    @IBOutlet weak var trackName: UILabel!
    @IBOutlet weak var playPauseButton: UIButton!
    
    @IBAction func pickTrack(_ sender: UIButton) {
        let controller = MPMediaPickerController(mediaTypes: .music)
        controller.allowsPickingMultipleItems = false
        controller.popoverPresentationController?.sourceView = sender
        controller.delegate = self
        present(controller, animated: true)
    }
    
    @IBAction func playTrackPressed(_ sender: UIButton) {
        if(track != nil) {
            playTrack()
        }
    }
    
    func playTrack (){
        if (musicPlayer.playbackState != .playing){
            musicPlayer.play()
            startRecordingVideo()
            playPauseButton.setImage(UIImage(systemName:"pause.fill"), for: .normal)
        } else {
            musicPlayer.pause()
            stopRecordingVideo()
            playPauseButton.setImage(UIImage(systemName:"play.fill"), for: .normal)
        }
    }
    
    func mediaPicker(_ mediaPicker: MPMediaPickerController,
                     didPickMediaItems mediaItemCollection: MPMediaItemCollection) {
        mediaPicker.dismiss(animated: true)
        track = mediaItemCollection.items[0]
        trackName.text = mediaItemCollection.items[0].title
        musicPlayer.setQueue(with: mediaItemCollection)
        trackInfo.isHidden = false;
    }
    
    func mediaPickerDidCancel(_ mediaPicker: MPMediaPickerController) {
        mediaPicker.dismiss(animated: true)
    }
    
//    MARK: Video
    
    @IBOutlet weak var videoPreview: UIView!
    let captureSession = AVCaptureSession();
    let videoOutput = AVCaptureMovieFileOutput();
    
    
//    MARK: Recording delegat emethods
//    didFinishRecordingTo
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        print("Did stop recording to \(outputFileURL)")
        PHPhotoLibrary.shared().performChanges({
            let options = PHAssetResourceCreationOptions()
            options.shouldMoveFile = true
            let creationRequest = PHAssetCreationRequest.forAsset()
            creationRequest.addResource(with: .video, fileURL: outputFileURL, options: options)
        }, completionHandler: { success, error in
                if !success {
                    print("AVCam couldn't save the movie to your photo library: \(String(describing: error))")
                }
            }
        )
    }
//    didStartRecordingTo
    func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
        print("Did start recording to \(fileURL)")
    }
    
    let previewView = PreviewView();
    
    func startVideoSession(){
        
        captureSession.beginConfiguration()
        
//        Select camera
        let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                  for: .video, position: .back)
        
//        Set input
        guard
            let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice!),
            captureSession.canAddInput(videoDeviceInput)
        else { print("Failed getting video device"); return }
        captureSession.addInput(videoDeviceInput)
        
//        Set output
        guard captureSession.canAddOutput(videoOutput) else { print("Can not add output"); return }
        captureSession.sessionPreset = .medium
        if let connection = videoOutput.connection(with: .video) {
            if connection.isVideoStabilizationSupported {
                connection.preferredVideoStabilizationMode = .auto
            }
        }
        captureSession.addOutput(videoOutput)
        captureSession.commitConfiguration()
        
        previewView.videoPreviewLayer.session = captureSession
        previewView.contentMode = .scaleAspectFill
        
        videoPreview.addSubview(previewView)
        captureSession.startRunning();
    }
    
    func startRecordingVideo(){
        print("Started recording")
        
        let videoOutputConnection = videoOutput.connection(with: .video)
        let availableVideoCodecTypes = videoOutput.availableVideoCodecTypes
        if availableVideoCodecTypes.contains(.hevc) {
            videoOutput.setOutputSettings([AVVideoCodecKey: AVVideoCodecType.hevc], for: videoOutputConnection!)
        }
        
        // Start recording video to a temporary file.
        let outputFileName = NSUUID().uuidString
        let outputFilePath = (NSTemporaryDirectory() as NSString).appendingPathComponent((outputFileName as NSString).appendingPathExtension("mov")!)
        videoOutput.startRecording(to: URL(fileURLWithPath: outputFilePath), recordingDelegate: self)
    }
    
    func stopRecordingVideo(){
        print("Stopped recording")
        videoOutput.stopRecording()
    }
    
    func correctVideoOrientation(){
        if (UIDevice.current.orientation.isLandscape){
            videoPreview.setTransformRotation(toDegrees: -90)
        } else {
            videoPreview.setTransformRotation(toDegrees: 0)
        }
    }
    
//    MARK: Start
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        startVideoSession()
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
//        correctVideoOrientation()
    }

    override func viewDidLayoutSubviews(){
        super.viewDidLayoutSubviews()
        previewView.frame = videoPreview.bounds
    }
    
    override func didRotate(from fromInterfaceOrientation: UIInterfaceOrientation) {
//        correctVideoOrientation()
    }


}

class PreviewView: UIView {
    override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }
    
    /// Convenience wrapper to get layer as its statically known type.
    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        return layer as! AVCaptureVideoPreviewLayer
    }
    
}

extension UIView {
    func setTransformRotation(toDegrees angleInDegrees: CGFloat) {
        let angleInRadians = angleInDegrees / 180.0 * CGFloat.pi
        self.transform = CGAffineTransform(rotationAngle: angleInRadians)
    }
}
