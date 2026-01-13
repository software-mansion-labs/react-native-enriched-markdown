require "json"

package = JSON.parse(File.read(File.join(__dir__, "package.json")))

Pod::Spec.new do |s|
  s.name         = "ReactNativeEnrichedMarkdown"
  s.version      = package["version"]
  s.summary      = package["description"]
  s.homepage     = package["homepage"]
  s.license      = package["license"]
  s.authors      = package["author"]

  s.platforms    = { :ios => min_ios_version_supported }
  s.source       = { :git => "https://github.com/software-mansion-labs/react-native-enriched-markdown.git", :tag => "#{s.version}" }

  s.source_files = "ios/**/*.{h,m,mm,cpp}", "cpp/md4c/*.{c,h}", "cpp/parser/*.{hpp,cpp}"
  s.private_header_files = "ios/**/*.h"

  # Set header search paths to cpp/md4c and cpp/parser, add preprocessor definitions
  s.pod_target_xcconfig = {
    'HEADER_SEARCH_PATHS' => '"$(PODS_TARGET_SRCROOT)/cpp/md4c" "$(PODS_TARGET_SRCROOT)/cpp/parser" "$(PODS_TARGET_SRCROOT)/ios/internals"',
    'GCC_PREPROCESSOR_DEFINITIONS' => '$(inherited) MD4C_USE_UTF8=1',
    'CLANG_CXX_LANGUAGE_STANDARD' => 'c++17'
  }

  install_modules_dependencies(s)
end
