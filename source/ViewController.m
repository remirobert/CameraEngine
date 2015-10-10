//
//  ViewController.m
//  CameraEngine
//
//  Created by Remi Robert on 19/08/15.
//  Copyright (c) 2015 Remi Robert. All rights reserved.
//

#import "PreviewViewController.h"
#import "ViewController.h"
#import "CameraEngine.h"

@interface ViewController ()
@property (nonatomic, assign) Float64 progressVideoRecording;
@end

@implementation ViewController

- (void)tapHandler {
    [CameraEngine capturePhoto:^(UIImage *image) {
        [self performSegueWithIdentifier:@"previewSegue" sender:image];
    }];
}

- (IBAction)switch:(id)sender {
    AVCaptureDevicePosition current = [CameraEngine shareInstance].devicePosition;
    
    [CameraEngine shareInstance].devicePosition = (current == AVCaptureDevicePositionBack) ? AVCaptureDevicePositionFront : AVCaptureDevicePositionBack;
}

- (void)longPressHandler:(UILongPressGestureRecognizer *)longPress {
    if (longPress.state == UIGestureRecognizerStateBegan) {
        if (![CameraEngine shareInstance].isCapturing) {
            [CameraEngine startCapture:^(NSURL *videoPath) {
                
            }];
        }
        else {
            if ([CameraEngine shareInstance].isPaused) {
                [CameraEngine resumeCapture];
            }
        }
    }
    else if (longPress.state == UIGestureRecognizerStateCancelled ||
             longPress.state == UIGestureRecognizerStateEnded ||
             longPress.state == UIGestureRecognizerStateFailed) {
        [CameraEngine stopCapture];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [CameraEngine startup];
    
    AVCaptureVideoPreviewLayer *preview = [CameraEngine getPreviewLayer];
    preview.frame = self.view.bounds;
    [self.view.layer addSublayer:preview];
    
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapHandler)];
    [self.view addGestureRecognizer:tap];
    
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressHandler:)];
    [self.view addGestureRecognizer:longPress];
    
    [CameraEngine shareInstance].readQRCodeCompletion = ^(NSString *content) {
        NSLog(@"content qr code");
    };
    
    [CameraEngine shareInstance].progressRecordingCompletion = ^(Float64 currentTime, CMSampleBufferRef sampleBuffer) {
        self.progressVideoRecording = currentTime;
        NSLog(@"current progress : %f", currentTime);
    };
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"previewSegue"]) {
        ((PreviewViewController *)segue.destinationViewController).image = (UIImage *)sender;
    }
}

@end
