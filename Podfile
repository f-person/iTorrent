#plugin 'cocoapods-binary'

platform :ios, '11.0'
#enable_bitcode_for_prebuilt_frameworks!
#keep_source_code_for_prebuilt_frameworks!
#all_binary!

target 'iTorrent' do
  use_frameworks!
  pod 'MarqueeLabel'
  pod "GCDWebServer/WebUploader", "~> 3.0"
  pod "GCDWebServer/WebDAV", "~> 3.0"
  pod 'DeepDiff'
  pod "SwiftyXMLParser", :git => 'https://github.com/yahoojapan/SwiftyXMLParser.git'
  pod 'Bond'
end

#target 'iTorrent-ProgressWidgetExtension' do
#  use_frameworks!
#end

post_install do |installer|
  #fix MarqueeLabel IBDesignable error
  installer.pods_project.build_configurations.each do |config|
    config.build_settings.delete('CODE_SIGNING_ALLOWED')
    config.build_settings.delete('CODE_SIGNING_REQUIRED')
  end

  #fix missing libarclite_iphoneos.a
  installer.generated_projects.each do |project|
    project.targets.each do |target|
      target.build_configurations.each do |config|
        config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '11.0'
      end
    end
  end
end
