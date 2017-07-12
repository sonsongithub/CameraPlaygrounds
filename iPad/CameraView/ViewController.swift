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
    
    var imageFunc: ((inout [CUnsignedChar], Int, Int, Int) -> Void) = { (pixel: inout [CUnsignedChar], width: Int, height: Int, bytesPerRow: Int) -> Void in
        
//        var temp: [CUnsignedChar] = [CUnsignedChar](repeating: 0, count: height * bytesPerRow)
//
//        memcpy(&temp, &pixel, height * bytesPerRow)
        
        for y in 0..<height {
            for x in 0..<width {
                
                let targetx = x //width - 1 - x
                let targety = height - 1 - y
                
                let r = CUnsignedChar(20) //pixel[4 * x + y * bytesPerRow + 0]
                let g = temp[4 * x + y * bytesPerRow + 1]
                let b = temp[4 * x + y * bytesPerRow + 2]
                let a = temp[4 * x + y * bytesPerRow + 3]
                pixel[4 * targetx + targety * bytesPerRow + 0] = r
                pixel[4 * targetx + targety * bytesPerRow + 1] = g
                pixel[4 * targetx + targety * bytesPerRow + 2] = b
                pixel[4 * targetx + targety * bytesPerRow + 3] = a
            }
        }
    }
    
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
            session.sessionPreset = .low
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
    
    private func creatCGImage(pointer: UnsafeMutableRawPointer?, width: CGFloat, height: CGFloat, bytesPerPixel: CGFloat) -> CGImage? {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue)
            .union(CGBitmapInfo.byteOrder32Little)
        guard let context = CGContext(data: pointer, width: Int(width), height: Int(height), bitsPerComponent: 8, bytesPerRow: Int(bytesPerPixel), space: colorSpace, bitmapInfo: bitmapInfo.rawValue) else { return nil }
        return context.makeImage()
    }
    
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
//        switch connection.videoOrientation {
//        case .portrait:
//            print("portrait")
//        case .portraitUpsideDown:
//            print("portraitUpsideDown")
//        case .landscapeLeft:
//            print("landscapeLeft")
//        case .landscapeRight:
//            print("landscapeRight")
//        }
//
//        NSLog("[Camera] - capture")
        let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)!
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)

        let pixelBufferWidth = CGFloat(CVPixelBufferGetWidth(pixelBuffer))
        let pixelBufferHeight = CGFloat(CVPixelBufferGetHeight(pixelBuffer))
        let bytesPerHeight = CGFloat(CVPixelBufferGetBytesPerRow(pixelBuffer))
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)

        let pointer = (CUnsignedChar*)CVPixelBufferGetBaseAddress(pixelBuffer)
        
        var buffer: [CUnsignedChar] = [CUnsignedChar](repeating: 0, count: height * bytesPerRow)
        
        
        
        for y in 0..<height {
            for x in 0..<width {
                
                let targetx = x //width - 1 - x
                let targety = height - 1 - y
                
//                let r = pointer[4 * x + y * bytesPerRow + 0]
//                let g = pointer[4 * x + y * bytesPerRow + 1]
//                let b = pointer[4 * x + y * bytesPerRow + 2]
//                let a = pointer[4 * x + y * bytesPerRow + 3]
//                buffer[4 * targetx + targety * bytesPerRow + 0] = r
//                buffer[4 * targetx + targety * bytesPerRow + 1] = g
//                buffer[4 * targetx + targety * bytesPerRow + 2] = b
//                buffer[4 * targetx + targety * bytesPerRow + 3] = a
            }
        }

//        memcpy(&buffer, pointer, height * bytesPerRow)

        imageFunc(&buffer, width, height, bytesPerRow)
        
        guard let cgImage = creatCGImage(pointer: &buffer, width: pixelBufferWidth, height: pixelBufferHeight, bytesPerPixel: bytesPerHeight) else { return }

        let uiImage = UIImage(cgImage: cgImage)

        DispatchQueue.main.async {
            self.imageView.image = uiImage
        }
        CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly)
    }
}

