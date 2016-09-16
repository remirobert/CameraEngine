Pod::Spec.new do |s|

  s.name         = "CameraEngine"
  s.version      = "1.0"
  s.summary      = "CameraEngine library for iOS in Swift"

  s.description  = <<-DESC
                   Camera engine for iOS in Swift, allow the QR code reading, recording video, capture photo, generate GIF.
                   DESC

  s.homepage     = "https://github.com/remirobert/CameraEngine"

  s.license      = "MIT"

  s.author             = { "rémi " => "remirobert33530@gmail.com" }
  s.social_media_url   = "http://twitter.com/remi936"

  s.platform     = :ios
  s.ios.deployment_target = "10.0"

  s.source       = { :git => "https://github.com/remirobert/CameraEngine.git", :tag => "1.0" }
  s.source_files  = "source", "CameraEngine/*"

end
