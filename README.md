![cameraenginelogo](https://cloud.githubusercontent.com/assets/3276768/13000720/df3ec444-d1b1-11e5-9312-e70dabafa2f1.png)

<h3 align="center">🌟 The most advanced Camera framework in <strong>Swift</strong> 🌟</h1>

[![License MIT](https://img.shields.io/badge/license-MIT-green.svg?style=flat)](https://raw.githubusercontent.com/remirobert/CameraEngine/master/LICENSE)&nbsp;
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)&nbsp;
[![CocoaPods](http://img.shields.io/cocoapods/v/CameraEngine.svg?style=flat)](http://cocoapods.org/?q=CameraEngine)&nbsp;
[![Build Status](https://travis-ci.org/remirobert/CameraEngine.svg?branch=master)](https://travis-ci.org/remirobert/CameraEngine)
[![CocoaPods](http://img.shields.io/cocoapods/p/CameraEngine.svg?style=flat)](http://cocoapods.org/?q=CameraEngine)&nbsp;
[![Support](https://img.shields.io/badge/support-iOS%208%2B%20-blue.svg?style=flat)](https://www.apple.com/nl/ios/)&nbsp;
[![codebeat badge](https://codebeat.co/badges/fcf16e2f-fe4e-4d4d-abb4-968e71c7d9f2)](https://codebeat.co/projects/github-com-remirobert-cameraengine)&nbsp;
[![Donate](http://www.paypalobjects.com/en_US/i/btn/btn_donate_LG.gif)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=2MUNQRB8KTSM8 "Donate")

**CameraEngine** *is an iOS camera engine library that allows easy integration of special capture features and camera customization in your iOS app.*

<p align="center">
  <img src ="https://cloud.githubusercontent.com/assets/3276768/14136235/579a1a2c-f694-11e5-8bce-f784884da8ea.png"/>
</p>

## :fire: Features

|         | CameraEngine  |
----------|-----------------
:relaxed: | Support iOS8 - iOS9
:triangular_ruler: | Support orientation device
:checkered_flag: | Fast capture
:camera: | Photo capture
:movie_camera: | Video capture
:chart_with_upwards_trend: | quality settings presset video / photo capture
:raising_hand: | switch device (front, back)
:bulb: | flash mode management
:flashlight: | torch mode management
:mag_right: | focus mode management
:bowtie: | detection face, barecode, and qrcode
:rocket: | GIF encoder

## 🔨 Installation

#### CocoaPods

- Add `pod "CameraEngine"` to your Podfile.
- Run `pod install` or `pod update`.
- import CameraEngine


#### Carthage

- Add `github "remirobert/CameraEngine"` to your Cartfile.
- Run `carthage update` and add the framework to your project.
- import CameraEngine


#### Manually

- Download all the files in the CameraEngine subdirectory.
- Add the source files to your Xcode project.
- import CameraEngine


To add the Framework, you can also create a **workspace** for your project, then add the **CameraEngine.xcodeproj**, and the **CameraEngine**, then you should be able to compile the framework, and import it in your app project.

**CameraEngine** supports *swift3*, see the development branch for a swift 3 integration.

## :rocket: Quick start

> First let's init and start the camera session. You can call that in viewDidLoad, or in appDelegate.

```Swift
override func viewDidLoad() {
  super.viewDidLoad()
  self.cameraEngine.startSession()
}
```
> Next time to display the preview layer

```Swift
override func viewDidLayoutSubviews() {
  let layer = self.cameraEngine.previewLayer
        
  layer.frame = self.view.bounds
  self.view.layer.insertSublayer(layer, atIndex: 0)
  self.view.layer.masksToBounds = true
}
```

> Capture a photo

```Swift
self.cameraEngine.capturePhoto { (image: UIImage?, error: NSError?) -> (Void) in
  //get the picture tooked in the 👉 image
}
```

> Capture a video

```Swift
private func startRecording() {
  guard let url = CameraEngineFileManager.documentPath("video.mp4") else {
    return
  }
            
  self.cameraEngine.startRecordingVideo(url, blockCompletion: { (url, error) -> (Void) in
  })
}

private func stopRecording() {
  self.cameraEngine.stopRecordingVideo()
}
```

> Generate animated image GIF

```swift
guard let url = CameraEngineFileManager.documentPath("animated.gif") else {
  return
}
self.cameraEngine.createGif(url, frames: self.frames, delayTime: 0.1, completionGif: { (success, url) -> (Void) in
  //Do some crazy stuff here
})
```

## :wrench: configurations

CameraEngine, allows you to set some parameters, such as management of **flash**, **torch** and **focus**. But also on the quality of the media, which also has an impact on the size of the output file. 

> Flash

```swift
self.cameraEngine.flashMode = .On
self.cameraEngine.flashMode = .Off
self.cameraEngine.flashMode = .Auto
```

> Torch

```swift
self.cameraEngine.torchMode = .On
self.cameraEngine.torchMode = .Off
self.cameraEngine.torchMode = .Auto
```

> Focus

              |  CameraEngine focus
--------------------------|------------------------------------------------------------
.Locked | means the lens is at a fixed position
.AutoFocus | means setting this will cause the camera to focus once automatically, and then return back to Locked
.ContinuousAutoFocus | means the camera will automatically refocus on the center of the frame when the scene changes

```swift
self.cameraEngine.cameraFocus = .Locked
self.cameraEngine.cameraFocus = .AutoFocus
self.cameraEngine.cameraFocus = .ContinuousAutoFocus
```

> Camera presset Photo

```swift
self.cameraEngine.sessionPresset = .Low
self.cameraEngine.sessionPresset = .Medium
self.cameraEngine.sessionPresset = .High
...
```

> Camera presset Video

```swift
self.cameraEngine.videoEncoderPresset = .Preset640x480
self.cameraEngine.videoEncoderPresset = .Preset960x540
self.cameraEngine.videoEncoderPresset = .Preset1280x720
self.cameraEngine.videoEncoderPresset = .Preset1920x1080
self.cameraEngine.videoEncoderPresset = .Preset3840x2160
```

## :eyes: Object detection

CameraEngine can detect **faces**, **QRcodes**, or **barcode**. It will return all metadata on each frame, when it detects something. To exploit you whenever you want later.

> Set the detection mode

```swift
self.cameraEngine.metadataDetection = .Face
self.cameraEngine.metadataDetection = .QRCode
self.cameraEngine.metadataDetection = .BareCode
self.cameraEngine.metadataDetection = .None //disable the detection
```
> exploiting face detection

```swift
self.cameraEngine.blockCompletionFaceDetection = { faceObject in
  let frameFace = (faceObject as AVMetadataObject).bounds
  self.displayLayerDetection(frame: frameFace)
}
```

> exploiting code detection (barecode and QRCode)

```swift
self.cameraEngine.blockCompletionCodeDetection = { codeObject in
  let valueCode = codeObject.stringValue
  let frameCode = (codeObject as AVMetadataObject).bounds
  self.displayLayerDetection(frame: frameCode)
}
```

## :car::dash: Example

You will find a sample project, which implements all the features of CameraEngine, with an interface that allows you to test and play with the settings.
To run the example projet, run `pod install`, because it uses the current prod version of CameraEngine.

<img src="http://i.giphy.com/mMkiMqylxW2bK.gif" />

## Contributors 🍻

 - [eyaldar](https://github.com/eyaldar)
 - [davidlondono](https://github.com/davidlondono)
 - [patthehuman](https://github.com/patthehuman)
 - [jnoh](https://github.com/jnoh)

## License
This project is licensed under the terms of the MIT license. See the LICENSE file.

> This project is in no way affiliated with Apple Inc. This project is open source under the MIT license, which means you have full access to the source code and can modify it to fit your own needs.

If you want to support the development of this library, feel free to
[![Donate](http://www.paypalobjects.com/en_US/i/btn/btn_donate_LG.gif)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=2MUNQRB8KTSM8 "Donate"). Thanks to all contributors so far!

![bannabot](https://cloud.githubusercontent.com/assets/3276768/13000776/da960a14-d1b2-11e5-849f-d0f0703b8aa2.png)
