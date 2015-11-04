//
//  CameraEngine.m
//  CameraEngine
//
//  Created by Remi Robert on 19/08/15.
//  Copyright (c) 2015 Remi Robert. All rights reserved.
//

#import "CameraEngine.h"
#import "VideoEncoder.h"

@interface CameraEngine  () <AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate, AVCaptureMetadataOutputObjectsDelegate>
{
    AVCaptureSession *_session;
    AVCaptureVideoPreviewLayer *_preview;
    dispatch_queue_t _captureQueue;
    AVCaptureConnection *_audioConnection;
    AVCaptureConnection *_videoConnection;
    AVCaptureStillImageOutput *_stillImageOutput;
    
    AVCaptureDevice *backCamera;
    AVCaptureDevice *frontCamera;
    AVCaptureDeviceInput *currentInput;
    
    VideoEncoder* _encoder;
    BOOL _isCapturing;
    BOOL _isPaused;
    BOOL _discont;
    int _currentFile;
    CMTime _timeOffset;
    CMTime _lastVideo;
    CMTime _lastAudio;
    CMTime _startTime;
    CMTime _startTimestamp;
    CMTime _pauseTimestamp;
    NSDate *_pauseDate;
    NSTimeInterval _amountPauseTime;
    
    int _cx;
    int _cy;
    int _channels;
    Float64 _samplerate;

    void (^completionBlock)(NSURL *videoPath);
}
@end

@implementation CameraEngine

@synthesize isCapturing = _isCapturing;
@synthesize isPaused = _isPaused;

+ (instancetype)shareInstance {
    static CameraEngine *engine;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        engine = [[CameraEngine alloc] init];
    });
    return engine;
}

+ (CameraEngine *)engine {
    return [CameraEngine shareInstance];
}

- (instancetype)init {
    self = [super init];
    
    if (self) {
        self.maximumCaptureDuration = kCMTimeInvalid;
    }
    return self;
}

- (void)startup {
    if (_session == nil) {
        self.isCapturing = NO;
        self.isPaused = NO;
        _currentFile = 0;
        _discont = NO;
        
        _session = [[AVCaptureSession alloc] init];
        
        
        backCamera = [self captureDeviceForPosition:AVCaptureDevicePositionBack];
        frontCamera = [self captureDeviceForPosition:AVCaptureDevicePositionFront];

        currentInput = [AVCaptureDeviceInput deviceInputWithDevice:backCamera error:nil];
        
        if ([_session canAddInput:currentInput]) {
            [_session addInput:currentInput];
        }
        
        AVCaptureDevice* mic = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
        AVCaptureDeviceInput* micinput = [AVCaptureDeviceInput deviceInputWithDevice:mic error:nil];
        [_session addInput:micinput];
        
        _captureQueue = dispatch_queue_create(MAIN_CAPTURE_QUEUE, DISPATCH_QUEUE_SERIAL);
        AVCaptureVideoDataOutput* videoout = [[AVCaptureVideoDataOutput alloc] init];
        [videoout setSampleBufferDelegate:self queue:_captureQueue];
        NSDictionary* setcapSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                        [NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange], kCVPixelBufferPixelFormatTypeKey,
                                        nil];
        videoout.videoSettings = setcapSettings;
        if ([_session canAddOutput:videoout]) {
            [_session addOutput:videoout];
        }
        
        _stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
        NSDictionary *outputSettings = [[NSDictionary alloc] initWithObjectsAndKeys:
                                        AVVideoCodecJPEG, AVVideoCodecKey, nil];
        [_stillImageOutput setOutputSettings:outputSettings];
        if ([_session canAddOutput:_stillImageOutput]) {
            [_session addOutput:_stillImageOutput];
        }
        
        AVCaptureMetadataOutput *captureMetadataOutput = [[AVCaptureMetadataOutput alloc] init];
        [_session addOutput:captureMetadataOutput];
        
        dispatch_queue_t dispatchQueue;
        dispatchQueue = dispatch_queue_create(CAPTURE_METADA_TAOUTPUT_QUEUE, NULL);
        [captureMetadataOutput setMetadataObjectsDelegate:self queue:dispatchQueue];
        [captureMetadataOutput setMetadataObjectTypes:@[AVMetadataObjectTypeQRCode]];
        
        _videoConnection = [videoout connectionWithMediaType:AVMediaTypeVideo];
        if ([_videoConnection isVideoOrientationSupported]) {
            AVCaptureVideoOrientation orientation = AVCaptureVideoOrientationPortrait;
            [_videoConnection setVideoOrientation:orientation];
        }
        
        NSDictionary* actual = videoout.videoSettings;
        _cy = [[actual objectForKey:@"Height"] floatValue];
        _cx = [[actual objectForKey:@"Width"] floatValue];
        
        AVCaptureAudioDataOutput* audioout = [[AVCaptureAudioDataOutput alloc] init];
        [audioout setSampleBufferDelegate:self queue:_captureQueue];
        [_session addOutput:audioout];
        _audioConnection = [audioout connectionWithMediaType:AVMediaTypeAudio];

        [_session startRunning];
        
        _preview = [AVCaptureVideoPreviewLayer layerWithSession:_session];
        _preview.connection.videoOrientation = AVCaptureVideoOrientationPortrait;
        _preview.videoGravity = AVLayerVideoGravityResizeAspectFill;
    }
}

