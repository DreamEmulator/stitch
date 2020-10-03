//
//  ViewController.swift
//  stitch
//
//  Created by Sebastiaan Hols on 03/10/2020.
//

import UIKit
import MediaPlayer
import AVFoundation

class ViewController: UIViewController, MPMediaPickerControllerDelegate {

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
            musicPlayer.play();
            playPauseButton.setImage(UIImage(systemName:"pause.fill"), for: .normal)
        } else {
            musicPlayer.pause();
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
    let videoOutput = AVCaptureVideoDataOutput();
    
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
        captureSession.addOutput(videoOutput)
        captureSession.commitConfiguration()
        
        previewView.videoPreviewLayer.session = captureSession
        previewView.contentMode = .scaleAspectFill
        
        previewView.frame = CGRect(x: videoPreview.bounds.width / 2,y: 0,width: 400, height: 400)
        videoPreview.addSubview(previewView)
        captureSession.startRunning();
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        startVideoSession()
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
