Pod::Spec.new do |s|
  s.name         = "RxMediaPicker"
  s.version      = "0.0.1"
  s.summary      = "A reactive wrapper built around UIImagePickerController."
  s.homepage     = "https://github.com/ruipfcosta/RxMediaPicker"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.authors      = { "Rui Costa" => "rui.pfcosta@gmail.com" }
  s.platform     = :ios, "8.0"
  s.source       = { :git => 'https://github.com/ruipfcosta/RxMediaPicker.git', :tag => s.version }
  s.source_files = "RxMediaPicker/*.swift"
  s.requires_arc = true
  s.dependency   'RxSwift', '~> 3.0'
end
