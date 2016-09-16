//
//  CameraEngineGifEncoder.swift
//  CameraEngine2
//
//  Created by Remi Robert on 11/02/16.
//  Copyright © 2016 Remi Robert. All rights reserved.
//

import UIKit
import ImageIO
import MobileCoreServices
import AVFoundation

public typealias blockCompletionGifEncoder = (_ success: Bool, _ url: URL?) -> (Void)

class CameraEngineGifEncoder {
    
    var blockCompletionGif: blockCompletionGifEncoder?
    
    func createGif(_ fileUrl: URL, frames: [UIImage], delayTime: Float, loopCount: Int = 0) {
        
        let fileProperties = [kCGImagePropertyGIFDictionary as String: [
            kCGImagePropertyGIFLoopCount as String: loopCount
            ]]
        
        let frameProperties = [kCGImagePropertyGIFDictionary as String: [
            kCGImagePropertyGIFDelayTime as String: delayTime
            ]]
        
        guard let destination = CGImageDestinationCreateWithURL(fileUrl as CFURL, kUTTypeGIF, frames.count, nil) else {
            self.blockCompletionGif?(false, nil)
            return
        }
        
        for currentFrame in frames {
            if let imageRef = currentFrame.cgImage {
                CGImageDestinationAddImage(destination, imageRef, frameProperties as CFDictionary)
            }
        }
        
        CGImageDestinationSetProperties(destination, fileProperties as CFDictionary)
        
        if !CGImageDestinationFinalize(destination) {
            print("error fail finalize")
            self.blockCompletionGif?(false, nil)
        }
        else {
            self.blockCompletionGif?(true, fileUrl)
        }
    }
}
