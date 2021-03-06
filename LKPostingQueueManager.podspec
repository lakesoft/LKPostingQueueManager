#
# Be sure to run `pod lib lint LKPostingQueueManager.podspec' to ensure this is a
# valid spec and remove all comments before submitting the spec.
#
# Any lines starting with a # are optional, but encouraged
#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "LKPostingQueueManager"
  s.version          = "1.2.0"
  s.summary          = "Queue manager for posting"
  s.description      = <<-DESC
  Queue manager for posting
                       DESC
  s.homepage         = "https://github.com/lakesoft/LKPostingQueueManager"
  # s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"
  s.license          = 'MIT'
  s.author           = { "Hiroshi Hashiguchi" => "xcatsan@mac.com" }
  s.source           = { :git => "https://github.com/lakesoft/LKPostingQueueManager.git", :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.platform     = :ios, '10.0'
  s.requires_arc = true

  s.source_files = 'Pod/Classes/**/*'
  s.resource_bundles = {
    'LKPostingQueueManager' => ['Pod/Assets/*']
  }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  s.dependency 'LKQueue'
  s.dependency 'LKTaskCompletion'
  s.dependency 'FBNetworkReachability'
  s.dependency 'LKCodingObject'
end
