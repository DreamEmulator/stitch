//
//  ViewController.swift
//  stitch
//
//  Created by Sebastiaan Hols on 03/10/2020.
//

import UIKit
import MediaPlayer

class ViewController: UIViewController, MPMediaPickerControllerDelegate {

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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }


}

