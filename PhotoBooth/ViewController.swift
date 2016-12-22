//
//  ViewController.swift
//  PhotoBooth
//
//  Created by Wasupol Tungsakultong on 10/13/2559 BE.
//  Copyright © 2559 Wasupol Tungsakultong. All rights reserved.
//

import UIKit
import LLSimpleCamera
import AVFoundation
import Photos
import YYImage
import LxFTPRequest
//import AssetsLibrary
import JGProgressHUD

let ftpUsername = "snapshotapp"
let ftpPassword = "Pipo1234!"
let ftpURL = "ftp://ftp.theblacklist2017.com"
var cameraSetting = "Front"

class ViewController: UIViewController, /*GRRequestsManagerDelegate*/UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var backgroundImageView: UIImageView!
//    @IBOutlet weak var artworkTextTest: UILabel!
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var pickedImageButton: UIButton!
    @IBOutlet weak var cameraSelectorButton: UIButton!
    
    @IBOutlet var subView: UIView!
    @IBOutlet weak var countdownLabel: UILabel!
    @IBOutlet weak var finishLabel: UILabel!
    
    @IBOutlet weak var blackframeImageView: UIImageView!
    private var previewViewController: LLSimpleCamera?
    private var myTimer: Timer?
    private var time = 5
    private var imageToUploads: [PHImage] = []
    private var path: String!
    
    private var webpEncoder: YYImageEncoder!
    private var imagePickerViewController: UIImagePickerController?
    private var hud: JGProgressHUD?
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    deinit {
        myTimer?.invalidate()
        self.myTimer = nil
        
        self.removeAllImages()
        self.resetUICamera()
        self.imageToUploads.removeAll()
        if webpEncoder != nil {
            self.webpEncoder = nil
        }
        if imagePickerViewController != nil {
            self.imagePickerViewController = nil
        }
        if self.path != nil {
            self.path = nil
        }
        if hud != nil {
            self.hud?.dismiss()
            self.hud = nil
        }
        //remove observer
        NotificationCenter.default.removeObserver(self)
    }
    
    @IBAction func cameraSelectorAction(_ sender: Any) {
        if cameraSelectorButton.titleLabel?.text == "Front" {
            cameraSelectorButton.setTitle("Rear", for: UIControlState.normal)
            cameraSetting = "Rear"
        }
        else if cameraSelectorButton.titleLabel?.text == "Rear" {
            cameraSelectorButton.setTitle("Front", for: UIControlState.normal)
            cameraSetting = "Front"
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.pickedImageButton.isHidden = true
        self.backgroundImageView.isHidden = false
        self.hud = JGProgressHUD(style: .dark)
        self.hud?.textLabel.text = "Processing..."
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.applicationDidEnterBackground(_:)), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.applicationWillEnterForeground(_:)), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
    }
    
    func applicationDidEnterBackground(_ notification: Notification) {
        //home button pressed
        self.myTimer?.invalidate()
        self.myTimer = nil
        self.hud?.dismiss()
        self.hud = nil
        self.removeAllImages()
        self.resetUICamera()
        self.finishLabel.isHidden = true
    }
    
    func applicationWillEnterForeground(_ notification: Notification) {
        // from the background to the active state
        // relabel start
        self.startButton.setTitle("Start", for: .normal)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        if let previewViewController = self.previewViewController {
            previewViewController.view.removeFromSuperview()
            previewViewController.removeFromParentViewController()
//            var squareSizeWidth: CGFloat = 0
//            if size.width > size.height {
//                squareSizeWidth = size.height
//            } else {
//                squareSizeWidth = size.width
//            }
//            let squareSize = CGSize(width: squareSizeWidth, height: squareSizeWidth)
            
            var screenRect = self.view.bounds
            screenRect.origin.y += self.topLayoutGuide.length
            print("Y:\(screenRect.origin.y) X: \(screenRect.origin.x)")
            self.attachCameraAndStart(shouldStart: false, rect: screenRect)
            
        }
        self.view.bringSubview(toFront: backgroundImageView)
        self.view.bringSubview(toFront: blackframeImageView)
        self.view.bringSubview(toFront: finishLabel)
        self.view.bringSubview(toFront: countdownLabel)
        self.view.bringSubview(toFront: startButton)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated
        myTimer?.invalidate()
        self.myTimer = nil
        self.resetUICamera()
        self.removeAllImages()
    }
    
    @IBAction func pickImageWatermark(_ sender: UIButton) {
        let imagePickerController = UIImagePickerController()
        imagePickerController.delegate = self
        imagePickerController.sourceType = .photoLibrary
        self.imagePickerViewController = imagePickerController
        self.present(self.imagePickerViewController!, animated: true, completion: nil)
    }

    @IBAction func startTouchUpInside(_ sender: AnyObject) {
        if let senderButton = sender as? UIButton {
            if startButton == senderButton {
                if senderButton.titleLabel?.text == "Done" {
                    self.finishLabel.isHidden = true
                    self.startButton.setTitle("Start", for: .normal)
                    //show artwork
                } else {
                    //restart
                    var screenRect = self.view.bounds
                    print(self.view.bounds)
                    print(self.topLayoutGuide.length)
                    screenRect.origin.y += self.topLayoutGuide.length
                    // let squareRect = CGRect(x: 0, y: 0, width: screenRect.width, height: screenRect.width)
                    attachCameraAndStart(shouldStart: true, rect: screenRect)
                    startButton.isHidden = true
                    // pickedImageButton.isHidden = true
                    backgroundImageView.isHidden = true
                    blackframeImageView.isHidden = false
                    cameraSelectorButton.isHidden = true
                    // blackframeImageView.isHidden = true
                    countdownLabel.isHidden = false
                    finishLabel.isHidden = true
                    self.myTimer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(updateLabel(timer:)), userInfo: nil, repeats: false)
                }
            }
        }
    }
    
    func updateLabel(timer: Timer) {
        countdownLabel.text = "\(time)"
        time = time - 1
        if time == 0 {
            myTimer?.invalidate()
            self.myTimer = nil
            self.perform(#selector(resetTimer), with: nil, afterDelay: 1.0)
        } else {
            self.myTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateLabel(timer:)), userInfo: nil, repeats: false)
        }
    }
    
    func resetTimer() {
        // capture screen instead of take photo
        // var image :UIImage = self.subView.capture()
        //no error
        // let phImg = PHImage(image: image)
        // self.imageToUploads.append(phImg)
        // if self.imageToUploads.count < 5
        // {
        // continue
        // self.time = 5
        // self.startButton.isHidden = true
        // self.artworkTextTest.isHidden = true
        // self.pickedImageButton.isHidden = true
        // self.blackframeImageView.isHidden = false
        // self.countdownLabel.isHidden = false
        // self.countdownLabel.text = "5"
        // self.myTimer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector:
        // #selector(self.updateLabel(timer:)), userInfo: nil, repeats: false)
        // }
        // else
        // {
        // 5 images upload and reset
        // self.hud?.show(in: self.view)
        // var settings = RenderSettings()
        // let firstImage = self.imageToUploads.first!
        // settings.width = firstImage.adjustedImage.size.width
        // settings.height = firstImage.adjustedImage.size.height
        // settings.fps = 2
        // let imageAnimator = ImageAnimator(renderSettings: settings, images: self.imageToUploads)
        // imageAnimator.render()
        // {
        // self.ftpUploadVideofile(imageAnimator: imageAnimator)
        // }
        // }
    self.previewViewController?.capture({ (camera, image, metadata, error) in
            if error != nil {
                self.resetUICamera()
            } else {
                //no error
                if let imageRaw = image {
                    let cropImage = self.cropBottomImage(image: imageRaw)
                    let phImage = PHImage(image: cropImage)
                    //Resize before append to watermardks (frame)
//                    let phImage = PHImage(image: self.resizeImage(image: imageRaw, width:0 , height: 1280, isScale: true))
//                    let phImage = PHImage(image: imageRaw.resizeWith(percentage: 0.3)!)
//                    let phImage = PHImage(image: self.resizeImage(image: imageRaw, width:960 , height: 1280, isScale: false))
                    self.imageToUploads.append(phImage)
                    if self.imageToUploads.count < 5 {
                        // continue
                        self.time = 5
                        self.startButton.isHidden = true
//                        self.artworkTextTest.isHidden = true
//                        self.pickedImageButton.isHidden = true
                        self.blackframeImageView.isHidden = false
                        self.countdownLabel.isHidden = false
                        self.countdownLabel.text = "5"
                        self.myTimer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector:
                            #selector(self.updateLabel(timer:)), userInfo: nil, repeats: false)
                    }
                    else {
                        // 5 images upload and reset
                        self.hud?.show(in: self.view)
                        var settings = RenderSettings()
                        let firstImage = self.imageToUploads.first!
                        settings.width = firstImage.adjustedImage.size.width
                        settings.height = firstImage.adjustedImage.size.height
                        settings.fps = 2
                        let imageAnimator = ImageAnimator(renderSettings: settings, images: self.imageToUploads)
                        imageAnimator.render()
                            {
                            self.ftpUploadVideofile(imageAnimator: imageAnimator)
                            }
                    }
                }
            }
        }, exactSeenImage: true)
    }
    
    func saveImageToPhotosAlbum() {
//        for imageCapture in imageToUploads {
        for (_, value) in imageToUploads.enumerated() {
            print("Save Image to photo album Size:")
            print(value.adjustedImage.size)
            UIImageWriteToSavedPhotosAlbum(value.adjustedImage, self, #selector(saveImage(_:didFinishSavingWithError:contextInfo:)), nil)
            sleep(1)
        }
//        let library = ALAssetsLibrary()
//        let queue = DispatchQueue(label: "co.uniqorn.PhotoBooth.saveToCameraRoll")
//        for (index, value) in imageToUploads.enumerated() {
//            queue.async {
//                let sema = DispatchSemaphore(value: 0)
//                library.writeImage(toSavedPhotosAlbum: value.originalImage.cgImage!, metadata: <#T##[AnyHashable : Any]!#>, completionBlock: <#T##ALAssetsLibraryWriteImageCompletionBlock!##ALAssetsLibraryWriteImageCompletionBlock!##(URL?, Error?) -> Void#>)
//            }
//        }
    }
    
    func ftpUploadVideofile(imageAnimator: ImageAnimator) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "YYYYMMdd_HHmmss"
        self.path = dateFormatter.string(from: Date())
        guard let realPath = path else {
            return
        }
        let filePath = "/\(realPath)" + ".\(imageAnimator.settings.videoFilenameExt)"
        self.ftpCreateDirectory(path: "/\(realPath)/", completion: {
            (request, success) in
            if success {
                self.ftpCreateFilePath(filePath: filePath, completion: { (request, success) in
                    if success {
                        self.ftpUploadFile(localFileURL: imageAnimator.settings.outputURL, filePath: filePath, completion: { (request, success) in
                            if success {
                                self.exportGifFile(path: realPath)
                            }
                        })
                    }
                })
            } else {
                //can't create folder
                //retry them
                self.hud?.dismiss()
                let alertController = UIAlertController(title: "Error", message: "Something goes wrong, Please try again.", preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: "Retry", style: .default, handler: { (_) in
                    self.hud?.show(in: self.view)
                    self.ftpUploadVideofile(imageAnimator: imageAnimator)
                }))
                self.present(alertController, animated: true, completion: nil)
            }
        })
