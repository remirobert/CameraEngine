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

public typealias blockCompletionGifEncoder = (success: Bool, url: NSURL?) -> (Void)

class CameraEngineGifEncoder {
    
    var blockCompletionGif: blockCompletionGifEncoder?
    
    func createGif(fileUrl: NSURL, frames: [UIImage], delayTime: Float, loopCount: Int = 0) {
        
        let fileProperties = [kCGImagePropertyGIFDictionary as String: [
            kCGImagePropertyGIFLoopCount as String: loopCount
            ]]
        
        let frameProperties = [kCGImagePropertyGIFDictionary as String: [
            kCGImagePropertyGIFDelayTime as String: delayTime
            ]]
        
        guard let destination = CGImageDestinationCreateWithURL(fileUrl, kUTTypeGIF, frames.count, nil) else {
            self.blockCompletionGif?(success: false, url: nil)
            return
        }
        
        for currentFrame in frames {
            if let imageRef = currentFrame.CGImage {
                CGImageDestinationAddImage(destination, imageRef, frameProperties as CFDictionaryRef)
            }
        }
        
        CGImageDestinationSetProperties(destination, fileProperties as CFDictionaryRef)
        
        if !CGImageDestinationFinalize(destination) {
            print("error fail finalize")
            self.blockCompletionGif?(success: false, url: nil)
        }
        else {
            self.blockCompletionGif?(success: true, url: fileUrl)
        }
    }
}
