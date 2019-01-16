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
    case photo
    case high
    case medium
    case low
    case res352x288
    case res640x480
    case res1280x720
    case res1920x1080
    case res3840x2160
    case frame960x540
    case frame1280x720
    case inputPriority
    
    public func foundationPreset() -> String {
        switch self {
        case .photo: return AVCaptureSessionPresetPhoto
        case .high: return AVCaptureSessionPresetHigh
        case .medium: return AVCaptureSessionPresetMedium
        case .low: return AVCaptureSessionPresetLow
        case .res352x288: return AVCaptureSessionPreset352x288
        case .res640x480: return AVCaptureSessionPreset640x480
        case .res1280x720: return AVCaptureSessionPreset1280x720
        case .res1920x1080: return AVCaptureSessionPreset1920x1080
        case .res3840x2160:
            if #available(iOS 9.0, *) {
                return AVCaptureSessionPreset3840x2160
            }
            else {
                return AVCaptureSessionPresetPhoto
            }
        case .frame960x540: return AVCaptureSessionPresetiFrame960x540
        case .frame1280x720: return AVCaptureSessionPresetiFrame1280x720
        default: return AVCaptureSessionPresetPhoto
        }
    }
    
    public static func availablePresset() -> [CameraEngineSessionPreset] {
        return [
            .photo,
            .high,
            .medium,
            .low,
            .res352x288,
            .res640x480,
            .res1280x720,
            .res1920x1080,
            .res3840x2160,
            .frame960x540,
            .frame1280x720,
            .inputPriority
        ]
    }
}

let cameraEngineSessionQueueIdentifier = "com.cameraEngine.capturesession"

public class CameraEngine: NSObject {
    
    let session = AVCaptureSession()
    let cameraDevice = CameraEngineDevice()
    let cameraOutput = CameraEngineCaptureOutput()
    let cameraInput = CameraEngineDeviceInput()
    let cameraMetadata = CameraEngineMetadataOutput()
    let cameraGifEncoder = CameraEngineGifEncoder()
    let capturePhotoSettings = AVCapturePhotoSettings()
    var captureDeviceIntput: AVCaptureDeviceInput?
    
    var sessionQueue: DispatchQueue = DispatchQueue(label: cameraEngineSessionQueueIdentifier)
    
    private var _torchMode: AVCaptureTorchMode = .off
    public var torchMode: AVCaptureTorchMode! {
        get {
            return _torchMode
        }
        set {
            _torchMode = newValue
            configureTorch(newValue)
        }
    }
    
