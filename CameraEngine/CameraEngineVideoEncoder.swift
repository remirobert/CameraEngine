//
//  CameraEngineVideoEncoder.swift
//  CameraEngine2
//
//  Created by Remi Robert on 11/02/16.
//  Copyright © 2016 Remi Robert. All rights reserved.
//

import UIKit
import AVFoundation

public enum CameraEngineVideoEncoderEncoderSettings: String {
    case Preset640x480
    case Preset960x540
    case Preset1280x720
    case Preset1920x1080
    case Preset3840x2160
    case Unknow
    
    private func avFoundationPresetString() -> String? {
        switch self {
        case .Preset640x480: return AVOutputSettingsPreset640x480
        case .Preset960x540: return AVOutputSettingsPreset960x540
        case .Preset1280x720: return AVOutputSettingsPreset1280x720
        case .Preset1920x1080: return AVOutputSettingsPreset1920x1080
        case .Preset3840x2160:
            if #available(iOS 9.0, *) {
                return AVOutputSettingsPreset3840x2160
            }
            else {
                return nil
            }
        case .Unknow: return nil
        }
    }
    
    func configuration() -> AVOutputSettingsAssistant? {
        if let presetSetting = self.avFoundationPresetString() {
            return AVOutputSettingsAssistant(preset: presetSetting)
        }
        return nil
    }
    
    public static func availableFocus() -> [CameraEngineVideoEncoderEncoderSettings] {
        return AVOutputSettingsAssistant.availableOutputSettingsPresets().map {
            if #available(iOS 9.0, *) {
                switch $0 {
                case AVOutputSettingsPreset640x480: return .Preset640x480
                case AVOutputSettingsPreset960x540: return .Preset960x540
                case AVOutputSettingsPreset1280x720: return .Preset1280x720
                case AVOutputSettingsPreset1920x1080: return .Preset1920x1080
                case AVOutputSettingsPreset3840x2160: return .Preset3840x2160
                default: return .Unknow
                }
            }
            else {
                switch $0 {
                case AVOutputSettingsPreset640x480: return .Preset640x480
                case AVOutputSettingsPreset960x540: return .Preset960x540
                case AVOutputSettingsPreset1280x720: return .Preset1280x720
                case AVOutputSettingsPreset1920x1080: return .Preset1920x1080
                default: return .Unknow
                }
            }
        }
    }
    
    public func description() -> String {
        switch self {
        case .Preset640x480: return "Preset 640x480"
        case .Preset960x540: return "Preset 960x540"
        case .Preset1280x720: return "Preset 1280x720"
        case .Preset1920x1080: return "Preset 1920x1080"
        case .Preset3840x2160: return "Preset 3840x2160"
        case .Unknow: return "Preset Unknow"
        }
    }
}

extension UIDevice {
    static func orientationTransformation() -> CGFloat {
        switch UIDevice.currentDevice().orientation {
        case .Portrait: return CGFloat(M_PI / 2)
        case .PortraitUpsideDown: return CGFloat(M_PI / 4)
        case .LandscapeRight: return CGFloat(M_PI)
        case .LandscapeLeft: return CGFloat(M_PI * 2)
        default: return 0
        }
    }
}

class CameraEngineVideoEncoder {
    
    private var assetWriter: AVAssetWriter!
    private var videoInputWriter: AVAssetWriterInput!
    private var audioInputWriter: AVAssetWriterInput!
    private var startTime: CMTime!
    
    lazy var presetSettingEncoder: AVOutputSettingsAssistant? = {
        return CameraEngineVideoEncoderEncoderSettings.Preset1920x1080.configuration()
    }()
    
    private func initVideoEncoder(url: NSURL) {
        guard let presetSettingEncoder = self.presetSettingEncoder else {
            print("[Camera engine] presetSettingEncoder = nil")
            return
        }

        do {
            self.assetWriter = try AVAssetWriter(URL: url, fileType: AVFileTypeMPEG4)
        }
        catch {
            fatalError("error init assetWriter")
        }
        
        let videoOutputSettings = presetSettingEncoder.videoSettings
        let audioOutputSettings = presetSettingEncoder.audioSettings
        
        guard self.assetWriter.canApplyOutputSettings(videoOutputSettings, forMediaType: AVMediaTypeVideo) else {
            fatalError("Negative [VIDEO] : Can't apply the Output settings...")
        }
        guard self.assetWriter.canApplyOutputSettings(audioOutputSettings, forMediaType: AVMediaTypeAudio) else {
            fatalError("Negative [AUDIO] : Can't apply the Output settings...")
        }

        self.videoInputWriter = AVAssetWriterInput(mediaType: AVMediaTypeVideo, outputSettings: videoOutputSettings)
        self.videoInputWriter.expectsMediaDataInRealTime = true
        self.videoInputWriter.transform = CGAffineTransformMakeRotation(UIDevice.orientationTransformation())
        
        self.audioInputWriter = AVAssetWriterInput(mediaType: AVMediaTypeAudio, outputSettings: audioOutputSettings)
        self.audioInputWriter.expectsMediaDataInRealTime = true
        
        if self.assetWriter.canAddInput(self.videoInputWriter) {
            self.assetWriter.addInput(self.videoInputWriter)
        }
        if self.assetWriter.canAddInput(self.audioInputWriter) {
            self.assetWriter.addInput(self.audioInputWriter)
        }
    }
    
    func startWriting(url: NSURL) {
        self.startTime = CMClockGetTime(CMClockGetHostTimeClock())
        self.initVideoEncoder(url)
    }
    
    func stopWriting(blockCompletion: blockCompletionCaptureVideo?) {
        self.videoInputWriter.markAsFinished()
        self.audioInputWriter.markAsFinished()
        
        self.assetWriter.finishWritingWithCompletionHandler { () -> Void in
            if let blockCompletion = blockCompletion {
                blockCompletion(url: self.assetWriter.outputURL, error: nil)
            }
        }
    }
    
    func appendBuffer(sampleBuffer: CMSampleBuffer!, isVideo: Bool) {
	
	if CMSampleBufferDataIsReady(sampleBuffer) {
            if self.assetWriter.status == AVAssetWriterStatus.Unknown {
                let startTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
                self.assetWriter.startWriting()
                self.assetWriter.startSessionAtSourceTime(startTime) 
	    }
            if isVideo {
                if self.videoInputWriter.readyForMoreMediaData {
                    self.videoInputWriter.appendSampleBuffer(sampleBuffer)
                }
            }
            else {
                if self.audioInputWriter.readyForMoreMediaData {
                    self.audioInputWriter.appendSampleBuffer(sampleBuffer)
                }
            }
	}
    }
    
    func progressCurrentBuffer(sampleBuffer: CMSampleBuffer) -> Float64 {
        let currentTimestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        let currentTime = CMTimeGetSeconds(CMTimeSubtract(currentTimestamp, self.startTime))
        return currentTime
    }
}
