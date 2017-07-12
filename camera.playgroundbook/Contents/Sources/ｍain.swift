//  playground
import PlaygroundSupport

public class CameraPlayground {
    public static let viewController = ViewController()
    public static func initialize() {
        PlaygroundPage.current.liveView = viewController
    }
}
