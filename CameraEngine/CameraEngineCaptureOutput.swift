//
//  CameraEngineCaptureOutput.swift
//  CameraEngine2
//
//  Created by Remi Robert on 24/12/15.
//  Copyright © 2015 Remi Robert. All rights reserved.
//

import UIKit
import AVFoundation

public typealias blockCompletionCapturePhoto = (image: UIImage?, error: NSError?) -> (Void)
public typealias blockCompletionCaptureVideo = (url: NSURL?, error: NSError?) -> (Void)
public typealias blockCompletionOutputBuffer = (sampleBuffer: CMSampleBuffer) -> (Void)
public typealias blockCompletionProgressRecording = (duration: Float64) -> (Void)

extension AVCaptureVideoOrientation {
    static func orientationFromUIDeviceOrientation(orientation: UIDeviceOrientation) -> AVCaptureVideoOrientation {
        switch orientation {
        case .Portrait: return .Portrait
        case .LandscapeLeft: return .LandscapeRight
        case .LandscapeRight: return .LandscapeLeft
        case .PortraitUpsideDown: return .PortraitUpsideDown
        default: return .Portrait
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
    
    func capturePhoto(blockCompletion: blockCompletionCapturePhoto) {
        guard let connectionVideo  = self.stillCameraOutput.connectionWithMediaType(AVMediaTypeVideo) else {
            blockCompletion(image: nil, error: nil)
            return
        }
        connectionVideo.videoOrientation = AVCaptureVideoOrientation.orientationFromUIDeviceOrientation(UIDevice.currentDevice().orientation)
        
        self.stillCameraOutput.captureStillImageAsynchronouslyFromConnection(connectionVideo) { (sampleBuffer: CMSampleBuffer!, err: NSError!) -> Void in
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
    
    func setPressetVideoEncoder(videoEncoderPresset: CameraEngineVideoEncoderEncoderSettings) {
        self.videoEncoder.presetSettingEncoder = videoEncoderPresset.configuration()
    }
    
    func startRecordVideo(blockCompletion: blockCompletionCaptureVideo, url: NSURL) {
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
    
    func configureCaptureOutput(session: AVCaptureSession, sessionQueue: dispatch_queue_t) {
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
    
    private func progressCurrentBuffer(sampleBuffer: CMSampleBuffer) {
        if let block = self.blockCompletionProgress where self.isRecording {
            block(duration: self.videoEncoder.progressCurrentBuffer(sampleBuffer))
        }
    }
    
    func captureOutput(captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, fromConnection connection: AVCaptureConnection!) {
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
    
    func captureOutput(captureOutput: AVCaptureFileOutput!, didStartRecordingToOutputFileAtURL fileURL: NSURL!, fromConnections connections: [AnyObject]!) {
        print("start recording ...")
    }
    
    func captureOutput(captureOutput: AVCaptureFileOutput!, didFinishRecordingToOutputFileAtURL outputFileURL: NSURL!, fromConnections connections: [AnyObject]!, error: NSError!) {
        print("end recording video ... \(outputFileURL)")
        print("error : \(error)")
        if let blockCompletionVideo = self.blockCompletionVideo {
            blockCompletionVideo(url: outputFileURL, error: error)
        }
    }
}
