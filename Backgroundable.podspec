Pod::Spec.new do |s|
  s.name             = "Backgroundable"
  s.version          = "0.2.2"
  s.summary          = "A collection of handy classes, extensions and global functions to handle being in the background on iOS using Swift."
  s.homepage         = "https://github.com/BellAppLab/Backgroundable"
  s.license          = 'MIT'
  s.author           = { "Bell App Lab" => "apps@bellapplab.com" }
  s.source           = { :git => "https://github.com/BellAppLab/Backgroundable.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/BellAppLab'

  s.platform     = :ios, '8.0'
  s.requires_arc = true

  s.source_files = 'Pod/Classes/**/*'

  s.frameworks = 'UIKit'
end
