import UIKit
import RxSwift
import RxMediaPicker
import MediaPlayer

class ViewController: UIViewController, RxMediaPickerDelegate {
    
    var picker: RxMediaPicker!
    var moviePlayer: MPMoviePlayerController!
    let disposeBag = DisposeBag()
    
    lazy var buttonPhoto: UIButton  = self.makeButton("Pick photo", target: self, action: "pickPhoto")
    lazy var buttonVideo: UIButton  = self.makeButton("Record video", target: self, action: "recordVideo")
    lazy var container: UIView      = self.makeContainer()
    
    override func loadView() {
        super.loadView()
        
        view.addSubview(buttonPhoto)
        view.addSubview(buttonVideo)
        view.addSubview(container)
        
        let views = ["buttonPhoto": buttonPhoto, "buttonVideo": buttonVideo, "container": container]
        
        var constraints = NSLayoutConstraint.constraintsWithVisualFormat("V:|-50-[buttonPhoto]-20-[buttonVideo]-20-[container(==200)]", options: NSLayoutFormatOptions(rawValue: 0), metrics: .None, views: views)
        constraints += NSLayoutConstraint.constraintsWithVisualFormat("H:[container(==200)]", options: NSLayoutFormatOptions(rawValue: 0), metrics: .None, views: views)
        
        constraints.append(NSLayoutConstraint(item: buttonPhoto, attribute: .CenterX, relatedBy: .Equal, toItem: view, attribute: .CenterX, multiplier: 1, constant: 0))
        constraints.append(NSLayoutConstraint(item: buttonVideo, attribute: .CenterX, relatedBy: .Equal, toItem: view, attribute: .CenterX, multiplier: 1, constant: 0))
        constraints.append(NSLayoutConstraint(item: container, attribute: .CenterX, relatedBy: .Equal, toItem: view, attribute: .CenterX, multiplier: 1, constant: 0))
        
        NSLayoutConstraint.activateConstraints(constraints)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        picker = RxMediaPicker(delegate: self)
    }
    
    func makeButton(title: String, target: AnyObject, action: Selector) -> UIButton {
        let b = UIButton()
        b.translatesAutoresizingMaskIntoConstraints = false
        b.setTitle(title, forState: .Normal)
        b.addTarget(target, action: action, forControlEvents: .TouchUpInside)
        b.setTitleColor(UIColor.blueColor(), forState: .Normal)
        
        return b
    }
    
    func makeContainer() -> UIView {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = UIColor.blackColor()
        
        return v
    }
    
    func removeAllSubviews() {
        for subview in container.subviews {
            subview.removeFromSuperview()
        }
    }
    
    func pickPhoto() {
        picker.selectImage(editable: true)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { (image, editedImage) in
                let imageView = UIImageView(frame: self.container.bounds)
                imageView.image = editedImage ?? image
                
                self.removeAllSubviews()
                self.container.addSubview(imageView)
            }, onError: { error in
                print("Got an error")
            }, onCompleted: {
                print("Completed")
            }, onDisposed: {
                print("Disposed")
            })
            .addDisposableTo(disposeBag)
    }
        
    func recordVideo() {
        #if (arch(i386) || arch(x86_64))
            let alert = UIAlertController(title: "Error - Simulator", message: "Video recording not available on the simulator", preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: .None))
            presentViewController(alert, animated: true, completion: .None)
            return
        #endif
        
        picker.selectVideo(.Camera, maximumDuration: 10, editable: true)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: processUrl
            , onError: { error in
                print("Got an error")
            }, onCompleted: {
                print("Completed")
            }, onDisposed: {
                print("Disposed")
            })
            .addDisposableTo(disposeBag)
    }
    
    func processUrl(url: NSURL) {
        moviePlayer = MPMoviePlayerController(contentURL: url)
        
        removeAllSubviews()
        moviePlayer.view.frame = container.bounds
        container.addSubview(moviePlayer.view)
        
        moviePlayer.prepareToPlay()
        moviePlayer.play()
    }

    // RxMediaPickerDelegate
    
    func presentPicker(picker: UIImagePickerController) {
        print("Will present picker")
        presentViewController(picker, animated: true, completion: .None)
    }
    
    func dismissPicker(picker: UIImagePickerController) {
        print("Will dismiss picker")
        dismissViewControllerAnimated(true, completion: .None)
    }
    
}
