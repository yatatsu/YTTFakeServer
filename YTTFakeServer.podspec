Pod::Spec.new do |s|
  s.name             = "YTTFakeServer"
  s.version          = "0.1.0"
  s.summary          = "A stub HTTP response provider for iOS."
  s.homepage         = "https://github.com/yatatsu/YTTFakeServer"
  s.license          = 'MIT'
  s.author           = { "yatatsu" => "yatatsukitagawa@gmail.com" }
  s.source           = { :git => "https://github.com/yatatsu/YTTFakeServer.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/tatsuyakit'

  s.platform     = :ios, '7.0'
  s.requires_arc = true

  s.source_files = 'Pod/Classes'
  s.resource_bundles = {
    'YTTFakeServer' => ['Pod/Assets/*.png']
  }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  s.dependency 'Reachability', '~> 3.2'
end
