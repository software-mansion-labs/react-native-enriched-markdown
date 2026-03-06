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

  # LaTeX math rendering via iosMath is enabled by default.
  # To disable it and save ~2.5 MB, set the environment variable before running pod install:
  #   ENRICHED_MARKDOWN_ENABLE_MATH=0 bundle exec pod install
  # Or add to your Podfile:
  #   ENV['ENRICHED_MARKDOWN_ENABLE_MATH'] = '0'
  enable_math = ENV['ENRICHED_MARKDOWN_ENABLE_MATH'] != '0'

  preprocessor_defs = '$(inherited) MD4C_USE_UTF8=1'
  if enable_math
    preprocessor_defs += ' ENRICHED_MARKDOWN_MATH=1'
    s.dependency 'iosMath', '~> 0.9'
  end

  s.pod_target_xcconfig = {
    'HEADER_SEARCH_PATHS' => '"$(PODS_TARGET_SRCROOT)/cpp/md4c" "$(PODS_TARGET_SRCROOT)/cpp/parser" "$(PODS_TARGET_SRCROOT)/ios/internals"',
    'GCC_PREPROCESSOR_DEFINITIONS' => preprocessor_defs,
    'CLANG_CXX_LANGUAGE_STANDARD' => 'c++17'
  }

  install_modules_dependencies(s)
end
