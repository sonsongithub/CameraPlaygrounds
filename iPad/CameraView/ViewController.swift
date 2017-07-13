//
//  ViewController.swift
//  CameraView
//
//  Created by sonson on 2017/07/11.
//  Copyright © 2017年 sonson. All rights reserved.
//


import UIKit
import AVFoundation
import CoreImage

enum CameraOrientation {
    case landscapeLeft
    case landscapeRight
    case portrait
    case portraitUpsideDown
}

public class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    var device: AVCaptureDevice?
    var session: AVCaptureSession?
    let imageView = UIImageView(frame: .zero)
    
    var cameraOrientation = CameraOrientation.landscapeLeft
    
    var ratio = CGFloat(1)
    
    var orientation = AVCaptureVideoOrientation.portrait

    var pixelBuffer24bit: [CUnsignedChar]?
    var pixelBuffer32bit: [CUnsignedChar]?
    
    var constraintWidth: NSLayoutConstraint?
    var constraintHeight: NSLayoutConstraint?
    
    var outputWidth = 1
    var outputHeight = 1
    
    var originalVideoWidth = 1
    var originalVideoHeight = 1
    
    var imageFunc: ((inout [CUnsignedChar], Int, Int, Int) -> Void) = { (pixel: inout [CUnsignedChar], width: Int, height: Int, bytesPerRow: Int) -> Void in
        
        for y in 0..<height {
            for x in 0..<width/2 {
                pixel[3 * x + y * bytesPerRow + 0] = 0
//                pixel[4 * targetx + targety * bytesPerRow + 1] = g
//                pixel[4 * targetx + targety * bytesPerRow + 2] = b
            }
        }
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        let views: [String: UIView] = ["imageView": imageView]
//        self.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[imageView]-0-|", options: [], metrics: nil, views: views))
//        self.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[imageView]-0-|", options: [], metrics: nil, views: views))
        
        let constraintX = NSLayoutConstraint(item: self.view, attribute: .centerX, relatedBy: .equal, toItem: imageView, attribute: .centerX, multiplier: 1, constant: 0)
        let constraintY = NSLayoutConstraint(item: self.view, attribute: .centerY, relatedBy: .equal, toItem: imageView, attribute: .centerY, multiplier: 1, constant: 0)
        let constraintWidth = NSLayoutConstraint(item: imageView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 384)
        let constraintHeight = NSLayoutConstraint(item: imageView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 384)
        
        self.view.addConstraint(constraintX)
        self.view.addConstraint(constraintY)
        imageView.addConstraint(constraintWidth)
        imageView.addConstraint(constraintHeight)
        
        self.constraintWidth = constraintWidth
        self.constraintHeight = constraintHeight
        
        let session = AVCaptureSession()
        let discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .front)
        guard discoverySession.devices.count > 0 else { return }
        let device = discoverySession.devices[0]
        
        session.beginConfiguration()
        
        do {
            let deviceInput = try AVCaptureDeviceInput(device: device)
            session.addInput(deviceInput)
            session.sessionPreset = .medium
        } catch {
            print(error)
            return
        }
        
        let output = AVCaptureVideoDataOutput()
        output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        let cameraQueue = DispatchQueue(label: "camera")
        output.setSampleBufferDelegate(self, queue: cameraQueue)
        output.alwaysDiscardsLateVideoFrames = true
        session.addOutput(output)
        
        session.commitConfiguration()

        do {
            try device.lockForConfiguration()
            device.activeVideoMinFrameDuration = CMTimeMake(1, 30)
            device.unlockForConfiguration()
        } catch {
            print(error)
        }
        session.startRunning()
        
        self.session = session
        self.device = device
    }
    
    private func creatCGImage(pointer: UnsafeMutableRawPointer?, width: Int, height: Int, bytesPerPixel: Int) -> CGImage? {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
            .union(CGBitmapInfo.byteOrder32Little)
        guard let context = CGContext(data: pointer, width: (width), height: (height), bitsPerComponent: 8, bytesPerRow: (bytesPerPixel), space: colorSpace, bitmapInfo: bitmapInfo.rawValue) else { return nil }
        return context.makeImage()
    }
    
    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
    }
    
    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
    }
    
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)!
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)

        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        
        originalVideoWidth = width
        originalVideoHeight = height
        
        guard let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer) else { return }
        
        let pointer: UnsafeMutablePointer<UInt8> = baseAddress.assumingMemoryBound(to: UInt8.self)
        
        if pixelBuffer24bit == nil {
            pixelBuffer24bit = [CUnsignedChar](repeating: 0, count: height * width * 3)
        }
        if pixelBuffer32bit == nil {
            pixelBuffer32bit = [CUnsignedChar](repeating: 0, count: height * width * 4)
        }
        
        switch UIDevice.current.orientation {
        case .landscapeRight:
            let newOrientation = CameraOrientation.landscapeRight
            if newOrientation != cameraOrientation {
                cameraOrientation = .landscapeRight
                outputWidth = height
                outputHeight = width
                
                DispatchQueue.main.async {
                    let A = self.view.frame.size.width / self.view.frame.size.height
                    let a = CGFloat(self.outputWidth) / CGFloat(self.outputHeight)

                    if A < a {
                        self.constraintHeight?.constant = self.view.frame.size.height
                        self.constraintWidth?.constant = self.view.frame.size.height * a
                    } else {
                        self.constraintWidth?.constant = self.view.frame.size.width
                        self.constraintHeight?.constant = self.view.frame.size.width / a
                    }
                }
            }
        case .landscapeLeft:
            let newOrientation = CameraOrientation.landscapeLeft
            if newOrientation != cameraOrientation {
                cameraOrientation = .landscapeLeft
                outputWidth = height
                outputHeight = width
                
                DispatchQueue.main.async {
                    let A = self.view.frame.size.width / self.view.frame.size.height
                    let a = CGFloat(self.outputWidth) / CGFloat(self.outputHeight)
                    
                    if A < a {
                        self.constraintHeight?.constant = self.view.frame.size.height
                        self.constraintWidth?.constant = self.view.frame.size.height * a
                    } else {
                        self.constraintWidth?.constant = self.view.frame.size.width
                        self.constraintHeight?.constant = self.view.frame.size.width / a
                    }
                }
            }
        case .portrait:
            let newOrientation = CameraOrientation.portrait
            if newOrientation != cameraOrientation {
                cameraOrientation = .portrait
                outputWidth = width
                outputHeight = height
                
                DispatchQueue.main.async {
                    let A = self.view.frame.size.width / self.view.frame.size.height
                    let a = CGFloat(self.outputWidth) / CGFloat(self.outputHeight)
                    
                    if A < a {
                        self.constraintHeight?.constant = self.view.frame.size.height
                        self.constraintWidth?.constant = self.view.frame.size.height * a
                    } else {
                        self.constraintWidth?.constant = self.view.frame.size.width
                        self.constraintHeight?.constant = self.view.frame.size.width / a
                    }
                }
            }
        case .portraitUpsideDown:
            let newOrientation = CameraOrientation.portraitUpsideDown
            if newOrientation != cameraOrientation {
                cameraOrientation = .portraitUpsideDown
                outputWidth = width
                outputHeight = height
                
                DispatchQueue.main.async {
                    let A = self.view.frame.size.width / self.view.frame.size.height
                    let a = CGFloat(self.outputWidth) / CGFloat(self.outputHeight)
                    
                    if A < a {
                        self.constraintHeight?.constant = self.view.frame.size.height
                        self.constraintWidth?.constant = self.view.frame.size.height * a
                    } else {
                        self.constraintWidth?.constant = self.view.frame.size.width
                        self.constraintHeight?.constant = self.view.frame.size.width / a
                    }
                }
            }
        default:
            do {}
        }
        
        switch cameraOrientation {
        case .landscapeLeft:
            outputWidth = height
            outputHeight = width
            for y in 0..<height {
                for x in 0..<width {
                    let targetx = y
                    let targety = x
                    let r = pointer[4 * x + y * bytesPerRow + 0]
                    let g = pointer[4 * x + y * bytesPerRow + 1]
                    let b = pointer[4 * x + y * bytesPerRow + 2]
                    pixelBuffer24bit![3 * targetx + targety * outputWidth * 3 + 0] = r
                    pixelBuffer24bit![3 * targetx + targety * outputWidth * 3 + 1] = g
                    pixelBuffer24bit![3 * targetx + targety * outputWidth * 3 + 2] = b
                }
            }
        case .landscapeRight:
            outputWidth = height
            outputHeight = width
            for y in 0..<height {
                for x in 0..<width {
                    let targetx = y
                    let targety = outputHeight - 1 - x
                    let r = pointer[4 * x + y * bytesPerRow + 0]
                    let g = pointer[4 * x + y * bytesPerRow + 1]
                    let b = pointer[4 * x + y * bytesPerRow + 2]
                    pixelBuffer24bit![3 * targetx + targety * outputWidth * 3 + 0] = r
                    pixelBuffer24bit![3 * targetx + targety * outputWidth * 3 + 1] = g
                    pixelBuffer24bit![3 * targetx + targety * outputWidth * 3 + 2] = b
                }
            }
        case .portrait:
            outputWidth = width
            outputHeight = height
            for y in 0..<height {
                for x in 0..<width {
                    let targetx = x
                    let targety = y
                    let r = pointer[4 * x + y * bytesPerRow + 0]
                    let g = pointer[4 * x + y * bytesPerRow + 1]
                    let b = pointer[4 * x + y * bytesPerRow + 2]
                    pixelBuffer24bit![3 * targetx + targety * outputWidth * 3 + 0] = r
                    pixelBuffer24bit![3 * targetx + targety * outputWidth * 3 + 1] = g
                    pixelBuffer24bit![3 * targetx + targety * outputWidth * 3 + 2] = b
                }
            }
        case .portraitUpsideDown:
            outputWidth = width
            outputHeight = height
            for y in 0..<height {
                for x in 0..<width {
                    let targetx = x
                    let targety = outputHeight - 1 - y
                    let r = pointer[4 * x + y * bytesPerRow + 0]
                    let g = pointer[4 * x + y * bytesPerRow + 1]
                    let b = pointer[4 * x + y * bytesPerRow + 2]
                    pixelBuffer24bit![3 * targetx + targety * outputWidth * 3 + 0] = r
                    pixelBuffer24bit![3 * targetx + targety * outputWidth * 3 + 1] = g
                    pixelBuffer24bit![3 * targetx + targety * outputWidth * 3 + 2] = b
                }
            }
        }
        
        ratio = CGFloat(outputWidth) / CGFloat(outputHeight)

        imageFunc(&pixelBuffer24bit!, outputWidth, outputHeight, 3 * outputWidth)
        
        for y in 0..<outputHeight {
            for x in 0..<outputWidth {
                let r = pixelBuffer24bit![3 * x + y * outputWidth * 3 + 0]
                let g = pixelBuffer24bit![3 * x + y * outputWidth * 3 + 1]
                let b = pixelBuffer24bit![3 * x + y * outputWidth * 3 + 2]
                pixelBuffer32bit![4 * x + y * outputWidth * 4 + 0] = 255
                pixelBuffer32bit![4 * x + y * outputWidth * 4 + 1] = r
                pixelBuffer32bit![4 * x + y * outputWidth * 4 + 2] = g
                pixelBuffer32bit![4 * x + y * outputWidth * 4 + 3] = b
            }
        }
        CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly)

        guard let cgImage = creatCGImage(pointer: &pixelBuffer32bit!, width: outputWidth, height: outputHeight, bytesPerPixel: outputWidth * 4) else { return }

        let uiImage = UIImage(cgImage: cgImage)

        DispatchQueue.main.async {
            self.imageView.image = uiImage
        }
    }
}

