import Cocoa
import FlutterMacOS

var toRelaunch = false

@main
class AppDelegate: FlutterAppDelegate {
    // MARK: - 生命周期状态标记

    private var shouldRelaunch = false
    private var isActive = false
    private var toRelaunch = false // ✅ 现在是类的成员

    private func showAlert(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    func stopMultipassVM(named name: String) {
        DispatchQueue.global(qos: .background).async {
            let process = Process()
            process.launchPath = "/usr/bin/env"
            process.arguments = ["multipass", "stop", name]

            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = pipe

            do {
                try process.run()
            } catch {
                print("❌ Failed to stop multipass VM: \(error)")
            }

            process.waitUntilExit() // 可以加也可以不加（异步线程中不阻塞主线程）
            print("✅ multipass VM \(name) stopped")
        }
    }

    override func applicationSupportsSecureRestorableState(_: NSApplication) -> Bool {
        return true
    }

    override func applicationShouldTerminateAfterLastWindowClosed(_: NSApplication) -> Bool {
        sendAppLifecycleEvent(state: "exiting")
        return false
    }

    override func applicationShouldTerminate(_: NSApplication) -> NSApplication.TerminateReply {
        var didReply = false

        // 20 秒后超时强制退出
        DispatchQueue.main.asyncAfter(deadline: .now() + 20.0) {
            if !didReply {
                print("⚠️ Flutter onExit 超时，强制退出")
                // 停掉虚拟机
                self.stopMultipassVM(named: "ubuntu-niulink")
                NSApp.reply(toApplicationShouldTerminate: true)
            }
        }

        // 发送给 Flutter：让它决定是否退出
        sendAppLifecycleEvent(state: "terminating") { result in
            guard !didReply else { return }
            didReply = true

            if let shouldExit = result as? Bool, shouldExit == false {
                // Flutter 请求取消退出
                NSApp.reply(toApplicationShouldTerminate: false)
            } else {
                // Flutter 同意退出
                if self.toRelaunch {
                    NSWorkspace.shared.launchApplication(
                        withBundleIdentifier: "com.titan_fil.titanNetwork",
                        options: [.async, .newInstance],
                        additionalEventParamDescriptor: nil,
                        launchIdentifier: nil
                    )
                }
                NSApp.reply(toApplicationShouldTerminate: true)
            }
        }

        return .terminateLater
    }

    override func applicationDidFinishLaunching(_: Notification) {
        let controller: FlutterViewController = mainFlutterWindow?.contentViewController as! FlutterViewController
        let myMethodChannel = MyMethodChannel(controller: controller)

        // Set relaunch handler
        myMethodChannel.relaunchHandler = {
            self.relaunchApp()
        }

        myMethodChannel.registerFunc()
        sendAppLifecycleEvent(to: myMethodChannel, state: "launched")
    }

    override func applicationShouldHandleReopen(_: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        // 检测到Dock图标点击，根据需要处理
        if !flag {
            // 如果没有窗口可见，可以选择重新显示窗口
            NSApp.windows.forEach { $0.makeKeyAndOrderFront(self) }
        }
        sendAppLifecycleEvent(state: flag ? "reopened" : "reactivated")
        return true
    }

    // MARK: - 激活/失活状态

    override func applicationDidBecomeActive(_: Notification) {
        isActive = true
        sendAppLifecycleEvent(state: "resumed")
    }

    override func applicationDidResignActive(_: Notification) {
        isActive = false
        sendAppLifecycleEvent(state: "paused")
    }

    // MARK: - 私有方法

    private func relaunchApp() {
        toRelaunch = true
        NSApplication.shared.terminate(true)
    }

    private func sendAppLifecycleEvent(to channel: MyMethodChannel? = nil, state: String, completion: ((Any?) -> Void)? = nil) {
        print("sendAppLifecycleEvent=======: \(state)")

        let targetChannel = channel ?? (mainFlutterWindow?.contentViewController as? FlutterViewController)
            .map { MyMethodChannel(controller: $0) }

        targetChannel?.channel.invokeMethod("onAppLifecycleChanged", arguments: state, result: { result in
            completion?(result)
        })
    }
}
