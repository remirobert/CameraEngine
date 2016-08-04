//
//  CameraEngineCaptureOutput.swift
//  CameraEngine2
//
//  Created by Remi Robert on 24/12/15.
//  Copyright © 2015 Remi Robert. All rights reserved.
//

import UIKit
import AVFoundation

public typealias blockCompletionCapturePhoto = (image: UIImage?, error: Error?) -> (Void)
public typealias blockCompletionCapturePhotoBuffer = ((sampleBuffer: CMSampleBuffer?, error: Error?) -> Void)
public typealias blockCompletionCaptureVideo = (url: URL?, error: NSError?) -> (Void)
public typealias blockCompletionOutputBuffer = (sampleBuffer: CMSampleBuffer) -> (Void)
public typealias blockCompletionProgressRecording = (duration: Float64) -> (Void)

extension AVCaptureVideoOrientation {
    static func orientationFromUIDeviceOrientation(_ orientation: UIDeviceOrientation) -> AVCaptureVideoOrientation {
        switch orientation {
        case .portrait: return .portrait
        case .landscapeLeft: return .landscapeRight
        case .landscapeRight: return .landscapeLeft
        case .portraitUpsideDown: return .portraitUpsideDown
        default: return .portrait
        }
    }
}

class CameraEngineCaptureOutput: NSObject {
    
    private let stillCameraOutput = AVCaptureStillImageOutput()
    private let movieFileOutput = AVCaptureMovieFileOutput()
    private var captureVideoOutput = AVCaptureVideoDataOutput()
    private var captureAudioOutput = AVCaptureAudioDataOutput()
    private var blockCompletionVideo: blockCompletionCaptureVideo?
    
    private let videoEncoder = CameraEngineVideoEncoder()
    
    var isRecording = false
    var blockCompletionBuffer: blockCompletionOutputBuffer?
    var blockCompletionProgress: blockCompletionProgressRecording?
	
	func capturePhotoBuffer(_ blockCompletion: blockCompletionCapturePhotoBuffer) {
		guard let connectionVideo  = self.stillCameraOutput.connection(withMediaType: AVMediaTypeVideo) else {
			blockCompletion(sampleBuffer: nil, error: nil)
			return
		}
		connectionVideo.videoOrientation = AVCaptureVideoOrientation.orientationFromUIDeviceOrientation(UIDevice.current.orientation)
		self.stillCameraOutput.captureStillImageAsynchronously(from: connectionVideo, completionHandler: blockCompletion)
	}
	
    func capturePhoto(_ blockCompletion: blockCompletionCapturePhoto) {
        guard let connectionVideo  = self.stillCameraOutput.connection(withMediaType: AVMediaTypeVideo) else {
            blockCompletion(image: nil, error: nil)
            return
        }
        connectionVideo.videoOrientation = AVCaptureVideoOrientation.orientationFromUIDeviceOrientation(UIDevice.current.orientation)
        
        self.stillCameraOutput.captureStillImageAsynchronously(from: connectionVideo) { (sampleBuffer: CMSampleBuffer?, err: Error?) -> Void in
            if let err = err {
                blockCompletion(image: nil, error: err)
            }
            else {
                if let sampleBuffer = sampleBuffer, let dataImage = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(sampleBuffer) {
                    let image = UIImage(data: dataImage)
                    blockCompletion(image: image, error: nil)
                }
                else {
                    blockCompletion(image: nil, error: nil)
                }
            }
        }
    }
    
    func setPressetVideoEncoder(_ videoEncoderPresset: CameraEngineVideoEncoderEncoderSettings) {
        self.videoEncoder.presetSettingEncoder = videoEncoderPresset.configuration()
    }
    
    func startRecordVideo(_ blockCompletion: blockCompletionCaptureVideo, url: URL) {
        if self.isRecording == false {
            self.videoEncoder.startWriting(url)
            self.isRecording = true
        }
        else {
            self.isRecording = false
            self.stopRecordVideo()
        }
        self.blockCompletionVideo = blockCompletion
    }
    
    func stopRecordVideo() {
        self.isRecording = false
        self.videoEncoder.stopWriting(self.blockCompletionVideo)
    }
    
    func configureCaptureOutput(_ session: AVCaptureSession, sessionQueue: DispatchQueue) {
        if session.canAddOutput(self.captureVideoOutput) {
            session.addOutput(self.captureVideoOutput)
            self.captureVideoOutput.setSampleBufferDelegate(self, queue: sessionQueue)
        }
        if session.canAddOutput(self.captureAudioOutput) {
            session.addOutput(self.captureAudioOutput)
            self.captureAudioOutput.setSampleBufferDelegate(self, queue: sessionQueue)
        }
        if session.canAddOutput(self.stillCameraOutput) {
            session.addOutput(self.stillCameraOutput)
        }
        
    }
}

extension CameraEngineCaptureOutput: AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate {
    
    private func progressCurrentBuffer(_ sampleBuffer: CMSampleBuffer) {
        if let block = self.blockCompletionProgress, self.isRecording {
            block(duration: self.videoEncoder.progressCurrentBuffer(sampleBuffer))
        }
    }
    
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {
        self.progressCurrentBuffer(sampleBuffer)
        if let block = self.blockCompletionBuffer {
            block(sampleBuffer: sampleBuffer)
        }
        if CMSampleBufferDataIsReady(sampleBuffer) == false || self.isRecording == false {
            return
        }
        if captureOutput == self.captureVideoOutput {
            self.videoEncoder.appendBuffer(sampleBuffer, isVideo: true)
        }
        else if captureOutput == self.captureAudioOutput {
            self.videoEncoder.appendBuffer(sampleBuffer, isVideo: false)
        }
    }
}

extension CameraEngineCaptureOutput: AVCaptureFileOutputRecordingDelegate {
    
    func capture(_ captureOutput: AVCaptureFileOutput!, didStartRecordingToOutputFileAt fileURL: URL!, fromConnections connections: [AnyObject]!) {
        print("start recording ...")
    }
    
    func capture(_ captureOutput: AVCaptureFileOutput!, didFinishRecordingToOutputFileAt outputFileURL: URL!, fromConnections connections: [AnyObject]!, error: Error!) {
        print("end recording video ... \(outputFileURL)")
        print("error : \(error)")
        if let blockCompletionVideo = self.blockCompletionVideo {
            blockCompletionVideo(url: outputFileURL, error: error)
        }
    }
}
