//
//  ViewController.swift
//  CameraEngineExample
//
//  Created by Remi Robert on 16/09/16.
//  Copyright © 2016 Remi Robert. All rights reserved.
//

import UIKit
import CameraEngine

enum ModeCapture {
    case Photo
    case Video
}

class ViewController: UIViewController {
    
    private var cameraEngine = CameraEngine()
    private var mode: ModeCapture = .Photo
    
    @IBOutlet weak var buttonMode: UIButton!
    @IBOutlet weak var labelMode: UILabel!
    @IBOutlet weak var buttonTrigger: UIButton!
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        guard let layer = self.cameraEngine.previewLayer else {
            return
        }
        layer.frame = self.view.bounds
        self.view.layer.insertSublayer(layer, at: 0)
    }
    
    @IBAction func setModeCapture(_ sender: AnyObject) {
        let alertController = UIAlertController(title: "set mode capture", message: nil, preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: "Photo", style: .default, handler: {  _ in
            self.labelMode.text = "Photo"
            self.buttonTrigger.setTitle("take picture", for: .normal)
            self.mode = .Photo
        }))
        alertController.addAction(UIAlertAction(title: "Video", style: .default, handler: {  _ in
            self.labelMode.text = "Video"
            self.buttonTrigger.setTitle("start recording", for: .normal)
            self.mode = .Video
        }))
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }
    
    @IBAction func encoderSettingsPresset(_ sender: AnyObject) {
        let alertController = UIAlertController(title: "Encoder settings", message: nil, preferredStyle: .actionSheet)
        
        alertController.addAction(UIAlertAction(title: "Preset640x480", style: .default, handler: { _ in
            self.cameraEngine.videoEncoderPresset = .Preset640x480
        }))
        alertController.addAction(UIAlertAction(title: "Preset960x540", style: .default, handler: { _ in
            self.cameraEngine.videoEncoderPresset = .Preset960x540
        }))
        alertController.addAction(UIAlertAction(title: "Preset1280x720", style: .default, handler: { _ in
            self.cameraEngine.videoEncoderPresset = .Preset1280x720
        }))
        alertController.addAction(UIAlertAction(title: "Preset1920x1080", style: .default, handler: { _ in
            self.cameraEngine.videoEncoderPresset = .Preset1920x1080
        }))
        alertController.addAction(UIAlertAction(title: "Preset3840x2160", style: .default, handler: { _ in
            self.cameraEngine.videoEncoderPresset = .Preset3840x2160
        }))
        
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }
    
    @IBAction func setZoomCamera(_ sender: AnyObject) {
        let alertController = UIAlertController(title: "set zoom factor", message: nil, preferredStyle: .actionSheet)
        
        alertController.addAction(UIAlertAction(title: "X1", style: .default, handler: { _ in
            self.cameraEngine.cameraZoomFactor = 1
        }))
        alertController.addAction(UIAlertAction(title: "X2", style: .default, handler: { _ in
            self.cameraEngine.cameraZoomFactor = 2
        }))
        alertController.addAction(UIAlertAction(title: "X3", style: .default, handler: { _ in
            self.cameraEngine.cameraZoomFactor = 3
        }))
        alertController.addAction(UIAlertAction(title: "X4", style: .default, handler: { _ in
            self.cameraEngine.cameraZoomFactor = 4
        }))
        alertController.addAction(UIAlertAction(title: "X5", style: .default, handler: { _ in
            self.cameraEngine.cameraZoomFactor = 5
        }))
        
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }
    
    @IBAction func setFocus(_ sender: AnyObject) {
        let alertController = UIAlertController(title: "set focus settings", message: nil, preferredStyle: .actionSheet)
        
        alertController.addAction(UIAlertAction(title: "Locked", style: .default, handler: { _ in
            self.cameraEngine.cameraFocus = CameraEngineCameraFocus.locked
        }))
        alertController.addAction(UIAlertAction(title: "auto focus", style: .default, handler: { _ in
            self.cameraEngine.cameraFocus = CameraEngineCameraFocus.autoFocus
        }))
        alertController.addAction(UIAlertAction(title: "continious auto focus", style: .default, handler: { _ in
            self.cameraEngine.cameraFocus = CameraEngineCameraFocus.continuousAutoFocus
        }))
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }
    
    @IBAction func switchCamera(_ sender: AnyObject) {
        self.cameraEngine.switchCurrentDevice()
    }
    
    @IBAction func takePhoto(_ sender: AnyObject) {
        switch self.mode {
        case .Photo:
            self.cameraEngine.capturePhoto {[weak self] (image , error) -> (Void) in
                if let image = image {
                    CameraEngineFileManager.savePhoto(image, blockCompletion: { (success, error) -> (Void) in
                        guard let `self` = self else { return }
                        if success {
                            let alertController =  UIAlertController(title: "Success, image saved !", message: nil, preferredStyle: .alert)
                            alertController.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                            self.present(alertController, animated: true, completion: nil)
                        }
                    })
                }
            }
        case .Video:
            if !self.cameraEngine.isRecording {
                if let url = CameraEngineFileManager.temporaryPath("video.mp4") {
                    self.buttonTrigger.setTitle("stop recording", for: .normal)
                    self.cameraEngine.startRecordingVideo(url, blockCompletion: {[weak self] (url: URL?, error: NSError?) -> (Void) in
                        if let url = url {
                            DispatchQueue.main.async {
                                guard let `self` = self else { return }

                                self.buttonTrigger.setTitle("start recording", for: .normal)
                                CameraEngineFileManager.saveVideo(url, blockCompletion: { (success: Bool, error: Error?) -> (Void) in
                                    if success {
                                        let alertController =  UIAlertController(title: "Success, video saved !", message: nil, preferredStyle: .alert)
                                        alertController.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                                        self.present(alertController, animated: true, completion: nil)
                                    }
                                })
                            }
                        }
                    })
                }
            }
            else {
                self.cameraEngine.stopRecordingVideo()
            }
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        self.cameraEngine.rotationCamera = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.cameraEngine.startSession()
    }
}
