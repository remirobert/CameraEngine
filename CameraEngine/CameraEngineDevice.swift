//
//  CameraEngineDevice.swift
//  CameraEngine2
//
//  Created by Remi Robert on 24/12/15.
//  Copyright © 2015 Remi Robert. All rights reserved.
//

import UIKit
import AVFoundation

public enum CameraEngineCameraFocus {
    case Locked
    case AutoFocus
    case ContinuousAutoFocus
    
    func foundationFocus() -> AVCaptureFocusMode {
        switch self {
        case .Locked: return AVCaptureFocusMode.Locked
        case .AutoFocus: return AVCaptureFocusMode.AutoFocus
        case .ContinuousAutoFocus: return AVCaptureFocusMode.ContinuousAutoFocus
        }
    }
    
    public func description() -> String {
        switch self {
        case .Locked: return "Locked"
        case .AutoFocus: return "AutoFocus"
        case .ContinuousAutoFocus: return "ContinuousAutoFocus"
        }
    }
    
    public static func availableFocus() -> [CameraEngineCameraFocus] {
        return [
            .Locked,
            .AutoFocus,
            .ContinuousAutoFocus
        ]
    }
}

class CameraEngineDevice {

    private var backCameraDevice: AVCaptureDevice!
    private var frontCameraDevice: AVCaptureDevice!
    var micCameraDevice: AVCaptureDevice!
    var currentDevice: AVCaptureDevice?
    var currentPosition: AVCaptureDevicePosition = .Unspecified
    
    func changeCameraFocusMode(focusMode: CameraEngineCameraFocus) {
        if let currentDevice = self.currentDevice {
            do {
                try currentDevice.lockForConfiguration()
                if currentDevice.isFocusModeSupported(focusMode.foundationFocus()) {
                    currentDevice.focusMode = focusMode.foundationFocus()
                }
                currentDevice.unlockForConfiguration()
            }
            catch {
                fatalError("[CameraEngine] error, impossible to lock configuration device")
            }
        }
    }
    
    func changeCurrentDevice(position: AVCaptureDevicePosition) {
        self.currentPosition = position
        switch position {
        case .Back: self.currentDevice = self.backCameraDevice
        case .Front: self.currentDevice = self.frontCameraDevice
        case .Unspecified: self.currentDevice = nil
        }
    }
    
    private func configureDeviceCamera() {
        let availableCameraDevices = AVCaptureDevice.devicesWithMediaType(AVMediaTypeVideo)
        for device in availableCameraDevices as! [AVCaptureDevice] {
            if device.position == .Back {
                self.backCameraDevice = device
            }
            else if device.position == .Front {
                self.frontCameraDevice = device
            }
        }        
    }
    
    private func configureDeviceMic() {
        self.micCameraDevice = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeAudio)
    }
    
    init() {
        self.configureDeviceCamera()
        self.configureDeviceMic()
        self.changeCurrentDevice(.Back)
    }
}
