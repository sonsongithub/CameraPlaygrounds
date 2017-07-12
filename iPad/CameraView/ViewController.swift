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

public class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    var device: AVCaptureDevice?
    var session: AVCaptureSession?
    let imageView = UIImageView(frame: .zero)
    
    var buffer: [CUnsignedChar]?

    public override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        let views: [String: UIView] = ["imageView": imageView]
        self.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[imageView]-0-|", options: [], metrics: nil, views: views))
        self.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[imageView]-0-|", options: [], metrics: nil, views: views))
        
        let session = AVCaptureSession()
        let discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .front)
        guard discoverySession.devices.count > 0 else { return }
        let device = discoverySession.devices[0]
        
        session.beginConfiguration()
        
        do {
            let deviceInput = try AVCaptureDeviceInput(device: device)
            session.addInput(deviceInput)
            session.sessionPreset = .vga640x480
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
    
    private func creatCGImage(pixels: [CUnsignedChar], width: CGFloat, height: CGFloat, bytesPerPixel: CGFloat) -> CGImage? {
        guard var buffer = buffer else { return nil }
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue)
            .union(CGBitmapInfo.byteOrder32Little)
        guard let context = CGContext(data: &buffer, width: Int(width), height: Int(height), bitsPerComponent: 8, bytesPerRow: Int(bytesPerPixel), space: colorSpace, bitmapInfo: bitmapInfo.rawValue) else { return nil }
        return context.makeImage()
    }
    
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        switch connection.videoOrientation {
        case .portrait:
            print("portrait")
        case .portraitUpsideDown:
            print("portraitUpsideDown")
        case .landscapeLeft:
            print("landscapeLeft")
        case .landscapeRight:
            print("landscapeRight")
        }
        
        NSLog("[Camera] - capture")
        let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)!
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)

//        let image = CIImage(cvImageBuffer: pixelBuffer)

        let pixelBufferWidth = CGFloat(CVPixelBufferGetWidth(pixelBuffer))
        let pixelBufferHeight = CGFloat(CVPixelBufferGetHeight(pixelBuffer))
        let bytesPerHeight = CGFloat(CVPixelBufferGetBytesPerRow(pixelBuffer))
        
        let pointer = CVPixelBufferGetBaseAddress(pixelBuffer)
        
        if buffer == nil {
            let height = CVPixelBufferGetHeight(pixelBuffer)
            let bytesPerHeight = CVPixelBufferGetBytesPerRow(pixelBuffer)
            buffer = [CUnsignedChar](repeating: 0, count: height * bytesPerHeight)
        }
        
        if var temp = buffer {
            let height = CVPixelBufferGetHeight(pixelBuffer)
            let bytesPerHeight = CVPixelBufferGetBytesPerRow(pixelBuffer)
            memcpy(&temp, pointer, height * bytesPerHeight)
            
            for i in 0..<10000 {
                temp[i] = 122
            }
        }
        
        guard let cgImage = creatCGImage(pixels: buffer!, width: pixelBufferWidth, height: pixelBufferHeight, bytesPerPixel: bytesPerHeight) else { return }
        
//
//        let imageRect:CGRect = CGRect(x: 0, y: 0, width: pixelBufferWidth, height: pixelBufferHeight)
//        let context = CIContext()
//        let cgImage = context.createCGImage(image, from: imageRect)
//

        let uiImage = UIImage(cgImage: cgImage)
        print(uiImage)
        CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly)

        DispatchQueue.main.async {
            self.imageView.image = uiImage
        }
    }
}

