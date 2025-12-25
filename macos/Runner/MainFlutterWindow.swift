import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
    override func awakeFromNib() {
        let flutterViewController = FlutterViewController()
        contentViewController = flutterViewController
        // 设置窗口样式
//        self.titlebarAppearsTransparent = true  // 标题栏透明
//        self.isOpaque = false                   // 允许窗口透明
//        self.backgroundColor = NSColor(           // 设置背景色
//            srgbRed: 0.066,                      // 0x11 = 17/255 ≈ 0.066
//            green: 0.066,
//            blue: 0.066,
//            alpha: 0.066                         // 0x11 = 17/255 ≈ 0.066
//        )

        NSApp.appearance = NSAppearance(named: .darkAqua)

//        moveWindowToCenter()
        setFixedSize(width: 1400, height: 788)

        RegisterGeneratedPlugins(registry: flutterViewController)

        super.awakeFromNib()
    }

    func moveWindowToCenter() {
        guard let screen = NSScreen.main else { return }
        let screenFrame = screen.visibleFrame
        let windowFrame = frame
        let titleBarHeight = windowFrame.height - contentRect(forFrameRect: windowFrame).height // 计算标题栏高度
        let x = screenFrame.origin.x + (screenFrame.size.width - windowFrame.size.width) / 2
        let y = screenFrame.origin.y + (screenFrame.size.height - windowFrame.size.height) / 2 - titleBarHeight / 2 // 考虑标题栏高度
        setFrameOrigin(NSPoint(x: x, y: y))
    }

    func setFixedSize(width: CGFloat, height: CGFloat) {
        let size = NSSize(width: width, height: height)
        setContentSize(size)
//        self.minSize = size
//        self.maxSize = size
        setFrame(NSRect(origin: frame.origin, size: size), display: true)
        center() // 窗口显示在屏幕中央
    }
}
