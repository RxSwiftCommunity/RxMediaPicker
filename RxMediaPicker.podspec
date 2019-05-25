Pod::Spec.new do |s|
  s.name         = "RxMediaPicker"
  s.version      = "2.0.0"
  s.summary      = "A reactive wrapper built around UIImagePickerController."
  s.homepage     = "https://github.com/RxSwiftCommunity/RxMediaPicker"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.authors      = { "Rui Costa" => "rui.pfcosta@gmail.com", "Shai Mishali" => "freak4pc@gmail.com" }
  s.platform     = :ios, "8.0"
  s.source       = { :git => 'https://github.com/RxSwiftCommunity/RxMediaPicker.git', :tag => s.version }
  s.source_files = "RxMediaPicker/*.swift"
  s.requires_arc = true
  s.dependency 'RxSwift', '>= 4.3.1'
end
