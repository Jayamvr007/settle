# Gemfile for Fastlane
# Run: bundle install

source "https://rubygems.org"

gem "fastlane", "~> 2.225"
gem "cocoapods", "~> 1.15"

# Optional plugins
plugins_path = File.join(File.dirname(__FILE__), 'fastlane', 'Pluginfile')
eval_gemfile(plugins_path) if File.exist?(plugins_path)
