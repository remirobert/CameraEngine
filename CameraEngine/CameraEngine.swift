//
//  CameraEngine.swift
//  CameraEngine2
//
//  Created by Remi Robert on 24/12/15.
//  Copyright © 2015 Remi Robert. All rights reserved.
//

import UIKit
import AVFoundation

public enum CameraEngineSessionPreset {
    case Photo
    case High
    case Medium
    case Low
    case Res352x288
    case Res640x480
    case Res1280x720
    case Res1920x1080
    case Res3840x2160
    case Frame960x540
    case Frame1280x720
    case InputPriority
    
    public func foundationPreset() -> String {
        switch self {
        case .Photo: return AVCaptureSessionPresetPhoto
        case .High: return AVCaptureSessionPresetHigh
        case .Medium: return AVCaptureSessionPresetMedium
        case .Low: return AVCaptureSessionPresetLow
        case .Res352x288: return AVCaptureSessionPreset352x288
        case .Res640x480: return AVCaptureSessionPreset640x480
        case .Res1280x720: return AVCaptureSessionPreset1280x720
        case .Res1920x1080: return AVCaptureSessionPreset1920x1080
        case .Res3840x2160:
            if #available(iOS 9.0, *) {
                return AVCaptureSessionPreset3840x2160
            }
            else {
                return AVCaptureSessionPresetPhoto
            }
        case .Frame960x540: return AVCaptureSessionPresetiFrame960x540
        case .Frame1280x720: return AVCaptureSessionPresetiFrame1280x720
        default: return AVCaptureSessionPresetPhoto
        }
    }
    
    public static func availablePresset() -> [CameraEngineSessionPreset] {
        return [
            .Photo,
            .High,
            .Medium,
            .Low,
            .Res352x288,
            .Res640x480,
            .Res1280x720,
            .Res1920x1080,
            .Res3840x2160,
            .Frame960x540,
            .Frame1280x720,
            .InputPriority
        ]
    }
}

let cameraEngineSessionQueueIdentifier = "com.cameraEngine.capturesession"

public class CameraEngine: NSObject {
    
    private let session = AVCaptureSession()
    private let cameraDevice = CameraEngineDevice()
    private let cameraOutput = CameraEngineCaptureOutput()
    private let cameraInput = CameraEngineDeviceInput()
    private let cameraMetadata = CameraEngineMetadataOutput()
    private let cameraGifEncoder = CameraEngineGifEncoder()
    private var captureDeviceIntput: AVCaptureDeviceInput?
    
    private var sessionQueue: dispatch_queue_t! = {
        dispatch_queue_create(cameraEngineSessionQueueIdentifier, DISPATCH_QUEUE_SERIAL)
    }()
    
    private var _torchMode: AVCaptureTorchMode = .Off
    public var torchMode: AVCaptureTorchMode! {
        get {
            return _torchMode
        }
        set {
            _torchMode = newValue
            configureTorch(newValue)
        }
    }
    
    private var _flashMode: AVCaptureFlashMode = .Off
    public var flashMode: AVCaptureFlashMode! {
        get {
            return _flashMode
        }
        set {
            _flashMode = newValue
            configureFlash(newValue)
        }
    }
    
    public lazy var previewLayer: AVCaptureVideoPreviewLayer! = {
        let layer =  AVCaptureVideoPreviewLayer(session: self.session)
        layer.videoGravity = AVLayerVideoGravityResizeAspectFill
        return layer
    }()
    
    private var _sessionPresset: CameraEngineSessionPreset = .InputPriority
    public var sessionPresset: CameraEngineSessionPreset! {
        get {
            return self._sessionPresset
        }
        set {
            if self.session.canSetSessionPreset(newValue.foundationPreset()) {
                self._sessionPresset = newValue
                self.session.sessionPreset = self._sessionPresset.foundationPreset()
            }
            else {
                fatalError("[CameraEngine] session presset : [\(newValue.foundationPreset())] uncompatible with the current device")
            }
        }
    }
    
    private var _cameraFocus: CameraEngineCameraFocus = .ContinuousAutoFocus
    public var cameraFocus: CameraEngineCameraFocus! {
        get {
            return self._cameraFocus
        }
        set {
            self.cameraDevice.changeCameraFocusMode(newValue)
            self._cameraFocus = newValue
        }
    }
    
    private var _metadataDetection: CameraEngineCaptureOutputDetection = .None
    public var metadataDetection: CameraEngineCaptureOutputDetection! {
        get {
            return self._metadataDetection
        }
        set {
            self._metadataDetection = newValue
            self.cameraMetadata.configureMetadataOutput(self.session, sessionQueue: self.sessionQueue, metadataType: self._metadataDetection)
        }
    }
    
