import Foundation
import MobileCoreServices
import RxSwift
import UIKit
import AVFoundation

enum RxMediaPickerAction {
    case photo(observer: AnyObserver<(UIImage, UIImage?)>)
    case video(observer: AnyObserver<URL>, maxDuration: TimeInterval)
}

public enum RxMediaPickerError: Error {
    case generalError
    case canceled
    case videoMaximumDurationExceeded
}

@objc public protocol RxMediaPickerDelegate {
    func present(picker: UIImagePickerController)
    func dismiss(picker: UIImagePickerController)
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
    
    open func recordVideo(device: UIImagePickerControllerCameraDevice = .rear, quality: UIImagePickerControllerQualityType = .typeMedium, maximumDuration: TimeInterval = 600, editable: Bool = false) -> Observable<URL> {
        
        return Observable.create { observer in
            self.currentAction = RxMediaPickerAction.video(observer: observer, maxDuration: maximumDuration)
            
            let picker = UIImagePickerController()
            picker.sourceType = .camera
            picker.mediaTypes = [kUTTypeMovie as String]
            picker.videoMaximumDuration = maximumDuration
            picker.videoQuality = quality
            picker.allowsEditing = editable
            picker.delegate = self
            
            if UIImagePickerController.isCameraDeviceAvailable(device) {
                picker.cameraDevice = device
            }
            
            self.delegate?.present(picker: picker)
            
            return Disposables.create()
        }
    }
    
    open func selectVideo(source: UIImagePickerControllerSourceType = .photoLibrary, maximumDuration: TimeInterval = 600, editable: Bool = false) -> Observable<URL> {
        
        return Observable.create({ observer in
            self.currentAction = RxMediaPickerAction.video(observer: observer, maxDuration: maximumDuration)
            
            let picker = UIImagePickerController()
            picker.sourceType = source
            picker.mediaTypes = [kUTTypeMovie as String]
            picker.allowsEditing = editable
            picker.delegate = self
            
            self.delegate?.present(picker: picker)
            
            return Disposables.create()
        })
    }
    
    open func takePhoto(device: UIImagePickerControllerCameraDevice = .rear, flashMode: UIImagePickerControllerCameraFlashMode = .auto, editable: Bool = false) -> Observable<(UIImage, UIImage?)> {
        
        return Observable.create({ observer in
            self.currentAction = RxMediaPickerAction.photo(observer: observer)
            
            let picker = UIImagePickerController()
            picker.sourceType = .camera
            picker.allowsEditing = editable
            picker.delegate = self
            
            if UIImagePickerController.isCameraDeviceAvailable(device) {
                picker.cameraDevice = device
            }
            
            if UIImagePickerController.isFlashAvailable(for: picker.cameraDevice) {
                picker.cameraFlashMode = flashMode
            }
            
            self.delegate?.present(picker: picker)
            
            return Disposables.create()
        })
    }
    
    open func selectImage(source: UIImagePickerControllerSourceType = .photoLibrary, editable: Bool = false) -> Observable<(UIImage, UIImage?)> {
        
        return Observable.create { observer in
            self.currentAction = RxMediaPickerAction.photo(observer: observer)
            
            let picker = UIImagePickerController()
            picker.sourceType = source
            picker.allowsEditing = editable
            picker.delegate = self
            
            self.delegate?.present(picker: picker)
            
            return Disposables.create()
        }
    }
    
    func processPhoto(info: [String : AnyObject], observer: AnyObserver<(UIImage, UIImage?)>) {
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            let editedImage: UIImage? = info[UIImagePickerControllerEditedImage] as? UIImage
            observer.on(.next(image, editedImage))
            observer.on(.completed)
        } else {
            observer.on(.error(RxMediaPickerError.generalError))
        }
    }
    
    func processVideo(info: [String : Any], observer: AnyObserver<URL>, maxDuration: TimeInterval, picker: UIImagePickerController) {
        
        guard let videoURL = info[UIImagePickerControllerMediaURL] as? URL else {
            observer.on(.error(RxMediaPickerError.generalError))
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
                            self.processVideo(url: editedVideoURL, observer: observer, maxDuration: maxDuration, picker: picker)
                        case .failed: fallthrough
                        case .cancelled:
                            observer.on(.error(RxMediaPickerError.generalError))
                            self.dismissPicker(picker)
                        default: break
                        }
                    })
                }
        } else {
            processVideo(url: videoURL, observer: observer, maxDuration: maxDuration, picker: picker)
        }
    }
    
    fileprivate func processVideo(url: URL, observer: AnyObserver<URL>, maxDuration: TimeInterval, picker: UIImagePickerController) {
        
        let asset = AVURLAsset(url: url)
        let duration = CMTimeGetSeconds(asset.duration)
        
        if duration > maxDuration {
            observer.on(.error(RxMediaPickerError.videoMaximumDurationExceeded))
        } else {
            observer.on(.next(url))
            observer.on(.completed)
        }
        
        dismissPicker(picker)
    }
    
    fileprivate func dismissPicker(_ picker: UIImagePickerController) {
        delegate?.dismiss(picker: picker)
    }
    
    // UIImagePickerControllerDelegate
    
    open func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        if let action = currentAction {
            switch action {
            case .photo(let observer):
                processPhoto(info: info as [String : AnyObject], observer: observer)
                dismissPicker(picker)
            case .video(let observer, let maxDuration):
                processVideo(info: info, observer: observer, maxDuration: maxDuration, picker: picker)
            }
        }
    }
    
    open func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismissPicker(picker)
        
        if let action = currentAction {
            switch action {
            case .photo(let observer):      observer.on(.error(RxMediaPickerError.canceled))
            case .video(let observer, _):   observer.on(.error(RxMediaPickerError.canceled))
            }
        }
    }
}
