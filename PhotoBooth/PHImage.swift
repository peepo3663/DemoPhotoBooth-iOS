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
        self.fixrotation(image)
    }

    private func fixrotation(_ image: UIImage) {
        let targetWidth = image.size.width
        let targetHeight = image.size.height
        
        let imageRef = image.cgImage!
        var alphaInfo = imageRef.alphaInfo
        
        let colorSpaceInfo = imageRef.colorSpace!
        
        if alphaInfo == .none {
            alphaInfo = .premultipliedFirst
        }
        
        let bitmap: CGContext!
        
        if image.imageOrientation == .up || image.imageOrientation == .down {
            bitmap = CGContext(data: nil, width: Int(targetWidth), height: Int(targetHeight), bitsPerComponent: imageRef.bitsPerComponent, bytesPerRow: imageRef.bytesPerRow, space: colorSpaceInfo, bitmapInfo: alphaInfo.rawValue)!
        } else {
            bitmap = CGContext(data: nil, width: Int(targetHeight), height: Int(targetWidth), bitsPerComponent: imageRef.bitsPerComponent, bytesPerRow: imageRef.bytesPerRow, space: colorSpaceInfo, bitmapInfo: alphaInfo.rawValue)!
        }
        
        if image.imageOrientation == .left {
            bitmap.rotate(by: CGFloat(PHImage.radians(90)))
            bitmap.translateBy(x: 0, y: -targetHeight)
            
        } else if image.imageOrientation == .right {
            bitmap.rotate(by: CGFloat(PHImage.radians(-90)))
            bitmap.translateBy(x: -targetWidth, y: 0)
        } else if image.imageOrientation == .up {
            // NOTHING
        } else if image.imageOrientation == .down {
            bitmap.translateBy(x: targetWidth, y: targetHeight)
            bitmap.rotate(by: CGFloat(PHImage.radians(180)))
        }
        bitmap.draw(imageRef, in: CGRect(x: 0,y: 0,width: targetWidth,height: targetHeight))
        
        let ref = bitmap.makeImage()
        let newImage = UIImage(cgImage: ref!)
        
        self.adjustedImage = newImage
    }
    
    class func radians(_ degrees: Double) -> Double {
        return degrees * M_PI/180.0
    }
}
