#!/usr/bin/env ruby
require 'xcodeproj'

# Path to your Xcode project
project_path = 'Runner.xcodeproj'

# Open the project
project = Xcodeproj::Project.open(project_path)

# Framework search paths to ensure Flutter and SwiftyGif are found
framework_search_paths = [
  '$(inherited)',
  '$(SRCROOT)/../Flutter',
  '$(PODS_ROOT)/../../Flutter',
  '$(PODS_CONFIGURATION_BUILD_DIR)',
  '$(BUILT_PRODUCTS_DIR)',
  '$(PODS_ROOT)/../Flutter'
]

# Get the main target
target = project.targets.first

puts "Fixing build settings for target: #{target.name}"

# Update each build configuration
target.build_configurations.each do |config|
  puts "Updating configuration: #{config.name}"
  
  # Set Swift version
  config.build_settings['SWIFT_VERSION'] = '5.0'
  
  # Disable bitcode
  config.build_settings['ENABLE_BITCODE'] = 'NO'
  
  # Set iOS deployment target to 12.0
  config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '12.0'
  
  # Fix framework search paths
  config.build_settings['FRAMEWORK_SEARCH_PATHS'] ||= []
  
  # Add our framework search paths
  framework_search_paths.each do |path|
    unless config.build_settings['FRAMEWORK_SEARCH_PATHS'].include?(path)
      config.build_settings['FRAMEWORK_SEARCH_PATHS'] << path
    end
  end
  
  # Fix header search paths
  config.build_settings['HEADER_SEARCH_PATHS'] ||= []
  header_paths = [
    '$(inherited)',
    '${PODS_ROOT}/Headers/Public',
    '${PODS_ROOT}/Headers/Public/Flutter'
  ]
  
  header_paths.each do |path|
    unless config.build_settings['HEADER_SEARCH_PATHS'].include?(path)
      config.build_settings['HEADER_SEARCH_PATHS'] << path
    end
  end
  
  # Fix other important flags
  config.build_settings['CLANG_ENABLE_MODULES'] = 'YES'
  config.build_settings['DEFINES_MODULE'] = 'YES'
  
  # Fix for Xcode 15
  if config.name == 'Debug'
    config.build_settings['EXCLUDED_ARCHS[sdk=iphonesimulator*]'] = 'arm64'
  end
  
  # Fix for printing module
  config.build_settings['OTHER_LDFLAGS'] ||= []
  unless config.build_settings['OTHER_LDFLAGS'].include?('-framework Flutter')
    config.build_settings['OTHER_LDFLAGS'] << '-framework Flutter'
  end
end

# Save the project
puts "Saving project..."
project.save

puts "Project settings have been fixed!" 