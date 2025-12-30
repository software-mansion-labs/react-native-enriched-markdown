require "json"

package = JSON.parse(File.read(File.join(__dir__, "package.json")))

Pod::Spec.new do |s|
  s.name         = "RichText"
  s.version      = package["version"]
  s.summary      = package["description"]
  s.homepage     = package["homepage"]
  s.license      = package["license"]
  s.authors      = package["author"]

  s.platforms    = { :ios => min_ios_version_supported }
  s.source       = { :git => "https://github.com/software-mansion-labs/react-native-rich-text.git", :tag => "#{s.version}" }

  s.source_files = "ios/**/*.{h,m,mm,cpp}", "cpp/md4c/*.{c,h}"
  s.private_header_files = "ios/**/*.h"
  
  # Set header search paths to cpp/md4c and add preprocessor definitions
  s.pod_target_xcconfig = {
    'HEADER_SEARCH_PATHS' => '$(PODS_TARGET_SRCROOT)/cpp/md4c',
    'GCC_PREPROCESSOR_DEFINITIONS' => '$(inherited) MD4C_USE_UTF8=1'
  }


  install_modules_dependencies(s)
end