//        requestsManager.addRequestForCreateDirectory(atPath: path)
//        self.videoRequest = requestsManager.addRequestForUploadFile(atLocalPath: imageAnimator.settings.outputURL.path, toRemotePath: filePath)
//        requestsManager.startProcessingRequests()
    }
    
    func ftpUploadImagefiles(path: String) {
        for (index, value) in imageToUploads.enumerated()
        {
            let image = value.adjustedImage
            let fileURL = self.fileImages(index + 1)
            // Save image to Document directory
            // Image quality
            if let imageRawData = UIImageJPEGRepresentation(image!, 1.0)
            {
                let success = FileManager.default.createFile(atPath: fileURL.path, contents: imageRawData, attributes: nil)
                if success
                {
                    let filePath = "/\(path)/jpg-\(index + 1).jpg"
                    self.ftpCreateFilePath(filePath: filePath, completion: { (request, success) in
                        if success
                        {
                            self.ftpUploadFile(localFileURL: fileURL, filePath: filePath, completion: { (request, success) in
                                if success
                                {
                                    if index == self.imageToUploads.count - 1
                                    {
                                        DispatchQueue.main.async {
                                            self.hud?.dismiss()
                                            self.saveImageToPhotosAlbum()
                                            self.removeAllImages()
                                            self.resetUICamera()
                                        }
                                    }
                                }
                            })
                        }
                    })
                }
            }
        }
    }
    
    func removeAllTempFiles() {
        ImageAnimator.removeFileAtURL(fileURL: self.gifFileImage())
        for i in 1 ... 5 {
            ImageAnimator.removeFileAtURL(fileURL: self.fileImages(i))
        }
    }
    
    func exportGifFile(path: String) {
        removeAllTempFiles()
        if webpEncoder != nil {
            self.webpEncoder = nil
        }
        self.webpEncoder = YYImageEncoder(type: .GIF)
        webpEncoder.loopCount = 5
        for (_, value) in imageToUploads.enumerated() {
            let image = value.adjustedImage
            if let imageResize = image!.resizeWith(percentage: 0.3) {
                webpEncoder.add(imageResize, duration: 0.3)
            } else {
                //resize fail
                webpEncoder.add(image!, duration: 0.5)
            }
        }
        let gifFileURL = self.gifFileImage()
        let success = webpEncoder.encode(toFile: gifFileURL.path)
        if success {
            let filePath = "/\(path).gif"
            self.ftpCreateFilePath(filePath: filePath, completion: { (request, success) in
                if success {
                    self.ftpUploadFile(localFileURL: gifFileURL, filePath: filePath, completion: { (request, success) in
                        if success {
                            self.ftpUploadImagefiles(path: path)
                        }
                    })
                }
            })
        } else {
            //gif fail upload others
            self.ftpUploadImagefiles(path: path)
            return
        }
    }

    func gifFileImage() -> URL {
        let fileManager = FileManager.default
        if let tmpDirURL = try? fileManager.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true) {
            return tmpDirURL.appendingPathComponent("animateGIF").appendingPathExtension("gif")
        }
        fatalError("URLForDirectory() failed")
    }
    
    func fileImages(_ index: Int) -> URL {
        // Use the CachesDirectory so the rendered video file sticks around as long as we need it to.
        // Using the CachesDirectory ensures the file won't be included in a backup of the app.
        let fileManager = FileManager.default
        if let tmpDirURL = try? fileManager.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true) {
            return tmpDirURL.appendingPathComponent("jpg-\(index)").appendingPathExtension("jpg")
        }
        fatalError("URLForDirectory() failed")
    }
    
    func saveImage(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        #if DEBUG
            if let errorData = error {
                let alertController = UIAlertController(title: "Error", message: errorData.localizedDescription, preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
                self.present(alertController, animated: true, completion: nil)
            }
        #endif
    }
    
    func removeAllImages() {
        if self.imageToUploads.count > 0 {
            self.imageToUploads.removeAll()
        }
    }
    
    private func attachCameraAndStart(shouldStart: Bool, rect: CGRect) {
        if rect == CGRect.zero {
            return
        }
        if self.previewViewController == nil {
            self.previewViewController?.cameraQuality = AVCaptureSessionPresetPhoto
            
            // Front and rear camera
            if cameraSetting == "Front" {
                // Front
                self.previewViewController = LLSimpleCamera(quality: AVCaptureSessionPresetPhoto, position: LLCameraPositionFront, videoEnabled: false)
            } else {
                // Rear
                self.previewViewController = LLSimpleCamera(quality: AVCaptureSessionPresetPhoto, position: LLCameraPositionRear, videoEnabled: false)
            }
            self.previewViewController?.fixOrientationAfterCapture = true
        }
        self.previewViewController!.attach(to: self, withFrame: rect)
        self.view.bringSubview(toFront: blackframeImageView)
        self.view.bringSubview(toFront: finishLabel)
        self.view.bringSubview(toFront: countdownLabel)
        self.view.bringSubview(toFront: startButton)
        // Add cameraSelectorButton to view
        self.view.bringSubview(toFront: cameraSelectorButton)
        if shouldStart {
            self.previewViewController!.start()
//            self.previewViewController?.attach(to: subView, withFrame: rect)
        }
    }
    
    func resetUICamera() {
        countdownLabel.text = "5"
        startButton.isHidden = false
//        artworkTextTest.isHidden = false
//        artworkTextTest.text = "img2"
//        pickedImageButton.isHidden = false
        backgroundImageView.isHidden = false
        blackframeImageView.isHidden = true
        cameraSelectorButton.isHidden = false
        countdownLabel.isHidden = true
        finishLabel.isHidden = false
        time = 5
        startButton.setTitle("Done", for: .normal)
        if let previewViewController =  previewViewController {
            previewViewController.stop()
            previewViewController.view.removeFromSuperview()
            previewViewController.removeFromParentViewController()
        }
        self.webpEncoder = nil
        self.previewViewController = nil
    }
    
    
    // MARK: - ImagePickerViewControllerDelegate
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        //cancel
        if picker == self.imagePickerViewController {
            picker.dismiss(animated: true, completion: nil)
            self.imagePickerViewController = nil
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        //picked
        if self.imagePickerViewController == picker {
            guard let imagePicked = info[UIImagePickerControllerOriginalImage] as? UIImage else {
                picker.dismiss(animated: true, completion: nil)
                self.imagePickerViewController = nil
                return
            }
            ImageManager.sharedInstance.setWaterMarkImage(imagePicked)
            picker.dismiss(animated: true, completion: {
                self.imagePickerViewController = nil
            })
        }
    }
    
    private func ftpCreateDirectory(path: String, completion: ((LxFTPRequest, Bool) -> Void)?) {
        let createDirectoryRequest = LxFTPRequest.createResource()
        createDirectoryRequest?.serverURL = URL(string: ftpURL.appending(path))
        createDirectoryRequest?.username = ftpUsername
        createDirectoryRequest?.password = ftpPassword
        createDirectoryRequest?.successAction = {
            (resultClass: AnyClass?, result: Any?) in
            completion?(createDirectoryRequest!, true)
        }
        createDirectoryRequest?.failAction = {
            (domain: CFStreamErrorDomain, error:Int, errorMessage: String?) in
            completion?(createDirectoryRequest!, false)
        }
        createDirectoryRequest?.start()
    }
    
    private func ftpCreateFilePath(filePath: String, completion: ((LxFTPRequest, Bool) -> Void)?) {
        let createDirectoryRequest = LxFTPRequest.createResource()
        createDirectoryRequest?.serverURL = URL(string: ftpURL.appending(filePath))
        createDirectoryRequest?.username = ftpUsername
        createDirectoryRequest?.password = ftpPassword
        createDirectoryRequest?.successAction = {
            (resultClass: AnyClass?, result: Any?) in
            completion?(createDirectoryRequest!, true)
        }
        createDirectoryRequest?.failAction = {
            (domain: CFStreamErrorDomain, error:Int, errorMessage: String?) in
            self.hud?.dismiss()
            //retry
            let alertController = UIAlertController(title: "Error", message: errorMessage, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "Retry", style: .default, handler: { (_) in
                self.hud?.show(in: self.view)
                createDirectoryRequest?.start()
            }))
            self.present(alertController, animated: true, completion: nil)
            completion?(createDirectoryRequest!, false)
        }
        createDirectoryRequest?.start()
    }
    
    private func ftpUploadFile(localFileURL: URL, filePath: String, completion: ((LxFTPRequest, Bool) -> Void)?) {
        let createDirectoryRequest = LxFTPRequest.upload()
        createDirectoryRequest?.serverURL = URL(string: ftpURL.appending(filePath))
        createDirectoryRequest?.localFileURL = localFileURL
        createDirectoryRequest?.username = ftpUsername
        createDirectoryRequest?.password = ftpPassword
        createDirectoryRequest?.successAction = {
            (resultClass: AnyClass?, result: Any?) in
            completion?(createDirectoryRequest!, true)
        }
        createDirectoryRequest?.failAction = {
            (domain: CFStreamErrorDomain, error:Int, errorMessage: String?) in
            self.hud?.dismiss()
            //retry
            let alertController = UIAlertController(title: "Error", message: errorMessage, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "Retry", style: .default, handler: { (_) in
                self.hud?.show(in: self.view)
                createDirectoryRequest?.start()
            }))
            self.present(alertController, animated: true, completion: nil)
            completion?(createDirectoryRequest!, false)
        }
        createDirectoryRequest?.start()
    }
    
