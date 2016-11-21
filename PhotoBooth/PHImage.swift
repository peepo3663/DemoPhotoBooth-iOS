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
        self.processAdjustedImage(image)
    }
    
    private func processAdjustedImage(_ image: UIImage) {
        //TODO add watermark
        self.adjustedImage = self.applyWatermarkIfNeed(image)
//        self.fixrotation(waterMarkImage)
        
    }
    
    private func applyWatermarkIfNeed(_ image: UIImage) -> UIImage {
        if ImageManager.sharedInstance.hasWaterMarkImage() {
            let areaSize = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
            UIGraphicsBeginImageContextWithOptions(areaSize.size , false, 0.0)
            image.draw(in: areaSize)
            ImageManager.sharedInstance.waterMarkImage!.draw(in: areaSize, blendMode: .normal, alpha: 1.0)
            let result = UIGraphicsGetImageFromCurrentImageContext()!
            UIGraphicsEndImageContext()
            return result
        } else {
            //no watermark
            return image
        }
    }
}
