require "json"

package = JSON.parse(File.read(File.join(__dir__, "package.json")))

Pod::Spec.new do |s|
  s.name         = "ReactNativeEnrichedMarkdown"
  s.version      = package["version"]
  s.summary      = package["description"]
  s.homepage     = package["homepage"]
  s.license      = package["license"]
  s.authors      = package["author"]

  s.platforms    = { :ios => min_ios_version_supported, :osx => '14.0' }
  s.source       = { :git => "https://github.com/software-mansion-labs/react-native-enriched-markdown.git", :tag => "#{s.version}" }

  s.source_files = "ios/**/*.{h,m,mm,cpp}", "cpp/md4c/*.{c,h}", "cpp/parser/*.{hpp,cpp}"
  s.private_header_files = "ios/**/*.h"

  # To disable LaTeX math rendering (iosMath, supported on iOS and macOS), add ENV['ENRICHED_MARKDOWN_ENABLE_MATH'] = '0' to your Podfile.
  enable_math = ENV['ENRICHED_MARKDOWN_ENABLE_MATH'] != '0'

  preprocessor_defs = '$(inherited) MD4C_USE_UTF8=1'
  if enable_math
    preprocessor_defs += ' ENRICHED_MARKDOWN_MATH=1'
    s.dependency 'iosMath', '~> 0.9'
  end

  # Quoted imports like #import "Foo.h" do not search subdirs recursively; list every
  # ios folder that contains headers so renderer/ utils/ attachments/ etc. cross-imports resolve.
  ios_header_paths = %w[
    ios ios/attachments ios/input ios/input/internals ios/input/styles ios/internals ios/parser
    ios/renderer ios/styles ios/utils ios/views
  ].map { |p| "\"$(PODS_TARGET_SRCROOT)/#{p}\"" }.join(' ')

  s.pod_target_xcconfig = {
    'HEADER_SEARCH_PATHS' => "\"$(PODS_TARGET_SRCROOT)/cpp/md4c\" \"$(PODS_TARGET_SRCROOT)/cpp/parser\" #{ios_header_paths}",
    # React / SwiftUI modules use framework-style modules; our ObjC uses plain quoted includes.
    'CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES' => 'YES',
    'GCC_PREPROCESSOR_DEFINITIONS' => preprocessor_defs,
    'CLANG_CXX_LANGUAGE_STANDARD' => 'c++17'
  }

  install_modules_dependencies(s)
end
