import UIKit
import RxSwift
import RxMediaPicker
import MediaPlayer

class ViewController: UIViewController, RxMediaPickerDelegate {
    
    var picker: RxMediaPicker!
    var moviePlayer: MPMoviePlayerController!
    let disposeBag = DisposeBag()
    
    lazy var buttonPhoto: UIButton  = self.makeButton(title: "Pick photo", target: self, action: #selector(ViewController.pickPhoto))
    lazy var buttonVideo: UIButton  = self.makeButton(title: "Record video", target: self, action: #selector(ViewController.recordVideo))
    lazy var container: UIView      = self.makeContainer()
    
    override func loadView() {
        super.loadView()

        view.addSubview(buttonPhoto)
        view.addSubview(buttonVideo)
        view.addSubview(container)
        
        let views = ["buttonPhoto": buttonPhoto, "buttonVideo": buttonVideo, "container": container]

        var constraints = NSLayoutConstraint.constraints(withVisualFormat: "V:|-50-[buttonPhoto]-20-[buttonVideo]-20-[container(==200)]", options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: .none, views: views)

        constraints += NSLayoutConstraint.constraints(withVisualFormat: "H:[container(==200)]", options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: .none, views: views)
        
        constraints.append(NSLayoutConstraint(item: buttonPhoto, attribute: .centerX, relatedBy: .equal, toItem: view, attribute: .centerX, multiplier: 1, constant: 0))
        constraints.append(NSLayoutConstraint(item: buttonVideo, attribute: .centerX, relatedBy: .equal, toItem: view, attribute: .centerX, multiplier: 1, constant: 0))
        constraints.append(NSLayoutConstraint(item: container, attribute: .centerX, relatedBy: .equal, toItem: view, attribute: .centerX, multiplier: 1, constant: 0))
        
        NSLayoutConstraint.activate(constraints)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        picker = RxMediaPicker(delegate: self)
    }
    
    func makeButton(title: String, target: AnyObject, action: Selector) -> UIButton {
        let b = UIButton()
        b.translatesAutoresizingMaskIntoConstraints = false
        b.setTitle(title, for: .normal)
        b.addTarget(target, action: action, for: .touchUpInside)
        b.setTitleColor(.blue, for: .normal)
        
        return b
    }
    
    func makeContainer() -> UIView {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = .black
        
        return v
    }
    
    func removeAllSubviews() {
        for subview in container.subviews {
            subview.removeFromSuperview()
        }
    }
    
    @objc func pickPhoto() {
        picker.selectImage(editable: true)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { (image, editedImage) in
                let imageView = UIImageView(frame: self.container.bounds)
                imageView.image = editedImage ?? image
                
                self.removeAllSubviews()
                self.container.addSubview(imageView)
            }, onError: { error in
                print("Picker photo error: \(error)")
            }, onCompleted: {
                print("Completed")
            }, onDisposed: {
                print("Disposed")
            })
            .disposed(by: disposeBag)
    }
        
    @objc func recordVideo() {
        #if (arch(i386) || arch(x86_64))
            let alert = UIAlertController(title: "Error - Simulator", message: "Video recording not available on the simulator", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: .none))
            present(alert, animated: true, completion: nil)
            return
        #endif
        
        picker.selectVideo(source: .camera, maximumDuration: 10, editable: true)
              .observeOn(MainScheduler.instance)
              .subscribe(onNext: processUrl,
                         onError: { error in
                            print("Record video error \(error)")
                         },
                         onCompleted: {
                            print("Completed")
                         },
                         onDisposed: {
                            print("Disposed")
                         })
              .disposed(by: disposeBag)
    }
    
    func processUrl(url: URL) {
        moviePlayer = MPMoviePlayerController(contentURL: url)
        
        removeAllSubviews()
        moviePlayer.view.frame = container.bounds
        container.addSubview(moviePlayer.view)
        
        moviePlayer.prepareToPlay()
        moviePlayer.play()
    }

    // RxMediaPickerDelegate
    func present(picker: UIImagePickerController) {
        if moviePlayer != nil, moviePlayer.playbackState == .playing {
            moviePlayer.stop()
        }

        print("Will present picker")
        present(picker, animated: true, completion: nil)
    }

    func dismiss(picker: UIImagePickerController) {
        print("Will dismiss picker")
        dismiss(animated: true, completion: nil)
    }
}
