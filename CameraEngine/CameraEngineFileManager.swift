//
//  CameraEngineFileManager.swift
//  CameraEngine2
//
//  Created by Remi Robert on 11/02/16.
//  Copyright © 2016 Remi Robert. All rights reserved.
//

import UIKit
import Photos
import ImageIO

public typealias blockCompletionSaveMedia = (success: Bool, error: NSError?) -> (Void)

public class CameraEngineFileManager {
    
    private class func removeItemAtPath(path: String) {
        let filemanager = NSFileManager.defaultManager()
        if filemanager.fileExistsAtPath(path) {
            do {
                try filemanager.removeItemAtPath(path)
            }
            catch {
                print("[Camera engine] Error remove path :\(path)")
            }
        }
    }
    
    private class func appendPath(rootPath: String, pathFile: String) -> String {
        let destinationPath = rootPath.stringByAppendingString("/\(pathFile)")
        self.removeItemAtPath(destinationPath)
        return destinationPath
    }
    
    public class func savePhoto(image: UIImage, blockCompletion: blockCompletionSaveMedia?) {
        PHPhotoLibrary.sharedPhotoLibrary().performChanges({ () -> Void in
            PHAssetChangeRequest.creationRequestForAssetFromImage(image)
            }, completionHandler: blockCompletion)
    }
    
    public class func saveVideo(url: NSURL, blockCompletion: blockCompletionSaveMedia?) {
        PHPhotoLibrary.sharedPhotoLibrary().performChanges({ () -> Void in
            PHAssetChangeRequest.creationRequestForAssetFromVideoAtFileURL(url)
            }, completionHandler: blockCompletion)
    }
    
    public class func documentPath() -> String? {
        if let path = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true).last {
            return path
        }
        return nil
    }
    
    public class func temporaryPath() -> String {
        return NSTemporaryDirectory()
    }
    
    public class func documentPath(file: String) -> NSURL? {
        if let path = self.documentPath() {
            return NSURL(fileURLWithPath: self.appendPath(path, pathFile: file))
        }
        return nil
    }
    
    public class func temporaryPath(file: String) -> NSURL? {
        return NSURL(fileURLWithPath: self.appendPath(self.temporaryPath(), pathFile: file))
    }
}
