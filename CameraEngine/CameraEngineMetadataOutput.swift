//
//  CameraEngineMetadataOutput.swift
//  CameraEngine2
//
//  Created by Remi Robert on 03/02/16.
//  Copyright © 2016 Remi Robert. All rights reserved.
//

import UIKit
import AVFoundation

public typealias blockCompletionDetectionFace = (faceObject: AVMetadataFaceObject) -> (Void)
public typealias blockCompletionDetectionCode = (codeObject: AVMetadataMachineReadableCodeObject) -> (Void)

public enum CameraEngineCaptureOutputDetection {
    case Face
    case QRCode
    case BareCode
    case None
    
    func foundationCaptureOutputDetection() -> [AnyObject] {
        switch self {
        case .Face: return [AVMetadataObjectTypeFace]
        case .QRCode: return [AVMetadataObjectTypeQRCode]
        case .BareCode: return [
            AVMetadataObjectTypeUPCECode,
            AVMetadataObjectTypeCode39Code,
            AVMetadataObjectTypeCode39Mod43Code,
            AVMetadataObjectTypeEAN13Code,
            AVMetadataObjectTypeEAN8Code,
            AVMetadataObjectTypeCode93Code,
            AVMetadataObjectTypeCode128Code,
            AVMetadataObjectTypePDF417Code,
            AVMetadataObjectTypeQRCode,
            AVMetadataObjectTypeAztecCode
            ]
        case .None: return []
        }
    }
    
    public static func availableDetection() -> [CameraEngineCaptureOutputDetection] {
        return [
            .Face,
            .QRCode,
            .BareCode,
            .None
        ]
    }
    
    public func description() -> String {
        switch self {
        case .Face: return "Face detection"
        case .QRCode: return "QRCode detection"
        case .BareCode: return "BareCode detection"
        case .None: return "No detection"
        }
    }
}

class CameraEngineMetadataOutput: NSObject, AVCaptureMetadataOutputObjectsDelegate {
    
    private var metadataOutput:AVCaptureMetadataOutput?
    private var currentMetadataOutput: CameraEngineCaptureOutputDetection = .None
    var previewLayer: AVCaptureVideoPreviewLayer?
    
    var blockCompletionFaceDetection: blockCompletionDetectionFace?
    var blockCompletionCodeDetection: blockCompletionDetectionCode?
    
    var shapeLayer = CAShapeLayer()
    var layer2 = CALayer()
    
    func configureMetadataOutput(session: AVCaptureSession, sessionQueue: dispatch_queue_t, metadataType: CameraEngineCaptureOutputDetection) {
        if self.metadataOutput == nil {
            self.metadataOutput = AVCaptureMetadataOutput()
            self.metadataOutput?.setMetadataObjectsDelegate(self, queue: sessionQueue)
            if session.canAddOutput(self.metadataOutput) {
                session.addOutput(self.metadataOutput)
            }
        }
        self.metadataOutput!.metadataObjectTypes = metadataType.foundationCaptureOutputDetection()
        self.currentMetadataOutput = metadataType
    }
    
    func captureOutput(captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [AnyObject]!, fromConnection connection: AVCaptureConnection!) {
        guard let previewLayer = self.previewLayer else {
            return
        }
        
        for metadataObject in metadataObjects as! [AVMetadataObject] {
            switch metadataObject.type {
            case AVMetadataObjectTypeFace:
                if let block = self.blockCompletionFaceDetection where self.currentMetadataOutput == .Face {
                    let transformedMetadataObject = previewLayer.transformedMetadataObjectForMetadataObject(metadataObject)
                    block(faceObject: transformedMetadataObject as! AVMetadataFaceObject)
                }
            case AVMetadataObjectTypeQRCode:
                if let block = self.blockCompletionCodeDetection where self.currentMetadataOutput == .QRCode {
                    let transformedMetadataObject = previewLayer.transformedMetadataObjectForMetadataObject(metadataObject)
                    block(codeObject: transformedMetadataObject as! AVMetadataMachineReadableCodeObject)
                }
            case AVMetadataObjectTypeUPCECode, AVMetadataObjectTypeCode39Code, AVMetadataObjectTypeCode39Mod43Code, AVMetadataObjectTypeEAN13Code, AVMetadataObjectTypeEAN8Code, AVMetadataObjectTypeCode93Code, AVMetadataObjectTypeCode128Code, AVMetadataObjectTypePDF417Code,AVMetadataObjectTypeQRCode, AVMetadataObjectTypeAztecCode:
                if let block = self.blockCompletionCodeDetection where self.currentMetadataOutput == .BareCode {
                    let transformedMetadataObject = previewLayer.transformedMetadataObjectForMetadataObject(metadataObject)
                    block(codeObject: transformedMetadataObject as! AVMetadataMachineReadableCodeObject)
                }
            default:break
            }
        }
    }
}
