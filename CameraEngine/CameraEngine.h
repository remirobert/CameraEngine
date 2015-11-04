//
//  CameraEngine.h
//  CameraEngine
//
//  Created by Remi Robert on 19/08/15.
//  Copyright (c) 2015 Remi Robert. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <Foundation/Foundation.h>
#import <AssetsLibrary/AssetsLibrary.h>

# define MAIN_CAPTURE_QUEUE                "com.remirobert.cameraengine.capture"
# define CAPTURE_METADA_TAOUTPUT_QUEUE     "com.remirobert.metadata.queue"

@interface CameraEngine : NSObject

+ (instancetype)shareInstance;
+ (CameraEngine *)engine;
- (void)startup;
- (void)shutdown;
- (AVCaptureVideoPreviewLayer *)getPreviewLayer;

- (void)capturePhoto:(void (^)(UIImage *image))block;
- (void)startCapture:(void (^)(NSURL *videoPath))block;
- (void)pauseCapture;
- (void)resumeCapture;
- (void)stopCapture;

+ (void)startup;
+ (void)shutdown;
+ (AVCaptureVideoPreviewLayer *)getPreviewLayer;
+ (void)capturePhoto:(void (^)(UIImage *image))block;
+ (void)startCapture:(void (^)(NSURL *videoPath))block;
+ (void)pauseCapture;
+ (void)resumeCapture;
+ (void)stopCapture;

@property (nonatomic, assign) BOOL flash;
@property (nonatomic, assign) BOOL torch;
@property (nonatomic, assign) AVCaptureDevicePosition devicePosition;
@property (nonatomic, readwrite) BOOL isCapturing;
@property (nonatomic, readwrite) BOOL isPaused;
@property (nonatomic, assign) CMTime maximumCaptureDuration;
@property (nonatomic, assign) BOOL autSaveVideo;
@property (nonatomic, strong) void (^readQRCodeCompletion)(NSString *content);
@property (nonatomic, strong) void (^progressRecordingCompletion)(Float64 currentTime, CMSampleBufferRef sampleBuffer);

@end
