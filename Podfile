platform :ios, '16.0'

target 'Settle' do
  use_frameworks!

  # Pods for Settle
  pod 'razorpay-pod'
  
  # Migrating from SPM to Pods to fix Architecture Conflicts
  pod 'Firebase/Auth'
  pod 'Firebase/Firestore'
  pod 'GoogleSignIn'

end

# Fix arm64 simulator architecture issue on Apple Silicon Macs
post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['EXCLUDED_ARCHS[sdk=iphonesimulator*]'] = 'arm64'
    end
  end
end
