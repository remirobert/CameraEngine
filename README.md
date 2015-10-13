#How to install

With cocoapods:
```ruby
pod 'CameraEngine', '~> 0.2'
```

#How to use

Start and shutdown :
```Objective-c
//start camera engine
[CameraEngine startup];

//shutdown camera engine
[CameraEngine shutdown];
```

Preview layer :

```Objective-c
AVCaptureVideoPreviewLayer *preview = [CameraEngine getPreviewLayer];
preview.frame = self.view.bounds;
[self.view.layer addSublayer:preview];
```

Change device orientation :

```Objective-c
//In a button action trigger :
- (IBAction)switch:(id)sender {
    AVCaptureDevicePosition current = [CameraEngine shareInstance].devicePosition;

    [CameraEngine shareInstance].devicePosition = (current == AVCaptureDevicePositionBack) ? AVCaptureDevicePositionFront : AVCaptureDevicePositionBack;
}

// Or manually :
[CameraEngine shareInstance].devicePosition = AVCaptureDevicePositionFront;
[CameraEngine shareInstance].devicePosition = AVCaptureDevicePositionBack;
```

Video recording methods :

```Objective-c
//Starting and resume video recording
//In UILongPressGestureRecognizer for example
if (![CameraEngine shareInstance].isCapturing) {
    [CameraEngine startCapture:^(NSURL *videoPath) {
      //Do whatever you want with your video path.
      //Return nil if an error occured
    }];
}
else {
    if ([CameraEngine shareInstance].isPaused) {
        [CameraEngine resumeCapture];
    }
}

//Stop video recording
[CameraEngine stopCapture];
```

Photo capture methods :
```Objective-c
[CameraEngine capturePhoto:^(UIImage *image) {
  //Do whatever you want with your image.
  //Return nil if an error occured
}];
```

Read QR code :

```Objective-c
[CameraEngine shareInstance].readQRCodeCompletion = ^(NSString *content) {
  //Do whatever you want with your content.
};
```

Get recording progress block :

```Objective-c
[CameraEngine shareInstance].progressRecordingCompletion = ^(Float64 currentTime, CMSampleBufferRef sampleBuffer) {
  //get the current time here, for progress bar.
  //get the sample buffer to get a single frame.
};
```
