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
import GoldRaccoon
import YYImage
//import AssetsLibrary

let ftpUsername = "snapshotapp"
let ftpPassword = "Pipo1234!"
let ftpURL = "ftp.theblacklist2017.com"

class ViewController: UIViewController, GRRequestsManagerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var pickedImageButton: UIButton!
    @IBOutlet weak var countdownLabel: UILabel!
    @IBOutlet weak var finishLabel: UILabel!
    
    private var previewViewController: LLSimpleCamera?
    private var myTimer: Timer?
    private var time = 5
    private var imageToUploads: [PHImage] = []
    
    private var path: String!
    
    private var requestsManager: GRRequestsManager!
    private var webpEncoder: YYImageEncoder!
    private var videoRequest: GRDataExchangeRequestProtocol?
    private var imagePickerViewController: UIImagePickerController?
    
    deinit {
        myTimer?.invalidate()
        self.myTimer = nil
        self.resetUICamera()
        self.imageToUploads.removeAll()
        if self.requestsManager != nil {
            self.requestsManager.stopAndCancelAllRequests()
            self.requestsManager = nil
        }
        if webpEncoder != nil {
            self.webpEncoder = nil
        }
        if imagePickerViewController != nil {
            self.imagePickerViewController = nil
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.requestsManager = GRRequestsManager(hostname: ftpURL, user: ftpUsername, password: ftpPassword)
        self.requestsManager.delegate = self
        self.webpEncoder = YYImageEncoder(type: .GIF)
        webpEncoder.loopCount = 5
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        if let previewViewController = self.previewViewController {
            previewViewController.view.removeFromSuperview()
            previewViewController.removeFromParentViewController()
            self.attachCameraAndStart(shouldStart: false, sizeToDisplay: size)
        }
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
        self.imageToUploads.removeAll()
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
                attachCameraAndStart(shouldStart: true, sizeToDisplay: UIScreen.main.bounds.size)
                startButton.isHidden = true
                pickedImageButton.isHidden = true
                countdownLabel.isHidden = false
                finishLabel.isHidden = true
                self.myTimer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(updateLabel(timer:)), userInfo: nil, repeats: false)
            }
        }
    }
    
    func updateLabel(timer: Timer) {
        countdownLabel.text = "\(time)"
        time = time - 1
        if time == 0 {
            if myTimer != nil {
                myTimer!.invalidate()
                self.myTimer = nil
            }
            self.perform(#selector(resetTimer), with: nil, afterDelay: 1.0)
        } else {
            self.myTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateLabel(timer:)), userInfo: nil, repeats: false)
        }
    }
    
    func resetTimer() {
        self.previewViewController?.capture({ (camera, image, metadata, error) in
            if error != nil {
                self.resetUICamera()
            } else {
                //no error
                if let imageRaw = image {
                    let phImage = PHImage(image: imageRaw)
                    self.imageToUploads.append(phImage)
                    if self.imageToUploads.count < 5 {
                        // continue
                        self.time = 5
                        self.startButton.isHidden = true
                        self.pickedImageButton.isHidden = true
                        self.countdownLabel.isHidden = false
                        self.countdownLabel.text = "5"
                        self.myTimer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(self.updateLabel(timer:)), userInfo: nil, repeats: false)
                    } else {
                        // 5 images upload and reset
                        var settings = RenderSettings()
                        let firstImage = self.imageToUploads.first!
                        settings.width = firstImage.adjustedImage.size.width
                        settings.height = firstImage.adjustedImage.size.height
                        settings.fps = 1
                        let imageAnimator = ImageAnimator(renderSettings: settings, images: self.imageToUploads)
                        imageAnimator.render() {
                            self.ftpUploadVideofile(imageAnimator: imageAnimator)
                        }
                    }
                }
            }
        })
    }
    
    func saveImageToPhotosAlbum() {
//        for imageCapture in imageToUploads {
        for (_, value) in imageToUploads.enumerated() {
            UIImageWriteToSavedPhotosAlbum(value.originalImage, self, #selector(saveImage(_:didFinishSavingWithError:contextInfo:)), nil)
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
        let folderName = dateFormatter.string(from: Date())
        self.path = "/\(folderName)"
        let filePath = self.path + "/\(imageAnimator.settings.videoFilename).\(imageAnimator.settings.videoFilenameExt)"
        requestsManager.addRequestForCreateDirectory(atPath: path)
        self.videoRequest = requestsManager.addRequestForUploadFile(atLocalPath: imageAnimator.settings.outputURL.path, toRemotePath: filePath)
        requestsManager.startProcessingRequests()
    }
    
    func ftpUploadImagefiles(path: String) {
        removeAllTempFiles()
        for i in 0 ..< imageToUploads.count {
            let image = imageToUploads[i].adjustedImage
            let fileURL = self.fileImages(i + 1)
            if let imageRawData = UIImageJPEGRepresentation(image!, 1) {
                do {
                    try imageRawData.write(to: fileURL)
                } catch _ {
                    continue
                }
                let filePath = "\(path)/jpg-\(i + 1).jpg"
                requestsManager.addRequestForUploadFile(atLocalPath: fileURL.path, toRemotePath: filePath)
            } else {
                continue
            }
        }
        self.exportGifFile(path: path)
    }
    
    func removeAllTempFiles() {
        ImageAnimator.removeFileAtURL(fileURL: self.gifFileImage())
        for i in 1 ... 5 {
            ImageAnimator.removeFileAtURL(fileURL: self.fileImages(i))
        }
    }
    
    func exportGifFile(path: String) {
        for i in 0 ..< imageToUploads.count {
            let image = imageToUploads[i].adjustedImage
            webpEncoder.add(image!, duration: 1.0)
        }
        if let gifData = webpEncoder.encode() {
            let gifFileURL = self.gifFileImage()
            do {
                try gifData.write(to: gifFileURL)
            } catch {
                //gif fail upload others
                requestsManager.startProcessingRequests()
                return
            }
            let filePath = "\(path)/animateGIF.gif"
            requestsManager.addRequestForUploadFile(atLocalPath: gifFileURL.path, toRemotePath: filePath)
        }
        self.saveImageToPhotosAlbum()
        self.requestsManager.startProcessingRequests()
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
    
    private func attachCameraAndStart(shouldStart: Bool, sizeToDisplay: CGSize) {
        if self.previewViewController == nil {
            self.previewViewController = LLSimpleCamera(quality: AVCaptureSessionPresetPhoto, position: LLCameraPositionFront, videoEnabled: false)
        }
        self.previewViewController!.attach(to: self, withFrame: CGRect(x: 0, y: 0, width: sizeToDisplay.width, height: sizeToDisplay.height))
        self.view.bringSubview(toFront: finishLabel)
        self.view.bringSubview(toFront: countdownLabel)
        self.view.bringSubview(toFront: startButton)
        if shouldStart {
            self.previewViewController!.start()
        }
    }
    
    func resetUICamera() {
        countdownLabel.text = "5"
        startButton.isHidden = false
        pickedImageButton.isHidden = false
        countdownLabel.isHidden = true
        finishLabel.isHidden = false
        time = 5
        startButton.setTitle("Restart", for: .normal)
        if let previewViewController =  previewViewController {
            previewViewController.stop()
            previewViewController.view.removeFromSuperview()
            previewViewController.removeFromParentViewController()
        }
        self.previewViewController = nil
    }
    
    // MARK: - GRRequestManagerDelegate
    
    func requestsManager(_ requestsManager: GRRequestsManagerProtocol!, didFailRequest request: GRRequestProtocol!, withError error: Error!) {
        //fail by request
    }
    
    func requestsManager(_ requestsManager: GRRequestsManagerProtocol!, didCompleteUploadRequest request: GRDataExchangeRequestProtocol!) {
        //all upload
        if let videoRequest = videoRequest {
            if request.isEqual(videoRequest) {
                self.ftpUploadImagefiles(path: self.path)
                self.videoRequest = nil
            }
        }
    }
    
    func requestsManager(_ requestsManager: GRRequestsManagerProtocol!, didFailWritingFileAtPath path: String!, forRequest request: GRDataExchangeRequestProtocol!, error: Error!) {
        //fail write path
    }
    
    func requestsManager(_ requestsManager: GRRequestsManagerProtocol!, didCompletePercent percent: Float, forRequest request: GRRequestProtocol!) {
        //show percent
    }
    
    func requestsManagerDidCompleteQueue(_ requestsManager: GRRequestsManagerProtocol!) {
        //queue empty
        self.path = nil
        DispatchQueue.main.async {
            self.removeAllImages()
            self.resetUICamera()
        }
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
}

