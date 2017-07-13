CameraPlayground.initialize()
CameraPlayground.viewController.imageFunc = { (pixel: inout [CUnsignedChar], width: Int, height: Int, bytesPerRow: Int) -> Void in
    for y in 0..<height {
        for x in 0..<width/2 {
            pixel[3 * x + y * bytesPerRow + 0] = 0
    //                pixel[4 * targetx + targety * bytesPerRow + 1] = g
    //                pixel[4 * targetx + targety * bytesPerRow + 2] = b
        }
    }
}
