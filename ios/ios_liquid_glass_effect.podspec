Pod::Spec.new do |s|
  s.name             = 'ios_liquid_glass_effect'
  s.version          = '0.1.0-alpha.3'
  s.summary          = 'Native iOS Liquid Glass surfaces and buttons for Flutter.'
  s.description      = <<-DESC
Native UIKit Liquid Glass surfaces and buttons on iOS 26 and later, with
conventional UIKit materials on older iOS versions. Build with the iOS 26 SDK
or newer.
                       DESC
  s.homepage         = 'https://www.codemicros.com/'
  s.license          = { :type => 'MIT', :file => '../LICENSE' }
  s.author           = { 'CodeMicros' => 'codemicros@gmail.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'ios_liquid_glass_effect/Sources/ios_liquid_glass_effect/**/*.swift'
  s.dependency 'Flutter'
  s.platform         = :ios, '13.0'
  s.swift_version    = '5.0'
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386'
  }
end
