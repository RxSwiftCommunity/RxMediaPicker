# RxMediaPicker

RxMediaPicker is a RxSwift wrapper built around UIImagePickerController consisting in a simple interface for common actions like picking photos or videos stored on the device, recording a video or taking a photo.

If you ever used UIImagePickerController you know how it can become quite verbose and introduce some unnecessary complexity, as you use the same class to do everything, from picking photos or videos from the library, recording videos, etc. At the same time, you have all these different properties and methods which can be used when you are dealing with photos, others for when you're dealing with videos, and others in all cases.

If you're interested, check the resulting article [RxMediaPicker — picking photos and videos the cool kids’ way!](https://medium.com/@ruipfcosta/rxmediapicker-picking-photos-and-videos-the-cool-kids-way-4df81df0c778#.1wq0xp99o)

**Note:** As RxMediaPicker is still in its early days, the interface may change in future versions. 

##Features

- [x] Reactive wrapper built around UIImagePickerController.
- [x] Provides an interface for common operations like picking photos from the library, recording videos, etc.
- [x] Handles edited videos properly - something UIImagePickerController doesn't do for you!
- [x] Decouples the typical UIImagePickerController boilerplate from your code.
- [x] Reduces the complexity when compared to UIImagePickerController.
- [x] Easy to integrate and reuse accross your app.

##Example

For a more complete example please check the demo app included (ideally run it on a device). This is how you would record a video using the camera:

```swift
import RxMediaPicker
import RxSwift

var picker: RxMediaPicker!
let disposeBag = DisposeBag()

override func viewDidLoad() {
    super.viewDidLoad()
    picker = RxMediaPicker(delegate: self)
}

func recordVideo() {
    picker.recordVideo(maximumDuration: 10, editable: true)
        .observeOn(MainScheduler.instance)
        .subscribe(onNext: { url in
            // Do something with the video url obtained!
        }, onError: { error in
            print("Error occurred!")
        }, onCompleted: {
            print("Completed")
        }, onDisposed: {
            print("Disposed")
        })
        .addDisposableTo(disposeBag)
}
```

##Usage

###Available operations

Based on their names, the operations available on RxMediaPicker should be self-explanatory. You can record a video, or pick an existing one stored on the device, and the same thing happens for photos. The only thing to note here is that picking a video will get you the video url, and picking a photo will get you a tuple consisting in the original image and an optional edited image (if any edits were made).

```swift
func recordVideo(device device: UIImagePickerControllerCameraDevice = .Rear, 
                 quality: UIImagePickerControllerQualityType = .TypeMedium, 
                 maximumDuration: NSTimeInterval = 600, editable: Bool = false) -> Observable<NSURL>
```

```swift
func selectVideo(source: UIImagePickerControllerSourceType = .PhotoLibrary, 
                 maximumDuration: NSTimeInterval = 600, editable: Bool = false) -> Observable<NSURL>
```

```swift
func takePhoto(device device: UIImagePickerControllerCameraDevice = .Rear, 
               flashMode: UIImagePickerControllerCameraFlashMode = .Auto, 
               editable: Bool = false) -> Observable<(UIImage, UIImage?)>
```

```swift
func selectImage(source: UIImagePickerControllerSourceType = .PhotoLibrary, 
                 editable: Bool = false) -> Observable<(UIImage, UIImage?)>
```

###RxMediaPickerDelegate

```swift
func presentPicker(picker: UIImagePickerController)
func dismissPicker(picker: UIImagePickerController) 
```

To be able to use RxMediaPicker you will need to adopt the protocol RxMediaPickerDelegate. This is required to indicate RxMediaPicker how the camera/photos picker should be presented. For example, you may want to present the photos library picker in a popover on the iPad, and use the entire screen on the iPhone.


##Requirements

* iOS 8.0+
* Xcode 7.0+

##Instalation

###CocoaPods

[CocoaPods](https://cocoapods.org/) is a dependency manager for Cocoa projects. You can install it with the following command:

```bash
$ gem install cocoapods
```

To integrate RxMediaPicker into your Xcode project using CocoaPods, include this in your Podfile:

```ruby
platform :ios, '8.0'
use_frameworks!

pod 'RxMediaPicker'
```

### Carthage

[Carthage](https://github.com/Carthage/Carthage) is a decentralized dependency manager that builds your dependencies and provides you with binary frameworks.

You can install Carthage with [Homebrew](http://brew.sh/) using the following command:

```bash
$ brew update
$ brew install carthage
```

To integrate RxMediaPicker into your Xcode project using Carthage, specify it in your `Cartfile`:

```ogdl
github "RxSwiftCommunity/RxMediaPicker" "master"
```

Run `carthage` to build the framework and drag the built `RxMediaPicker.framework` into your Xcode project.

## Credits

Owned and maintained by Rui Costa ([@ruipfcosta](https://twitter.com/ruipfcosta)). 

## Contributing

Bug reports and pull requests are welcome.

## License

RxMediaPicker is released under the MIT license. See LICENSE for details.