//    private func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
//        //picked
//        if self.imagePickerViewController == picker {
//            guard let imagePicked = info[UIImagePickerControllerEditedImage] as? UIImage else {
//                picker.dismiss(animated: true, completion: nil)
//                self.imagePickerViewController = nil
//                return
//            }
//            ImageManager.sharedInstance.setWaterMarkImage(imagePicked)
//            picker.dismiss(animated: true, completion: { 
//                self.imagePickerViewController = nil
//            })
//        }
//    }
    /*
    * Resizing image with scale height
    * @param Image and new height
    * @return UIImage object with new size scale
    */
    func resizeImage(image: UIImage, width: CGFloat, height: CGFloat, isScale: Bool) -> UIImage {
        
        var newHeight: CGFloat
        var newWidth: CGFloat
        
        if isScale == true
        {
            // width scale
//            let scale: CGFloat = width / image.size.width
//            newHeight = image.size.height * scale
//            newWidth =  width
            // height scale
            let scale: CGFloat = height / image.size.height
            newWidth = image.size.width * scale
            newHeight = height
        }
        else
        {
            newHeight = height
            newWidth =  width
        }
        UIGraphicsBeginImageContext(CGSize(width: newWidth, height: newHeight))
        image.draw(in: CGRect(origin: CGPoint(x: 0,y :0), size: CGSize(width: newWidth, height: newHeight)))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
    }
    
