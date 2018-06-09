Pod::Spec.new do |s|
  s.name             = "PostalAddressRow"
  s.version          = "2.1.0"
  s.summary          = "An Eureka row that shows a series of UITextField's for the user to enter postal address information."
  s.homepage         = "https://github.com/EurekaCommunity/PostalAddressRow"
  s.license          = { type: 'MIT', file: 'LICENSE' }
  s.author           = { "Xmartlabs SRL" => "swift@xmartlabs.com" }
  s.source           = { git: "https://github.com/EurekaCommunity/PostalAddressRow.git", tag: s.version.to_s }
  s.social_media_url = 'https://twitter.com/EurekaCommunity'
  s.ios.deployment_target = '8.0'
  s.requires_arc = true
  s.ios.source_files = 'Sources/**/*.{swift}'
  s.resource_bundles = {
    'PostalAddressRow' => ['Sources/**/*.xib']
  }
  # s.ios.frameworks = 'UIKit', 'Foundation'
  s.dependency 'Eureka'
end
