//
//  RenderSettings.swift
//  PhotoBooth
//
//  Created by Wasupol Tungsakultong on 10/20/2559 BE.
//  Copyright © 2559 Wasupol Tungsakultong. All rights reserved.
//

import Foundation
import AVFoundation
import UIKit
import Photos

struct RenderSettings {
    
    var width: CGFloat = 1280
    var height: CGFloat = 720
    var fps: Int32 = 2   // 2 frames per second
    var avCodecKey = AVVideoCodecH264
    var videoFilename = "render"
    var videoFilenameExt = "mp4"
    
    var size: CGSize {
        return CGSize(width: width, height: height)
    }
    
    var outputURL: URL {
        // Use the CachesDirectory so the rendered video file sticks around as long as we need it to.
        // Using the CachesDirectory ensures the file won't be included in a backup of the app.
        let fileManager = FileManager.default
        if let tmpDirURL = try? fileManager.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true) {
            return tmpDirURL.appendingPathComponent(videoFilename).appendingPathExtension(videoFilenameExt)
        }
        fatalError("URLForDirectory() failed")
    }
}
