Pod::Spec.new do |s|
  s.name         = "WeTransfer-Swift-SDK"
  s.version      = "1.0"
  s.summary      = "A Swift SDK for WeTransfer’s public API"
  s.homepage     = "https://github.com/WeTransfer/WeTransfer-Swift-SDK"
  s.license      = "MIT"
  s.author       = { "Pim Coumans" => "pim@pixelrock.nl" }
  s.source       = { :git => "https://github.com/WeTransfer/WeTransfer-Swift-SDK.git", :tag => "v#{s.version}" }

  s.swift_version = "4.1"
  s.ios.deployment_target = "9.0"
  s.osx.deployment_target = "10.10"

  s.source_files  = "WeTransfer/**/*.swift"
end
