//
//  PHImage.swift
//  PhotoBooth
//
//  Created by Wasupol Tungsakultong on 10/21/2559 BE.
//  Copyright © 2559 Wasupol Tungsakultong. All rights reserved.
//

import Foundation

class PHImage {
    var originalImage: UIImage!
    var adjustedImage: UIImage!
    
    deinit {
        self.originalImage = nil
        self.adjustedImage = nil
    }
    
    init(image: UIImage) {
        self.originalImage = image
        print("original image size: \(self.originalImage.size)")
        // Start proceed adjust image with watermark ater init
        self.processAdjustedImage(image)
        // set adjust image equals to image that captured from screen
//        self.adjustedImage = image
    }
    
    private func processAdjustedImage(_ image: UIImage) {
        //TODO add watermark
        self.adjustedImage = self.applyWatermarkIfNeed(image)
//        self.fixrotation(waterMarkImage)
//        self.adjustedImage = self.adjustedImage.resizeWith(percentage: 0.25)
    }
    
    private func applyWatermarkIfNeed(_ image: UIImage) -> UIImage {
        if ImageManager.sharedInstance.hasWaterMarkImage() {
            print("areaSize width: \(image.size.width)")
            print("areaSize height: \(image.size.height)")
            let areaSize = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
            UIGraphicsBeginImageContextWithOptions(areaSize.size , false, 0.0)
            print("areaSize: \(areaSize.size)")
            image.draw(in: areaSize)
            ImageManager.sharedInstance.waterMarkImage!.draw(in: areaSize, blendMode: .normal, alpha: 1.0)
            let result = UIGraphicsGetImageFromCurrentImageContext()!
            UIGraphicsEndImageContext()
            print("result size: \(result.size)")
            return result
        } else {
            //no watermark
            return image
        }
    }
    
    
//    private func drawFrame(_ image: UIImage) -> UIImage
//    {
//        var bottomImage  = UIImage(cgImage: ImageManager.sharedInstance.waterMarkImage?.cgImage)
//        var topImage = image!
//        
//        var size = CGSize(width: 300, height: 300)
//        UIGraphicsBeginImageContext(size)
//        
//        let areaSize = CGRect(x: 0, y: 0, width: size.width, height: size.height)
//        bottomImage!.drawInRect(areaSize)
//        
//        topImage!.drawInRect(areaSize, blendMode: kCGBlendModeNormal, alpha: 0.8)
//        
//        var newImage:UIImage = UIGraphicsGetImageFromCurrentImageContext()
//        UIGraphicsEndImageContext()
//    }
}

extension UIImage {
    func resizeWith(percentage: CGFloat) -> UIImage? {
        let imageView = UIImageView(frame: CGRect(origin: .zero, size: CGSize(width: size.width * percentage, height: size.height * percentage)))
        imageView.contentMode = .scaleAspectFit
        imageView.image = self
        UIGraphicsBeginImageContextWithOptions(imageView.bounds.size, false, scale)
        guard let context = UIGraphicsGetCurrentContext() else {
            return nil
        }
        imageView.layer.render(in: context)
        guard let result = UIGraphicsGetImageFromCurrentImageContext() else {
            return nil
        }
        UIGraphicsEndImageContext()
        return result
    }
    func resizeWith(width: CGFloat) -> UIImage? {
        let imageView = UIImageView(frame: CGRect(origin: .zero, size: CGSize(width: width, height: CGFloat(ceil(width/size.width * size.height)))))
        imageView.contentMode = .scaleAspectFit
        imageView.image = self
        UIGraphicsBeginImageContextWithOptions(imageView.bounds.size, false, scale)
        guard let context = UIGraphicsGetCurrentContext() else {
            return nil
        }
        imageView.layer.render(in: context)
        guard let result = UIGraphicsGetImageFromCurrentImageContext() else { return nil }
        UIGraphicsEndImageContext()
        return result
    }
}