- (AVCaptureDevice *)captureDeviceForPosition:(AVCaptureDevicePosition)position {
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices) {
        if ([device position] == position) {
            return device;
        }
    }
    return nil;
}

- (void)setDevicePosition:(AVCaptureDevicePosition)devicePosition {
    _devicePosition = devicePosition;
    AVCaptureDevice *device = (devicePosition == AVCaptureDevicePositionFront) ? backCamera : frontCamera;
    
    AVCaptureDeviceInput *newInput =  [AVCaptureDeviceInput deviceInputWithDevice:device error:nil];
    [_session beginConfiguration];
    [_session removeInput:currentInput];
    if ([_session canAddInput:newInput]) {
        [_session addInput:newInput];
        currentInput = newInput;
    }
    [_session commitConfiguration];
}

- (void)setFlash:(BOOL)flash {
    _flash = flash;
    if ([backCamera hasFlash]) {
        
        [backCamera lockForConfiguration:nil];
        if (_flash) {
            [backCamera setFlashMode:AVCaptureFlashModeOn];
        }
        else {
            [backCamera setFlashMode:AVCaptureFlashModeOff];
        }
        [backCamera unlockForConfiguration];
    }
}


- (void)setTorch:(BOOL)torch {
    _torch = torch;
    if ([backCamera hasTorch]) {
        
        [backCamera lockForConfiguration:nil];
        if (_torch) {
            [backCamera setTorchMode:AVCaptureTorchModeOn];
        }
        else {
            [backCamera setTorchMode:AVCaptureTorchModeOff];
        }
        [backCamera unlockForConfiguration];
    }

}

- (void)startCapture:(void (^)(NSURL *videoPath))block {
    completionBlock = block;
    @synchronized(self) {
        if (!self.isCapturing) {
            _encoder = nil;
            self.isPaused = NO;
            _discont = NO;
            _timeOffset = CMTimeMake(0, 0);
            _startTimestamp = CMClockGetTime(CMClockGetHostTimeClock());
            _startTime = CMClockGetTime(CMClockGetHostTimeClock());
            self.isCapturing = YES;
        }
    }
}

- (void)capturePhoto:(void (^)(UIImage *image))block {
    AVCaptureConnection *connection = [_stillImageOutput connectionWithMediaType:AVMediaTypeVideo];
    connection.videoOrientation = (AVCaptureVideoOrientation)[UIDevice currentDevice].orientation;
    [_stillImageOutput captureStillImageAsynchronouslyFromConnection:connection completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
        if (!error) {
            NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
            UIImage *image = [UIImage imageWithData:imageData];
            block(image);
        }
        else {
            block(nil);
        }
    }];
}

