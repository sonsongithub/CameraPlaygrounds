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
    var connection: AVCaptureConnection?
    let imageView = UIImageView(frame: .zero)
    
    var orientation = AVCaptureVideoOrientation.portrait

    var pixelBuffer24bit: [CUnsignedChar]?
    var pixelBuffer32bit: [CUnsignedChar]?
    
    var imageFunc: ((inout [CUnsignedChar], Int, Int, Int) -> Void) = { (pixel: inout [CUnsignedChar], width: Int, height: Int, bytesPerRow: Int) -> Void in
        
//        var temp: [CUnsignedChar] = [CUnsignedChar](repeating: 0, count: height * bytesPerRow)
//
//        memcpy(&temp, &pixel, height * bytesPerRow)
        
//        for y in 0..<height {
//            for x in 0..<width {
//
//                let targetx = x //width - 1 - x
//                let targety = height - 1 - y
//
//                let r = CUnsignedChar(20) //pixel[4 * x + y * bytesPerRow + 0]
//                let g = temp[4 * x + y * bytesPerRow + 1]
//                let b = temp[4 * x + y * bytesPerRow + 2]
//                let a = temp[4 * x + y * bytesPerRow + 3]
//                pixel[4 * targetx + targety * bytesPerRow + 0] = r
//                pixel[4 * targetx + targety * bytesPerRow + 1] = g
//                pixel[4 * targetx + targety * bytesPerRow + 2] = b
//                pixel[4 * targetx + targety * bytesPerRow + 3] = a
//            }
//        }
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
        
        self.connection = output.connection(with: .video)
        
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
    
    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        session?.stopRunning()
        session?.beginConfiguration()
        print(UIApplication.shared.statusBarOrientation.rawValue)
        switch UIApplication.shared.statusBarOrientation {
        case .landscapeLeft:
            self.connection?.videoOrientation = .landscapeLeft
        case .landscapeRight:
            self.connection?.videoOrientation = .landscapeRight
        case .portrait:
            self.connection?.videoOrientation = .portrait
        case .portraitUpsideDown:
            self.connection?.videoOrientation = .portraitUpsideDown
        case .unknown:
            self.connection?.videoOrientation = .portrait
        }
        session?.commitConfiguration()
        session?.startRunning()
    }
    
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
//        print(connection)
//        DispatchQueue.main.async {
//            print(UIApplication.shared.statusBarOrientation.rawValue)
//        }
//        if orientation != connection.videoOrientation {
//            switch connection.videoOrientation {
//            case .portrait:
//                print("portrait")
//            case .portraitUpsideDown:
//                print("portraitUpsideDown")
//            case .landscapeLeft:
//                print("landscapeLeft")
//            case .landscapeRight:
//                print("landscapeRight")
//            }
//            orientation = connection.videoOrientation
//        }
        
        connection.videoOrientation = .portrait
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
        
        print("\(width)x\(height)")

        guard let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer) else { return }
        
        let pointer: UnsafeMutablePointer<UInt8> = baseAddress.assumingMemoryBound(to: UInt8.self)
        
//        var buffer: [CUnsignedChar] = [CUnsignedChar](repeating: 0, count: height * width * 3)

        if pixelBuffer24bit == nil {
            pixelBuffer24bit = [CUnsignedChar](repeating: 0, count: height * width * 3)
        }
        if pixelBuffer32bit == nil {
            pixelBuffer32bit = [CUnsignedChar](repeating: 0, count: height * width * 4)
        }
        
        for y in 0..<height {
            for x in 0..<width {

                let targetx = x //width - 1 - x
                let targety = y //height - 1 - y

                let r = pointer[4 * x + y * bytesPerRow + 0]
                let g = pointer[4 * x + y * bytesPerRow + 1]
                let b = pointer[4 * x + y * bytesPerRow + 2]
//                let a = pointer[4 * x + y * bytesPerRow + 3]
                pixelBuffer24bit![3 * targetx + targety * width * 3 + 0] = r
                pixelBuffer24bit![3 * targetx + targety * width * 3 + 1] = g
                pixelBuffer24bit![3 * targetx + targety * width * 3 + 2] = b
            }
        }

//        memcpy(&buffer, pointer, height * bytesPerRow)

        imageFunc(&pixelBuffer24bit!, width, height, 3 * width)
        
        for y in 0..<height {
            for x in 0..<width {
                
                let targetx = x //width - 1 - x
                let targety = height - 1 - y
                
                let r = pixelBuffer24bit![3 * x + y * width * 3 + 0]
                let g = pixelBuffer24bit![3 * x + y * width * 3 + 1]
                let b = pixelBuffer24bit![3 * x + y * width * 3 + 2]
                pixelBuffer32bit![4 * targetx + targety * width * 4 + 0] = 255
                pixelBuffer32bit![4 * targetx + targety * width * 4 + 1] = r
                pixelBuffer32bit![4 * targetx + targety * width * 4 + 2] = g
                pixelBuffer32bit![4 * targetx + targety * width * 4 + 3] = b
            }
        }

        guard let cgImage = creatCGImage(pointer: &pixelBuffer32bit!, width: width, height: height, bytesPerPixel: width * 4) else { return }

        let uiImage = UIImage(cgImage: cgImage)

        DispatchQueue.main.async {
            self.imageView.image = uiImage
        }
        CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly)
    }
}

