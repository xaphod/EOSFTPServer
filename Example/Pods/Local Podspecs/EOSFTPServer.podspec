#
# Be sure to run `pod lib lint EOSFTPServer.podspec' to ensure this is a
# valid spec and remove all comments before submitting the spec.
#
# Any lines starting with a # are optional, but encouraged
#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "EOSFTPServer"
  s.version          = "0.0.1"
  s.summary          = "A project to create a complete, standard compliant, multi-user, Objective-C (Mac OS X / iOS) FTP server."
  s.description      = <<-DESC
                        A project to create a complete, standard compliant, multi-user, Objective-C (Mac OS X / iOS) FTP server.
                        The original project was created by Jean-David Gadina - XS-Labs.
                       DESC
  s.homepage         = "https://github.com/codewhisper/EOSFTPServer"
  s.license          = 'Boost'
  s.author           = { "Michael Litvak" => "michael@codewhisper.com" }
  s.source           = { :git => "https://github.com/codewhisper/EOSFTPServer.git", :tag => s.version.to_s }

  s.platform     = :ios, '7.0'
  s.requires_arc = false

  s.source_files = 'Pod/Classes'

  # s.public_header_files = 'Pod/Classes/**/*.h'
  s.dependency 'CocoaAsyncSocket', '~> 7.3'
  s.xcconfig = {'OTHER_LDFLAGS' => '-ObjC -all_load'}
  s.prefix_header_file = 'Pod/Classes/EOSFTPServer-Prefix.pch'
end
