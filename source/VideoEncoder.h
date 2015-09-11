//
//  VideoEncoder.h
//  CameraEngine
//
//  Created by Remi Robert on 19/08/15.
//  Copyright (c) 2015 Remi Robert. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

@interface VideoEncoder : NSObject {
    AVAssetWriter* _writer;
    AVAssetWriterInput* _videoInput;
    AVAssetWriterInput* _audioInput;
    NSString* _path;
}

@property NSString* path;

+ (VideoEncoder*) encoderForPath:(NSString*) path Height:(int) cy width:(int) cx channels: (int) ch samples:(Float64) rate;

- (void) initPath:(NSString*)path Height:(int) cy width:(int) cx channels: (int) ch samples:(Float64) rate;
- (void) finishWithCompletionHandler:(void (^)(void))handler;
- (BOOL) encodeFrame:(CMSampleBufferRef) sampleBuffer isVideo:(BOOL) bVideo;


@end
