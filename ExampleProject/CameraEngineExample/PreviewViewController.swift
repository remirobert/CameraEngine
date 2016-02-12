//
//  PreviewViewController.swift
//  CameraEngine2
//
//  Created by Remi Robert on 25/12/15.
//  Copyright © 2015 Remi Robert. All rights reserved.
//

import UIKit
import PBJVideoPlayer
import FLAnimatedImage

enum Media {
    case Photo(image: UIImage)
    case Video(url: NSURL)
    case GIF(url: NSURL)
}

class PreviewViewController: UIViewController {

    @IBOutlet weak var imageView: FLAnimatedImageView!
    @IBOutlet weak var buttonClose: UIButton!
    @IBOutlet weak var flashButton: UIButton!
    @IBOutlet weak var torchButton: UIButton!
    var media: Media!
    var playerController: PBJVideoPlayerController!
    
    @IBAction func closePreview(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    private func playVideo(url: NSURL) {
        print("display video for url : \(url.absoluteString)")
        UISaveVideoAtPathToSavedPhotosAlbum(url.absoluteString, nil, nil, nil)
        self.playerController = PBJVideoPlayerController()
        self.playerController.view.frame = self.view.bounds
        self.playerController.videoPath = url.absoluteString
        
        self.playerController.view.backgroundColor = UIColor.orangeColor()
        
        self.addChildViewController(self.playerController)
        self.view.insertSubview(self.playerController.view, atIndex: 0)
        self.playerController.didMoveToParentViewController(self)
    }
    
    private func displayAnimatedGIF(url: NSURL) {
        let dataImage = NSData(contentsOfURL: url)
        let animatedImage = FLAnimatedImage(animatedGIFData: dataImage)
        
        self.imageView.animatedImage = animatedImage
    }
    
    override func viewWillAppear(animated: Bool) {
        switch self.media! {
        case .Photo(let image): self.imageView.image = image
        case .Video(let url): self.playVideo(url)
        case .GIF(let url): self.displayAnimatedGIF(url)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.blackColor()
    }
}