    private var _flashMode: AVCaptureFlashMode = .off
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
        layer?.videoGravity = AVLayerVideoGravityResizeAspectFill
        return layer
    }()
    
    private var _sessionPresset: CameraEngineSessionPreset = .inputPriority
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
    
    private var _cameraFocus: CameraEngineCameraFocus = .continuousAutoFocus
    public var cameraFocus: CameraEngineCameraFocus! {
        get {
            return self._cameraFocus
        }
        set {
            self.cameraDevice.changeCameraFocusMode(newValue)
            self._cameraFocus = newValue
        }
    }
    
    private var _metadataDetection: CameraEngineCaptureOutputDetection = .none
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
    
    private var _cameraZoomFactor: CGFloat = 1.0
    public var cameraZoomFactor: CGFloat! {
        get {
            if let `captureDevice` = captureDevice {
                _cameraZoomFactor = captureDevice.videoZoomFactor
            }
            
            return self._cameraZoomFactor
        }
        set {
            let newZoomFactor = self.cameraDevice.changeCurrentZoomFactor(newValue)
            if newZoomFactor > 0 {
                self._cameraZoomFactor = newZoomFactor
            }
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
                return captureDevice.isAdjustingFocus
            }
            
            return false
        }
    }
    
    public var isAdjustingExposure: Bool {
        get {
            if let `captureDevice` = captureDevice {
                return captureDevice.isAdjustingExposure
            }
            
            return false
        }
    }
    
    public var isAdjustingWhiteBalance: Bool {
        get {
            if let `captureDevice` = captureDevice {
                return captureDevice.isAdjustingWhiteBalance
            }
            
            return false
        }
    }
    
    public static var sharedInstance: CameraEngine = CameraEngine()
    
    public override init() {
        super.init()
        self.setupSession()
    }
    
    deinit {
        self.stopSession()
        NotificationCenter.default.removeObserver(self)
    }
    
    private func setupSession() {
        self.sessionQueue.async { () -> Void in
            self.configureInputDevice()
            self.configureOutputDevice()
            self.handleDeviceOrientation()
        }
    }
    
    public class func askAuthorization() -> AVAuthorizationStatus {
        return AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeVideo)
    }
    
    //MARK: Session management
    
    public func startSession() {
        let session = self.session
        
        self.sessionQueue.async { () -> Void in
            session.startRunning()
        }
    }
    
    public func stopSession() {
        let session = self.session
        
        self.sessionQueue.async { () -> Void in
            session.stopRunning()
        }
    }
    
    //MARK: Device management
    
    private func handleDeviceOrientation() {
        if self.rotationCamera {
			if (!UIDevice.current.isGeneratingDeviceOrientationNotifications) {
				UIDevice.current.beginGeneratingDeviceOrientationNotifications()
			}
            NotificationCenter.default.addObserver(forName: NSNotification.Name.UIDeviceOrientationDidChange, object: nil, queue: OperationQueue.main) { [weak self] (_) -> Void in
                guard let `self` = self else { return }
                self.previewLayer.connection.videoOrientation = AVCaptureVideoOrientation.orientationFromUIDeviceOrientation(UIDevice.current.orientation)
            }
        }
        else {
			if (UIDevice.current.isGeneratingDeviceOrientationNotifications) {
				UIDevice.current.endGeneratingDeviceOrientationNotifications()
			}
            NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
        }
    }
    
    public func changeCurrentDevice(_ position: AVCaptureDevicePosition) {
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
    
    private func configureFlash(_ mode: AVCaptureFlashMode) {
        if let currentDevice = self.cameraDevice.currentDevice, currentDevice.isFlashAvailable && self.capturePhotoSettings.flashMode != mode {
            self.capturePhotoSettings.flashMode = mode
        }
//        if let currentDevice = self.cameraDevice.currentDevice, currentDevice.isFlashAvailable && currentDevice.flashMode != mode {
//            do {
//                try currentDevice.lockForConfiguration()
//                currentDevice.flashMode = mode
//                currentDevice.unlockForConfiguration()
//            }
//            catch {
//                fatalError("[CameraEngine] error lock configuration device")
//            }
//        }
    }
    
    private func configureTorch(_ mode: AVCaptureTorchMode) {
        if let currentDevice = self.cameraDevice.currentDevice, currentDevice.isTorchAvailable && currentDevice.torchMode != mode {
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
            self.changeCurrentDevice((self.cameraDevice.currentPosition == .back) ? .front : .back)
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
        catch CameraEngineDeviceInputErrorType.unableToAddCamera {
            fatalError("[CameraEngine] unable to add camera as InputDevice")
        }
        catch CameraEngineDeviceInputErrorType.unableToAddMic {
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
    
    public func focus(_ atPoint: CGPoint) {
        if let currentDevice = self.cameraDevice.currentDevice {
			let performFocus = currentDevice.isFocusModeSupported(.autoFocus) && currentDevice.isFocusPointOfInterestSupported
			let performExposure = currentDevice.isExposureModeSupported(.autoExpose) && currentDevice.isExposurePointOfInterestSupported
            if performFocus || performExposure {
                let focusPoint = self.previewLayer.captureDevicePointOfInterest(for: atPoint)
                do {
                    try currentDevice.lockForConfiguration()
					
					if performFocus {
						currentDevice.focusPointOfInterest = CGPoint(x: focusPoint.x, y: focusPoint.y)
						if currentDevice.focusMode == AVCaptureFocusMode.locked {
							currentDevice.focusMode = AVCaptureFocusMode.autoFocus
						} else {
							currentDevice.focusMode = AVCaptureFocusMode.continuousAutoFocus
						}
					}
					
                    if performExposure {
						currentDevice.exposurePointOfInterest = CGPoint(x: focusPoint.x, y: focusPoint.y)
                        if currentDevice.exposureMode == AVCaptureExposureMode.locked {
                            currentDevice.exposureMode = AVCaptureExposureMode.autoExpose
                        } else {
                            currentDevice.exposureMode = AVCaptureExposureMode.continuousAutoExposure;
                        }
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
    
    public func capturePhoto(_ blockCompletion: @escaping blockCompletionCapturePhoto) {
        self.cameraOutput.capturePhoto(settings: self.capturePhotoSettings, blockCompletion)
    }
	
	public func capturePhotoBuffer(_ blockCompletion: @escaping blockCompletionCapturePhotoBuffer) {
        self.cameraOutput.capturePhotoBuffer(settings: self.capturePhotoSettings, blockCompletion)
	}
    
    public func startRecordingVideo(_ url: URL, blockCompletion: @escaping blockCompletionCaptureVideo) {
        if self.isRecording == false {
            self.sessionQueue.async(execute: {[weak self] () -> Void in
                guard let `self` = self else { return }
                self.cameraOutput.startRecordVideo(blockCompletion, url: url)
            })
        }
    }
    
    public func stopRecordingVideo() {
        if self.isRecording {
            self.sessionQueue.async(execute: {[weak self] () -> Void in
                guard let `self` = self else { return }
                self.cameraOutput.stopRecordVideo()
            })
        }
    }
    
    public func createGif(_ fileUrl: URL, frames: [UIImage], delayTime: Float, loopCount: Int = 0, completionGif: @escaping blockCompletionGifEncoder) {
        self.cameraGifEncoder.blockCompletionGif = completionGif
        self.cameraGifEncoder.createGif(fileUrl, frames: frames, delayTime: delayTime, loopCount: loopCount)
    }
}