    private var _videoEncoderPresset: CameraEngineVideoEncoderEncoderSettings!
    public var videoEncoderPresset: CameraEngineVideoEncoderEncoderSettings! {
        set {
            self._videoEncoderPresset = newValue
            self.cameraOutput.setPressetVideoEncoder(self._videoEncoderPresset)
        }
        get {
            return self._videoEncoderPresset
        }
    }
    
    public var blockCompletionBuffer: blockCompletionOutputBuffer? {
        didSet {
            self.cameraOutput.blockCompletionBuffer = self.blockCompletionBuffer
        }
    }
    
    public var blockCompletionProgress: blockCompletionProgressRecording? {
        didSet {
            self.cameraOutput.blockCompletionProgress = self.blockCompletionProgress
        }
    }
    
    public var blockCompletionFaceDetection: blockCompletionDetectionFace? {
        didSet {
            self.cameraMetadata.blockCompletionFaceDetection = self.blockCompletionFaceDetection
        }
    }
    
    public var blockCompletionCodeDetection: blockCompletionDetectionCode? {
        didSet {
            self.cameraMetadata.blockCompletionCodeDetection = self.blockCompletionCodeDetection
        }
    }
    
    private var _rotationCamera = false
    public var rotationCamera: Bool {
        get {
            return _rotationCamera
        }
        set {
            _rotationCamera = newValue
            self.handleDeviceOrientation()
        }
    }
    
    public var captureDevice: AVCaptureDevice? {
        get {
            return cameraDevice.currentDevice
        }
    }
    
    public var isRecording: Bool {
        get {
            return self.cameraOutput.isRecording
        }
    }
    
    public var isAdjustingFocus: Bool {
        get {
            if let `captureDevice` = captureDevice {
                return captureDevice.adjustingFocus
            }
            
            return false
        }
    }
    
    public var isAdjustingExposure: Bool {
        get {
            if let `captureDevice` = captureDevice {
                return captureDevice.adjustingExposure
            }
            
            return false
        }
    }
    
    public var isAdjustingWhiteBalance: Bool {
        get {
            if let `captureDevice` = captureDevice {
                return captureDevice.adjustingWhiteBalance
            }
            
            return false
        }
    }
    
    public class var sharedInstance: CameraEngine {
        struct Static {
            static var onceToken: dispatch_once_t = 0
            static var instance: CameraEngine? = nil
        }
        dispatch_once(&Static.onceToken) {
            Static.instance = CameraEngine()
        }
        return Static.instance!
    }
    
    public override init() {
        super.init()
        self.setupSession()
    }
    
