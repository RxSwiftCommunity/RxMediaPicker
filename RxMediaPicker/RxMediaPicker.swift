import Foundation
import MobileCoreServices
import RxSwift
import UIKit
import AVFoundation

enum RxMediaPickerAction {
    case Photo(observer: AnyObserver<(UIImage, UIImage?)>)
    case Video(observer: AnyObserver<NSURL>, maxDuration: NSTimeInterval)
}

public enum RxMediaPickerError: ErrorType {
    case GeneralError
    case Canceled
    case VideoMaximumDurationExceeded
}

@objc public protocol RxMediaPickerDelegate {
    func presentPicker(picker: UIImagePickerController)
    func dismissPicker(picker: UIImagePickerController)
}

@objc public class RxMediaPicker: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    weak var delegate: RxMediaPickerDelegate?
    
    private var currentAction: RxMediaPickerAction?
    
    var deviceHasCamera: Bool {
        return UIImagePickerController.isSourceTypeAvailable(.Camera)
    }
    
    public init(delegate: RxMediaPickerDelegate) {
        self.delegate = delegate
    }
    
    public func recordVideo(device device: UIImagePickerControllerCameraDevice = .Rear, quality: UIImagePickerControllerQualityType = .TypeMedium, maximumDuration: NSTimeInterval = 600, editable: Bool = false) -> Observable<NSURL> {
        
        return Observable.create { observer in
            self.currentAction = RxMediaPickerAction.Video(observer: observer, maxDuration: maximumDuration)
            
            let picker = UIImagePickerController()
            picker.sourceType = .Camera
            picker.mediaTypes = [kUTTypeMovie as String]
            picker.videoMaximumDuration = maximumDuration
            picker.videoQuality = quality
            picker.allowsEditing = editable
            picker.delegate = self
            
            if UIImagePickerController.isCameraDeviceAvailable(device) {
                picker.cameraDevice = device
            }
            
            self.delegate?.presentPicker(picker)
            
            return NopDisposable.instance
        }
    }
    
    public func selectVideo(source: UIImagePickerControllerSourceType = .PhotoLibrary, maximumDuration: NSTimeInterval = 600, editable: Bool = false) -> Observable<NSURL> {
        
        return Observable.create({ observer in
            self.currentAction = RxMediaPickerAction.Video(observer: observer, maxDuration: maximumDuration)
            
            let picker = UIImagePickerController()
            picker.sourceType = source
            picker.mediaTypes = [kUTTypeMovie as String]
            picker.allowsEditing = editable
            picker.delegate = self
            
            self.delegate?.presentPicker(picker)
            
            return NopDisposable.instance
        })
    }
    
    public func takePhoto(device device: UIImagePickerControllerCameraDevice = .Rear, flashMode: UIImagePickerControllerCameraFlashMode = .Auto, editable: Bool = false) -> Observable<(UIImage, UIImage?)> {
        
        return Observable.create({ observer in
            self.currentAction = RxMediaPickerAction.Photo(observer: observer)
            
            let picker = UIImagePickerController()
            picker.sourceType = .Camera
            picker.allowsEditing = editable
            picker.delegate = self
            
            if UIImagePickerController.isCameraDeviceAvailable(device) {
                picker.cameraDevice = device
            }
            
            if UIImagePickerController.isFlashAvailableForCameraDevice(picker.cameraDevice) {
                picker.cameraFlashMode = flashMode
            }
            
            self.delegate?.presentPicker(picker)
            
            return NopDisposable.instance
        })
    }
    
    public func selectImage(source: UIImagePickerControllerSourceType = .PhotoLibrary, editable: Bool = false) -> Observable<(UIImage, UIImage?)> {
        
        return Observable.create { observer in
            self.currentAction = RxMediaPickerAction.Photo(observer: observer)
            
            let picker = UIImagePickerController()
            picker.sourceType = source
            picker.allowsEditing = editable
            picker.delegate = self
            
            self.delegate?.presentPicker(picker)
            
            return NopDisposable.instance
        }
    }
    
    func processPhoto(info: [String : AnyObject], observer: AnyObserver<(UIImage, UIImage?)>) {
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            let editedImage: UIImage? = info[UIImagePickerControllerEditedImage] as? UIImage
            observer.on(.Next(image, editedImage))
            observer.on(.Completed)
        } else {
            observer.on(.Error(RxMediaPickerError.GeneralError))
        }
    }
    
    func processVideo(info: [String : AnyObject], observer: AnyObserver<NSURL>, maxDuration: NSTimeInterval) {
        if let videoUrl = info[UIImagePickerControllerMediaURL] as? NSURL {
            let asset = AVURLAsset(URL: videoUrl)
            let duration = CMTimeGetSeconds(asset.duration)
            
            if duration > maxDuration {
                observer.on(.Error(RxMediaPickerError.VideoMaximumDurationExceeded))
            } else {
                observer.on(.Next(videoUrl))
                observer.on(.Completed)
            }
        } else {
            observer.on(.Error(RxMediaPickerError.GeneralError))
        }
    }
    
    // UIImagePickerControllerDelegate
    
    public func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        delegate?.dismissPicker(picker)
        
        if let action = currentAction {
            switch action {
            case .Photo(let observer):                  processPhoto(info, observer: observer)
            case .Video(let observer, let maxDuration): processVideo(info, observer: observer, maxDuration: maxDuration)
            }
        }
    }
    
    public func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        delegate?.dismissPicker(picker)
        
        if let action = currentAction {
            switch action {
            case .Photo(let observer):      observer.on(.Error(RxMediaPickerError.Canceled))
            case .Video(let observer, _):   observer.on(.Error(RxMediaPickerError.Canceled))
            }
        }
    }
}
