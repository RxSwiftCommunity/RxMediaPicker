Pod::Spec.new do |s|
  s.name         = "RxMediaPicker"
  s.version      = "2.0.1"
  s.summary      = "A reactive wrapper built around UIImagePickerController."
  s.homepage     = "https://github.com/RxSwiftCommunity/RxMediaPicker"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.authors      = { "Rui Costa" => "rui.pfcosta@gmail.com", "Shai Mishali" => "freak4pc@gmail.com" }
  s.platform     = :ios, "9.0"
  s.source       = { :git => 'https://github.com/RxSwiftCommunity/RxMediaPicker.git', :tag => s.version }
  s.source_files = "Sources/RxMediaPicker/*.swift"
  s.requires_arc = true
  s.dependency 'RxSwift', '>= 6.0.0'
end
