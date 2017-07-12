CameraPlayground.initialize()
CameraPlayground.viewController.imageFunc = { (pixel: inout [CUnsignedChar], width: Int, height: Int, bytesPerRow: Int) -> Void in
    for y in 0..<height {
        for x in 0..<width {
            pixel[4 * x + y * bytesPerRow + 1] = 0
            //                buffer[4 * x + y * bytesPerRow + 1] = 255
            //                buffer[4 * x + y * bytesPerRow + 2] = 0
            //                buffer[4 * x + y * bytesPerRow + 3] = 255
        }
    }
}
