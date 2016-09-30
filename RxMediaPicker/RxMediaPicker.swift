import Foundation
import MobileCoreServices
import RxSwift
import UIKit
import AVFoundation

enum RxMediaPickerAction {
    case photo(observer: AnyObserver<(UIImage, UIImage?)>)
    case video(observer: AnyObserver<NSURL>, maxDuration: NSTimeInterval)
}

public enum RxMediaPickerError: Error {
    case generalError
    case canceled
    case videoMaximumDurationExceeded
}

@objc public protocol RxMediaPickerDelegate {
    func presentPicker(_ picker: UIImagePickerController)
    func dismissPicker(_ picker: UIImagePickerController)
}

@objc open class RxMediaPicker: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    weak var delegate: RxMediaPickerDelegate?
    
    fileprivate var currentAction: RxMediaPickerAction?
    
    open var deviceHasCamera: Bool {
        return UIImagePickerController.isSourceTypeAvailable(.camera)
    }
    
    public init(delegate: RxMediaPickerDelegate) {
        self.delegate = delegate
    }
    
    open func recordVideo(device: UIImagePickerControllerCameraDevice = .Rear, quality: UIImagePickerControllerQualityType = .TypeMedium, maximumDuration: NSTimeInterval = 600, editable: Bool = false) -> Observable<NSURL> {
        
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
    
    open func selectVideo(_ source: UIImagePickerControllerSourceType = .PhotoLibrary, maximumDuration: NSTimeInterval = 600, editable: Bool = false) -> Observable<NSURL> {
        
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
    
    open func takePhoto(device: UIImagePickerControllerCameraDevice = .Rear, flashMode: UIImagePickerControllerCameraFlashMode = .Auto, editable: Bool = false) -> Observable<(UIImage, UIImage?)> {
        
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
    
    open func selectImage(_ source: UIImagePickerControllerSourceType = .PhotoLibrary, editable: Bool = false) -> Observable<(UIImage, UIImage?)> {
        
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
    
    func processPhoto(_ info: [String : AnyObject], observer: AnyObserver<(UIImage, UIImage?)>) {
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            let editedImage: UIImage? = info[UIImagePickerControllerEditedImage] as? UIImage
            observer.on(.Next(image, editedImage))
            observer.on(.Completed)
        } else {
            observer.on(.Error(RxMediaPickerError.GeneralError))
        }
    }
    
    func processVideo(_ info: [String : AnyObject], observer: AnyObserver<NSURL>, maxDuration: TimeInterval, picker: UIImagePickerController) {
        
        guard let videoURL = info[UIImagePickerControllerMediaURL] as? URL else {
            observer.on(.Error(RxMediaPickerError.GeneralError))
            dismissPicker(picker)
            return
        }
        
        if let editedStart = info["_UIImagePickerControllerVideoEditingStart"] as? NSNumber,
            let editedEnd = info["_UIImagePickerControllerVideoEditingEnd"] as? NSNumber {
                
                let start = Int64(editedStart.doubleValue * 1000)
                let end = Int64(editedEnd.doubleValue * 1000)
                let cachesDirectory = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first!
                let editedVideoURL = URL(fileURLWithPath: cachesDirectory).appendingPathComponent("\(UUID().uuidString).mov", isDirectory: false)
                let asset = AVURLAsset(url: videoURL)
                
                if let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality) {
                    exportSession.outputURL = editedVideoURL
                    exportSession.outputFileType = AVFileTypeQuickTimeMovie
                    exportSession.timeRange = CMTimeRange(start: CMTime(value: start, timescale: 1000), duration: CMTime(value: end - start, timescale: 1000))
                    
                    exportSession.exportAsynchronously(completionHandler: {
                        switch exportSession.status {
                        case .completed:
                            self.processVideoURL(editedVideoURL, observer: observer, maxDuration: maxDuration, picker: picker)
                        case .failed: fallthrough
                        case .cancelled:
                            observer.on(.Error(RxMediaPickerError.GeneralError))
                            self.dismissPicker(picker)
                        default: break
                        }
                    })
                }
        } else {
            processVideoURL(videoURL, observer: observer, maxDuration: maxDuration, picker: picker)
        }
    }
    
    fileprivate func processVideoURL(_ url: URL, observer: AnyObserver<NSURL>, maxDuration: TimeInterval, picker: UIImagePickerController) {
        
        let asset = AVURLAsset(url: url)
        let duration = CMTimeGetSeconds(asset.duration)
        
        if duration > maxDuration {
            observer.on(.Error(RxMediaPickerError.VideoMaximumDurationExceeded))
        } else {
            observer.on(.Next(url))
            observer.on(.Completed)
        }
        
        dismissPicker(picker)
    }
    
    fileprivate func dismissPicker(_ picker: UIImagePickerController) {
        delegate?.dismissPicker(picker)
    }
    
    // UIImagePickerControllerDelegate
    
    open func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        if let action = currentAction {
            switch action {
            case .Photo(let observer):
                processPhoto(info, observer: observer)
                dismissPicker(picker)
            case .Video(let observer, let maxDuration):
                processVideo(info, observer: observer, maxDuration: maxDuration, picker: picker)
            }
        }
    }
    
    open func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismissPicker(picker)
        
        if let action = currentAction {
            switch action {
            case .Photo(let observer):      observer.on(.Error(RxMediaPickerError.Canceled))
            case .Video(let observer, _):   observer.on(.Error(RxMediaPickerError.Canceled))
            }
        }
    }
}
