//
//  ImageManager.swift
//  PhotoBooth
//
//  Created by Wasupol Tungsakultong on 11/13/2559 BE.
//  Copyright © 2559 Wasupol Tungsakultong. All rights reserved.
//

import UIKit

class ImageManager {
    static var sharedInstance: ImageManager = ImageManager()
    var waterMarkImage: UIImage?
    
    deinit {
        self.waterMarkImage = nil
    }
    
    func setWaterMarkImage(_ image: UIImage) {
        if waterMarkImage != image {
            self.waterMarkImage = image
        }
    }
    
    func hasWaterMarkImage() -> Bool {
        return self.waterMarkImage != nil
    }
}