//    func capture() {
//    
//    UIGraphicsBeginImageContext(self.view.bounds.size)
//    self.view.layer renderInContext:UIGraphicsGetCurrentContext()
//        var capturedImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()
//    UIGraphicsEndImageContext();
//    
//    //FINAL OUTPUT
//    self.imageView.image = capturedImage;
//    }
    
    func cropBottomImage(image: UIImage) -> UIImage {
//        let height = CGFloat(image.size.height / 3)
        let rect = CGRect(x: 0, y: 0, width: image.size.width, height: 1350)
        return cropImage(image: image, toRect: rect)
    }
    
    func cropImage(image:UIImage, toRect rect:CGRect) -> UIImage{
        let imageRef:CGImage = image.cgImage!.cropping(to: rect)!
        let croppedImage:UIImage = UIImage(cgImage:imageRef)
        return croppedImage
    }
    
    
}
extension UIView {
    
//    func capture(view: UIView) -> UIImage {
//        
//        UIGraphicsBeginImageContextWithOptions(view.frame.size, view.isOpaque, UIScreen.main.scale)
//        view.layer.render(in:UIGraphicsGetCurrentContext()!)
//        let image = UIGraphicsGetImageFromCurrentImageContext()
//        UIGraphicsEndImageContext()
//
//        return image!
//    }
    func capture() -> UIImage {
        
        UIGraphicsBeginImageContextWithOptions(self.frame.size, false, UIScreen.main.scale)
        self.layer.render(in:UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image!
    }
    
}
