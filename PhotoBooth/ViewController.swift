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

class ViewController: UIViewController {

    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var countdownLabel: UILabel!
    @IBOutlet weak var finishLabel: UILabel!
    
    private var previewViewController: LLSimpleCamera?
    private var myTimer: Timer?
    private var time = 5
    private var imageToUploads: [UIImage] = []
    
    deinit {
        myTimer?.invalidate()
        self.myTimer = nil
        self.resetUICamera()
        self.imageToUploads.removeAll()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
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

    @IBAction func startTouchUpInside(_ sender: AnyObject) {
        if let senderButton = sender as? UIButton {
            if startButton == senderButton {
                attachCameraAndStart(shouldStart: true, sizeToDisplay: UIScreen.main.bounds.size)
                startButton.isHidden = true
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
                    self.imageToUploads.append(imageRaw)
                    if self.imageToUploads.count < 5 {
                        // continue
                        self.time = 5
                        self.startButton.isHidden = true
                        self.countdownLabel.isHidden = false
                        self.countdownLabel.text = "5"
                        self.myTimer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(self.updateLabel(timer:)), userInfo: nil, repeats: false)
                    } else {
                        // 5 images upload and reset
                        self.saveImageToPhotosAlbum()
                        self.removeAllImages()
                        self.resetUICamera()
                    }
                }
            }
        })
    }
    
    func saveImageToPhotosAlbum() {
        for imageCapture in imageToUploads {
            UIImageWriteToSavedPhotosAlbum(imageCapture, self, #selector(saveImage(_:didFinishSavingWithError:contextInfo:)), nil)
        }
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
}

