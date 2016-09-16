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

public typealias blockCompletionSaveMedia = (_ success: Bool, _ error: Error?) -> (Void)

public class CameraEngineFileManager {
    
    private class func removeItemAtPath(_ path: String) {
        let filemanager = FileManager.default
        if filemanager.fileExists(atPath: path) {
            do {
                try filemanager.removeItem(atPath: path)
            }
            catch {
                print("[Camera engine] Error remove path :\(path)")
            }
        }
    }
    
    private class func appendPath(_ rootPath: String, pathFile: String) -> String {
        let destinationPath = rootPath + "/\(pathFile)"
        self.removeItemAtPath(destinationPath)
        return destinationPath
    }
    
    public class func savePhoto(_ image: UIImage, blockCompletion: blockCompletionSaveMedia?) {
        PHPhotoLibrary.shared().performChanges({ () -> Void in
            PHAssetChangeRequest.creationRequestForAsset(from: image)
            }, completionHandler: blockCompletion)
    }
    
    public class func saveVideo(_ url: URL, blockCompletion: blockCompletionSaveMedia?) {
        PHPhotoLibrary.shared().performChanges({ () -> Void in
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
            }, completionHandler: blockCompletion)
    }
    
    public class func documentPath() -> String? {
        if let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).last {
            return path
        }
        return nil
    }
    
    public class func temporaryPath() -> String {
        return NSTemporaryDirectory()
    }
    
    public class func documentPath(_ file: String) -> URL? {
        if let path = self.documentPath() {
            return URL(fileURLWithPath: self.appendPath(path, pathFile: file))
        }
        return nil
    }
    
    public class func temporaryPath(_ file: String) -> URL? {
        return URL(fileURLWithPath: self.appendPath(self.temporaryPath(), pathFile: file))
    }
}