- (void)stopCapture {
    @synchronized(self) {
        if (self.isCapturing) {
            NSString* filename = [NSString stringWithFormat:@"capture%d.mp4", _currentFile];
            NSString* path = [NSTemporaryDirectory() stringByAppendingPathComponent:filename];
            NSURL* url = [NSURL fileURLWithPath:path];
            _currentFile++;
            
            self.isCapturing = NO;
            dispatch_async(_captureQueue, ^{
                [_encoder finishWithCompletionHandler:^{
                    self.isCapturing = NO;
                    _encoder = nil;
                    _startTimestamp = CMClockGetTime(CMClockGetHostTimeClock());
                    if (_autSaveVideo) {
                        ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
                        [library writeVideoAtPathToSavedPhotosAlbum:url completionBlock:^(NSURL *assetURL, NSError *error){
                            [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
                            if (completionBlock) {
                                completionBlock(url);
                            }
                        }];
                    }
                    else {
                        if (completionBlock) {
                            completionBlock(url);
                        }
                    }
                }];
            });
        }
    }
}

- (void)pauseCapture {
    @synchronized(self) {
        if (self.isCapturing) {
            self.isPaused = YES;
            _discont = YES;
            _pauseDate = [NSDate date];
            _pauseTimestamp = CMClockGetTime(CMClockGetHostTimeClock());
        }
    }
}

- (void)resumeCapture {
    @synchronized(self) {
        if (self.isPaused) {
            _amountPauseTime += [_pauseDate timeIntervalSinceNow];
            CMTimeSubtract(_pauseTimestamp, _startTimestamp);
            self.isPaused = NO;
        }
    }
}

- (CMSampleBufferRef)adjustTime:(CMSampleBufferRef)sample by:(CMTime)offset {
    CMItemCount count;
    CMSampleBufferGetSampleTimingInfoArray(sample, 0, nil, &count);
    CMSampleTimingInfo* pInfo = malloc(sizeof(CMSampleTimingInfo) * count);
    CMSampleBufferGetSampleTimingInfoArray(sample, count, pInfo, &count);
    for (CMItemCount i = 0; i < count; i++)
    {
        pInfo[i].decodeTimeStamp = CMTimeSubtract(pInfo[i].decodeTimeStamp, offset);
        pInfo[i].presentationTimeStamp = CMTimeSubtract(pInfo[i].presentationTimeStamp, offset);
    }
    CMSampleBufferRef sout;
    CMSampleBufferCreateCopyWithNewTiming(nil, sample, count, pInfo, &sout);
    free(pInfo);
    return sout;
}

- (void)setAudioFormat:(CMFormatDescriptionRef)fmt {
    const AudioStreamBasicDescription *asbd = CMAudioFormatDescriptionGetStreamBasicDescription(fmt);
    _samplerate = asbd->mSampleRate;
    _channels = asbd->mChannelsPerFrame;
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection {
    if (!metadataObjects || metadataObjects.count == 0) {
        return;
    }
    AVMetadataMachineReadableCodeObject *metadataObj = metadataObjects.firstObject;
    if (metadataObj.type == AVMetadataObjectTypeQRCode) {
        if (_readQRCodeCompletion) {
            _readQRCodeCompletion([metadataObj stringValue]);
        }
    }
}

- (void)progressVideoCapture:(CMSampleBufferRef)sampleBuffer {
    CMTime currentTimestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
    Float64 maximumUpdated = CMTimeGetSeconds(CMTimeSubtract(currentTimestamp, _startTimestamp)) + _amountPauseTime;
    if (_progressRecordingCompletion) {
        _progressRecordingCompletion(maximumUpdated, sampleBuffer);
    }
    if (maximumUpdated >= CMTimeGetSeconds(_maximumCaptureDuration)) {
        [self stopCapture];
    }
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    BOOL bVideo = YES;
    
    @synchronized(self) {
        if (!self.isCapturing  || self.isPaused) {
            return;
        }
        
        [self progressVideoCapture:sampleBuffer];
        
        if (connection != _videoConnection) {
            bVideo = NO;
        }
        if ((_encoder == nil) && !bVideo) {
            CMFormatDescriptionRef fmt = CMSampleBufferGetFormatDescription(sampleBuffer);
            [self setAudioFormat:fmt];
            NSString* filename = [NSString stringWithFormat:@"capture%d.mp4", _currentFile];
            NSString* path = [NSTemporaryDirectory() stringByAppendingPathComponent:filename];
            _encoder = [VideoEncoder encoderForPath:path Height:_cy width:_cx channels:_channels samples:_samplerate];
        }
        if (_discont) {
            if (bVideo) {
                return;
            }
            _discont = NO;

            CMTime pts = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
            CMTime last = bVideo ? _lastVideo : _lastAudio;
            if (last.flags & kCMTimeFlags_Valid) {
                if (_timeOffset.flags & kCMTimeFlags_Valid) {
                    pts = CMTimeSubtract(pts, _timeOffset);
                }
                CMTime offset = CMTimeSubtract(pts, last);
                
                if (_timeOffset.value == 0) {
                    _timeOffset = offset;
                }
                else {
                    _timeOffset = CMTimeAdd(_timeOffset, offset);
                }
            }
            _lastVideo.flags = 0;
            _lastAudio.flags = 0;
        }
        
        CFRetain(sampleBuffer);
        
        if (_timeOffset.value > 0) {
            CFRelease(sampleBuffer);
            sampleBuffer = [self adjustTime:sampleBuffer by:_timeOffset];
        }
        
        CMTime pts = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
        CMTime dur = CMSampleBufferGetDuration(sampleBuffer);
        if (dur.value > 0) {
            pts = CMTimeAdd(pts, dur);
        }
        if (bVideo) {
            _lastVideo = pts;
        }
        else {
            _lastAudio = pts;
        }
    }
    [_encoder encodeFrame:sampleBuffer isVideo:bVideo];
    CFRelease(sampleBuffer);
}

- (void)shutdown {
    if (_session) {
        [_session stopRunning];
        _session = nil;
    }
    [_encoder finishWithCompletionHandler:^{
        NSLog(@"Capture completed");
    }];
}


- (AVCaptureVideoPreviewLayer*)getPreviewLayer {
    return _preview;
}

#pragma mark -
#pragma mark App notifications

- (void)initAppNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_applicationWillEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:[UIApplication sharedApplication]];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_applicationDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:[UIApplication sharedApplication]];
}

- (void)_applicationWillEnterForeground:(NSNotification *)notification {
    NSLog(@"application will enter in foreground");
    if (!_session) {
        [self startup];
    }
}

- (void)_applicationDidEnterBackground:(NSNotification *)notification {
    NSLog(@"Application did enter in background");
    if (_session) {
        [self shutdown];
    }
}

#pragma mark -
#pragma mark Public API

+ (void)startup {
    [[self engine] startup];
}
+ (void)shutdown {
    [[self engine] shutdown];
}

+ (AVCaptureVideoPreviewLayer *)getPreviewLayer {
    return [[self engine] getPreviewLayer];
}

+ (void)capturePhoto:(void (^)(UIImage *image))block {
    [[self engine] capturePhoto:block];
}

+ (void)startCapture:(void (^)(NSURL *videoPath))block {
    [[self engine] startCapture:block];
}

+ (void)pauseCapture {
    [[self engine] pauseCapture];
}

+ (void)resumeCapture {
    [[self engine] resumeCapture];
}

+ (void)stopCapture {
    [[self engine] stopCapture];
}

@end
