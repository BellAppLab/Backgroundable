Pod::Spec.new do |s|

  s.name                = "Backgroundable"
  s.version             = "1.4.1"
  s.summary             = "A collection of handy classes, extensions and global functions to handle being in the background using Swift."
  s.screenshot          = "https://github.com/BellAppLab/Backgroundable/raw/master/Images/backgroundable.png"

  s.description         = <<-DESC
Backgroundable is a collection of handy classes, extensions and global functions to handle being in the background using Swift.

It's main focus is to add functionalities to existing `Operation`s and `OperationQueue`s, without adding overheads to the runtime (aka it's fast) nor to the developer (aka there's very little to learn).

It's powerful because it's simple.
                   DESC

  s.homepage            = "https://github.com/BellAppLab/Backgroundable"

  s.license             = { :type => "MIT", :file => "LICENSE" }

  s.author              = { "Bell App Lab" => "apps@bellapplab.com" }
  s.social_media_url    = "https://twitter.com/BellAppLab"

  s.ios.deployment_target = "10.0"
  s.osx.deployment_target = "10.12"
  s.tvos.deployment_target = "10.0"

  s.swift_version       = '5.3'

  s.module_name         = 'Backgroundable'

  s.source              = { :git => "https://github.com/BellAppLab/Backgroundable.git", :tag => "#{s.version}" }

  s.source_files        = "Sources/Backgroundable"

  s.framework           = "Foundation"
  s.ios.framework       = "UIKit"
  s.tvos.framework      = "UIKit"

end
