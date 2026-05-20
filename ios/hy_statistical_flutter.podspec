Pod::Spec.new do |s|
  s.name             = 'hy_statistical_flutter'
  s.version          = '0.3.0'
  s.summary          = 'HyStatistical Flutter SDK iOS plugin (ad attribution support)'
  s.description      = <<-DESC
                       Flutter plugin that exposes native iOS IDFA / IDFV / PAID collection
                       to the Dart side via method channel, for ad attribution matching against
                       the HyStatistical backend (xiaohongshu / douyin etc.).
                       DESC
  s.homepage         = 'https://github.com/1251627/hy-statistical-flutter'
  s.license          = { :type => 'MIT' }
  s.author           = { 'HyStatistical' => 'noreply@futurofun.cc' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '14.0'
  s.swift_version = '5.9'
  s.frameworks = 'Foundation', 'UIKit', 'AdSupport'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
end