    deinit {
        self.stopSession()
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    private func setupSession() {
        dispatch_async(self.sessionQueue) { () -> Void in
            self.configureInputDevice()
            self.configureOutputDevice()
            self.handleDeviceOrientation()
        }
    }
    
    public class func askAuthorization() -> AVAuthorizationStatus {
        return AVCaptureDevice.authorizationStatusForMediaType(AVMediaTypeVideo)
    }
    
    //MARK: Session management
    
    public func startSession() {
        let session = self.session
        
        dispatch_async(self.sessionQueue) { () -> Void in
            session.startRunning()
        }
    }
    
    public func stopSession() {
        let session = self.session
        
        dispatch_async(self.sessionQueue) { () -> Void in
            session.stopRunning()
        }
    }
    
    //MARK: Device management
    
    private func handleDeviceOrientation() {
        if self.rotationCamera {
            UIDevice.currentDevice().beginGeneratingDeviceOrientationNotifications()
            NSNotificationCenter.defaultCenter().addObserverForName(UIDeviceOrientationDidChangeNotification, object: nil, queue: NSOperationQueue.mainQueue()) { (_) -> Void in
                self.previewLayer.connection.videoOrientation = AVCaptureVideoOrientation.orientationFromUIDeviceOrientation(UIDevice.currentDevice().orientation)
            }
        }
        else {
            UIDevice.currentDevice().endGeneratingDeviceOrientationNotifications()
            NSNotificationCenter.defaultCenter().removeObserver(self, name: UIDeviceOrientationDidChangeNotification, object: nil)
        }
    }
    
    public func changeCurrentDevice(position: AVCaptureDevicePosition) {
        self.cameraDevice.changeCurrentDevice(position)
        self.configureInputDevice()
    }
    
    public func compatibleCameraFocus() -> [CameraEngineCameraFocus] {
        if let currentDevice = self.cameraDevice.currentDevice {
            return CameraEngineCameraFocus.availableFocus().filter {
                return currentDevice.isFocusModeSupported($0.foundationFocus())
            }
        }
        else {
            return []
        }
    }
    
    public func compatibleSessionPresset() -> [CameraEngineSessionPreset] {
        return CameraEngineSessionPreset.availablePresset().filter {
            return self.session.canSetSessionPreset($0.foundationPreset())
        }
    }
    
    public func compatibleVideoEncoderPresset() -> [CameraEngineVideoEncoderEncoderSettings] {
        return CameraEngineVideoEncoderEncoderSettings.availableFocus()
    }
    
    public func compatibleDetectionMetadata() -> [CameraEngineCaptureOutputDetection] {
        return CameraEngineCaptureOutputDetection.availableDetection()
    }
    
    private func configureFlash(mode: AVCaptureFlashMode) {
        if let currentDevice = self.cameraDevice.currentDevice where currentDevice.flashAvailable && currentDevice.flashMode != mode {
            do {
                try currentDevice.lockForConfiguration()
                currentDevice.flashMode = mode
                currentDevice.unlockForConfiguration()
            }
            catch {
                fatalError("[CameraEngine] error lock configuration device")
            }
        }
    }
    
    private func configureTorch(mode: AVCaptureTorchMode) {
        if let currentDevice = self.cameraDevice.currentDevice where currentDevice.torchAvailable && currentDevice.torchMode != mode {
            do {
                try currentDevice.lockForConfiguration()
                currentDevice.torchMode = mode
                currentDevice.unlockForConfiguration()
            }
            catch {
                fatalError("[CameraEngine] error lock configuration device")
            }
        }
    }
    
    public func switchCurrentDevice() {
        if self.isRecording == false {
            self.changeCurrentDevice((self.cameraDevice.currentPosition == .Back) ? .Front : .Back)
        }
    }
    
    public var currentDevice: AVCaptureDevicePosition {
        get {
            return self.cameraDevice.currentPosition
        }
        set {
            self.changeCurrentDevice(newValue)
        }
    }
    
    //MARK: Device I/O configuration
    
    private func configureInputDevice() {
        do {
            if let currentDevice = self.cameraDevice.currentDevice {
                try self.cameraInput.configureInputCamera(self.session, device: currentDevice)
            }
            if let micDevice = self.cameraDevice.micCameraDevice {
                try self.cameraInput.configureInputMic(self.session, device: micDevice)
            }
        }
        catch CameraEngineDeviceInputErrorType.UnableToAddCamera {
            fatalError("[CameraEngine] unable to add camera as InputDevice")
        }
        catch CameraEngineDeviceInputErrorType.UnableToAddMic {
            fatalError("[CameraEngine] unable to add mic as InputDevice")
        }
        catch {
            fatalError("[CameraEngine] error initInputDevice")
        }
    }
    
    private func configureOutputDevice() {
        self.cameraOutput.configureCaptureOutput(self.session, sessionQueue: self.sessionQueue)
        self.cameraMetadata.previewLayer = self.previewLayer
        self.cameraMetadata.configureMetadataOutput(self.session, sessionQueue: self.sessionQueue, metadataType: self.metadataDetection)
    }
}

//MARK: Extension Device

public extension CameraEngine {
    
    public func focus(atPoint: CGPoint) {
        if let currentDevice = self.cameraDevice.currentDevice {
            if currentDevice.isFocusModeSupported(AVCaptureFocusMode.AutoFocus) && currentDevice.focusPointOfInterestSupported {
                let focusPoint = self.previewLayer.captureDevicePointOfInterestForPoint(atPoint)
                do {
                    try currentDevice.lockForConfiguration()
                    currentDevice.focusPointOfInterest = CGPoint(x: focusPoint.x, y: focusPoint.y)
                    currentDevice.focusMode = AVCaptureFocusMode.AutoFocus
                    
                    if currentDevice.isExposureModeSupported(AVCaptureExposureMode.AutoExpose) {
                        currentDevice.exposureMode = AVCaptureExposureMode.AutoExpose
                    }
                    currentDevice.unlockForConfiguration()
                }
                catch {
                    fatalError("[CameraEngine] error lock configuration device")
                }
            }
        }
    }
}

//MARK: Extension capture

public extension CameraEngine {
    
    public func capturePhoto(blockCompletion: blockCompletionCapturePhoto) {
        self.cameraOutput.capturePhoto(blockCompletion)
    }
    
    public func startRecordingVideo(url: NSURL, blockCompletion: blockCompletionCaptureVideo) {
        if self.isRecording == false {
            dispatch_async(self.sessionQueue, { () -> Void in
                self.cameraOutput.startRecordVideo(blockCompletion, url: url)
            })
        }
    }
    
    public func stopRecordingVideo() {
        if self.isRecording {
            dispatch_async(self.sessionQueue, { () -> Void in
                self.cameraOutput.stopRecordVideo()
            })
        }
    }
    
    public func createGif(fileUrl: NSURL, frames: [UIImage], delayTime: Float, loopCount: Int = 0, completionGif: blockCompletionGifEncoder) {
        self.cameraGifEncoder.blockCompletionGif = completionGif
        self.cameraGifEncoder.createGif(fileUrl, frames: frames, delayTime: delayTime, loopCount: loopCount)
    }
}
