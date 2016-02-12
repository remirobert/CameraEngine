//
//  ViewController.swift
//  CameraEngine2
//
//  Created by Remi Robert on 24/12/15.
//  Copyright © 2015 Remi Robert. All rights reserved.
//

import UIKit
import FCFileManager
import AVFoundation
import CameraEngine

enum ModeCapture {
    case Photo
    case Video
    case GIF
}

class ViewController: UIViewController {

    let cameraEngine = CameraEngine()
    
    @IBOutlet weak var buttonSwitch: UIButton!
    @IBOutlet weak var buttonTrigger: UIButton!
    @IBOutlet weak var buttonTorch: UIButton!
    @IBOutlet weak var buttonFlash: UIButton!
    @IBOutlet weak var buttonSessionPresset: UIButton!
    @IBOutlet weak var buttonModeCapture: UIButton!
    @IBOutlet weak var labelModeCapture: UILabel!
    @IBOutlet weak var labelDuration: UILabel!
    
    private var currentModeCapture: ModeCapture = .Photo
    private var frames = Array<UIImage>()
    
    @IBAction func changeModeCapture(sender: AnyObject) {
        let alertController = UIAlertController(title: "Mode capture", message: "Change the capture mode photo / video", preferredStyle: UIAlertControllerStyle.ActionSheet)

        alertController.addAction(UIAlertAction(title: "Photo", style: UIAlertActionStyle.Default, handler: { (_) -> Void in
            self.labelModeCapture.text = "Photo"
            self.labelDuration.hidden = true
            self.currentModeCapture = .Photo
        }))
        
        alertController.addAction(UIAlertAction(title: "Video", style: UIAlertActionStyle.Default, handler: { (_) -> Void in
            self.labelModeCapture.text = "Video"
            self.currentModeCapture = .Video
        }))
        
        alertController.addAction(UIAlertAction(title: "GIF", style: UIAlertActionStyle.Default, handler: { (_) -> Void in
            self.labelModeCapture.text = "GIF"
            self.currentModeCapture = .GIF
            self.frames.removeAll()
            self.labelDuration.text = "5"
        }))

        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    @IBAction func changeDetectionMode(sender: AnyObject) {
        let detectionCompatible = self.cameraEngine.compatibleDetectionMetadata()
        
        let alertController = UIAlertController(title: "Metadata Detection", message: "Change the metadata detection type", preferredStyle: UIAlertControllerStyle.ActionSheet)
        
        for currentDetectionMode in detectionCompatible {
            alertController.addAction(UIAlertAction(title: currentDetectionMode.description(), style: UIAlertActionStyle.Default, handler: { (_) -> Void in
                self.cameraEngine.metadataDetection = currentDetectionMode
            }))
        }
        alertController.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil))
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    @IBAction func changeFocusCamera(sender: AnyObject) {
        let focusCompatible = self.cameraEngine.compatibleCameraFocus()
        
        let alertController = UIAlertController(title: "Camera focus", message: "Change the focus camera mode, compatible with yours device", preferredStyle: UIAlertControllerStyle.ActionSheet)
        
        for currentFocusMode in focusCompatible {
            alertController.addAction(UIAlertAction(title: currentFocusMode.description(), style: UIAlertActionStyle.Default, handler: { (_) -> Void in
                self.cameraEngine.cameraFocus = currentFocusMode
            }))
        }
        alertController.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil))
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    private func changePressetCameraPhoto() {
        let pressetCompatible = self.cameraEngine.compatibleSessionPresset()
        
        let alertController = UIAlertController(title: "Session presset", message: "Change the presset of the session, compatible with yours device", preferredStyle: UIAlertControllerStyle.ActionSheet)
        
        for currentPresset in pressetCompatible {
            alertController.addAction(UIAlertAction(title: currentPresset.foundationPreset(), style: UIAlertActionStyle.Default, handler: { (_) -> Void in
                self.cameraEngine.sessionPresset = currentPresset
            }))
        }
        alertController.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil))
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    private func changePressetVideoEncoder() {
        let pressetCompatible = self.cameraEngine.compatibleVideoEncoderPresset()
        
        let alertController = UIAlertController(title: "Video encoder presset", message: "Change the video encoder presset, to change the resolution of the ouput video.", preferredStyle: UIAlertControllerStyle.ActionSheet)
        
        for currentPresset in pressetCompatible {
            alertController.addAction(UIAlertAction(title: currentPresset.description(), style: UIAlertActionStyle.Default, handler: { (_) -> Void in
                self.cameraEngine.videoEncoderPresset = currentPresset
            }))
        }
        alertController.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil))
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    @IBAction func changePressetSession(sender: AnyObject) {
        switch self.currentModeCapture {
        case .Photo, .GIF: self.changePressetCameraPhoto()
        case .Video: self.changePressetVideoEncoder()
        }
    }
    
    @IBAction func changeTorchMode(sender: AnyObject) {
        let alertController = UIAlertController(title: "Torch mode", message: "Change the torch mode", preferredStyle: UIAlertControllerStyle.ActionSheet)

        alertController.addAction(UIAlertAction(title: "On", style: UIAlertActionStyle.Default, handler: { (_) -> Void in
            self.cameraEngine.torchMode = .On
        }))
        alertController.addAction(UIAlertAction(title: "Off", style: UIAlertActionStyle.Default, handler: { (_) -> Void in
            self.cameraEngine.torchMode = .Off
        }))
        alertController.addAction(UIAlertAction(title: "Auto", style: UIAlertActionStyle.Default, handler: { (_) -> Void in
            self.cameraEngine.torchMode = .Auto
        }))
        alertController.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil))
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    @IBAction func changeFlashMode(sender: AnyObject) {
        let alertController = UIAlertController(title: "Flash mode", message: "Change the flash mode", preferredStyle: UIAlertControllerStyle.ActionSheet)

        alertController.addAction(UIAlertAction(title: "On", style: UIAlertActionStyle.Default, handler: { (_) -> Void in
            self.cameraEngine.flashMode = .On
        }))
        alertController.addAction(UIAlertAction(title: "Off", style: UIAlertActionStyle.Default, handler: { (_) -> Void in
            self.cameraEngine.flashMode = .Off
        }))
        alertController.addAction(UIAlertAction(title: "Auto", style: UIAlertActionStyle.Default, handler: { (_) -> Void in
            self.cameraEngine.flashMode = .Auto
        }))
        alertController.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil))
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    private func captureVideo() {
        print("record video")
        if self.cameraEngine.isRecording == false {
            guard let url = CameraEngineFileManager.documentPath("video.mp4") else {
                return
            }
            
            self.cameraEngine.startRecordingVideo(url, blockCompletion: { (url, error) -> (Void) in
                print("url movie : \(url)")
                
                let controller = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("previewController")
                
                CameraEngineFileManager.saveVideo(url!, blockCompletion: { (success, error) -> (Void) in
                    print("error saving video : \(error)")
                })
                
                (controller as! PreviewViewController).media = Media.Video(url: url!)
                self.presentViewController(controller, animated: true, completion: nil)
            })
        }
        else {
            self.cameraEngine.stopRecordingVideo()
        }
    }
    
    private func capturePhoto() {
        self.cameraEngine.capturePhoto { (image: UIImage?, error: NSError?) -> (Void) in
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                if let image = image {
                    
                    if self.currentModeCapture == .GIF {
                        self.frames.append(image)
                        if (self.frames.count == 5) {
                            guard let url = CameraEngineFileManager.documentPath("animated.gif") else {
                                return
                            }
                            self.cameraEngine.createGif(url, frames: self.frames, delayTime: 0.1, completionGif: { (success, url) -> (Void) in
                                if let url = url {
                                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                        let controller = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("previewController")
                                        (controller as! PreviewViewController).media = Media.GIF(url: url)
                                        self.presentViewController(controller, animated: true, completion: nil)
                                    })
                                }
                            })
                            return
                        }
                        self.labelModeCapture.hidden = false
                        self.labelModeCapture.text = "\(5 - self.frames.count)"
                    }
                    else {
                        let controller = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("previewController")
                        
                        CameraEngineFileManager.savePhoto(image, blockCompletion: { (success, error) -> (Void) in
                            print("error save image : \(error)")
                        })
                        
                        (controller as! PreviewViewController).media = Media.Photo(image: image)
                        self.presentViewController(controller, animated: true, completion: nil)
                    }
                }
            })
        }
    }
    
    @IBAction func capturePhoto(sender: AnyObject) {
        switch self.currentModeCapture {
        case .Photo, .GIF: self.capturePhoto()
        case .Video: self.captureVideo()
        }
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if let touch = event!.allTouches()!.first {
            let position = touch.locationInView(self.view)
            self.cameraEngine.focus(position)
        }
    }
    
    @IBAction func switchCamera(sender: AnyObject) {
        self.cameraEngine.switchCurrentDevice()
    }
    
    override func viewDidLayoutSubviews() {
        let layer = self.cameraEngine.previewLayer
        
        layer.frame = self.view.bounds
        self.view.layer.insertSublayer(layer, atIndex: 0)
        self.view.layer.masksToBounds = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.blackColor()
        
        self.labelDuration.hidden = true
        
        self.cameraEngine.startSession()
        
        self.cameraEngine.blockCompletionProgress = { progress in
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.labelDuration.hidden = false
                self.labelDuration.text = "\(progress)"
            })
            print("progress duration : \(progress)")
        }
        
        self.cameraEngine.blockCompletionFaceDetection = { faceObject in
            print("face Object")
            
            (faceObject as AVMetadataObject).bounds
        }
        
        self.cameraEngine.blockCompletionCodeDetection = { codeObject in
            print("code object value : \(codeObject.stringValue)")
        }
    }
}
