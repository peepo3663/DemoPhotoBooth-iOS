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
        self.processAdjustedImage()
    }
    
    private func processAdjustedImage() {
        //TODO add watermark
    }
}
