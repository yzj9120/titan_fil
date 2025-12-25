
import FlutterMacOS
import Foundation

class MyMethodChannel {
    let channelName: String = "com.titan_fil.titanNetwork/defineChannel"

    var channel: FlutterMethodChannel
    var appVer: String? = ""

    var relaunchHandler: (() -> Void)?

    init(controller: FlutterViewController) {
        channel = FlutterMethodChannel(name: channelName, binaryMessenger: controller.engine.binaryMessenger)
    }

    func registerFunc() {
        channel.setMethodCallHandler { call, result in
            switch call.method {
            case "getAvailableDiskSpace":
                result(self.getUsedDiskSpace())
            case "getFreeDiskSpace":
                result(self.getFreeDiskSpace())
            case "getDiskCapacity":
                result(self.getDiskCapacity())
            case "getTotalDiskSpaceReadable":
                result(self.getTotalDiskSpaceReadable())
            case "getFreeDiskSpaceReadable":
                result(self.getFreeDiskSpaceReadable())
            case "getSizeReadable":
                if let arguments = call.arguments as? [String: Any],
                   let folderPath = arguments["folderPath"] as? String
                {
                    result(self.folderSize(atPath: folderPath))
                } else {
                    result(FlutterError(code: "INVALID_ARGUMENT", message: "Missing or invalid arguments", details: nil))
                }
            case "isMultipassInstalled":
                let isInstalled = self.checkMultipassInstallation()
                result(isInstalled)
            case "installMultipass":
                self.installMultipass(result: result)
            case "installSbinMultipass":
                MultipassInstaller.installIfNeeded { success, message in
                    result([
                        "success": success,
                        "message": message ?? "",
                    ])
                }
            case "relaunchApp":
                self.relaunchHandler?()
            case "relaunchMac":
                self.restartMac(result: result)
            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }

    private func restartMac(result: @escaping FlutterResult) {
        let appleScript = """
        do shell script "shutdown -r now" with administrator privileges
        """

        if let script = NSAppleScript(source: appleScript) {
            var errorDict: NSDictionary?
            script.executeAndReturnError(&errorDict)

            if let error = errorDict {
                result(FlutterError(code: "RESTART_FAILED", message: "AppleScript error: \(error)", details: nil))
            } else {
                result("Mac is restarting...")
            }
        } else {
            result(FlutterError(code: "SCRIPT_ERROR", message: "Failed to create AppleScript", details: nil))
        }
    }

    private func checkMultipassInstallation() -> Bool {
        // 检查 /usr/local/bin/multipass 是否存在
        let fileManager = FileManager.default
        return fileManager.fileExists(atPath: "/usr/local/bin/multipass")
    }

    private func installMultipass(result: @escaping FlutterResult) {
        // 获取资源路径中的 pkg 文件
        guard let pkgPath = Bundle.main.path(forResource: "multipass-1.15.1", ofType: "pkg") else {
            result(false)
            return
        }

        let installTask = Process()
        installTask.launchPath = "/usr/bin/open"
        installTask.arguments = [pkgPath]

        installTask.terminationHandler = { process in
            DispatchQueue.main.async {
                result(process.terminationStatus == 0)
            }
        }

        do {
            try installTask.run()
        } catch {
            result(false)
        }
    }

    // 总计空间
    func getDiskCapacity() -> Int {
        let totalSize = getTotalDiskSpace()
        let tempValue = Int(totalSize) / 1_000_000_000
        return Int(floor(Double(tempValue)))
    }

    // 可用空间
    func getFreeDiskSpace() -> Int {
        let leftSize = getLeftDiskSpace()
        let tempValue = Int(leftSize) / 1_000_000_000
        return Int(floor(Double(tempValue)))
    }

    // 已使用空间
    func getUsedDiskSpace() -> Int {
        let totalSize = getTotalDiskSpace()
        let leftSize = getLeftDiskSpace()
        let tempValue = Int(totalSize - leftSize) / 1_000_000_000
        return Int(floor(Double(tempValue)))
    }

    func getTotalDiskSpace() -> Int64 {
        guard let systemAttributes = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory() as String),
              let space = (systemAttributes[FileAttributeKey.systemSize] as? NSNumber)?.int64Value else { return 0 }
        return space
    }

    func getLeftDiskSpace() -> Int64 {
        if let space = try? URL(fileURLWithPath: NSHomeDirectory() as String).resourceValues(forKeys: [URLResourceKey.volumeAvailableCapacityForImportantUsageKey]).volumeAvailableCapacityForImportantUsage {
            return space
        } else {
            return 0
        }
    }

    // 获取总磁盘空间并以人类可读格式返回
    func getTotalDiskSpaceReadable() -> String {
        let totalSpace = getTotalDiskSpace()
        return bytesToHumanReadable(totalSpace)
    }

    // 获取剩余磁盘空间并以人类可读格式返回
    func getFreeDiskSpaceReadable() -> String {
        let freeSpace = getLeftDiskSpace()
        return bytesToHumanReadable(freeSpace)
    }

    // 将字节数转换为人类可读格式
    func bytesToHumanReadable(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useBytes, .useKB, .useMB, .useGB, .useTB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }

    // 获取文件夹大小并以人类可读格式返回
    func getSizeReadable(ofFolderAtPath path: String) -> String {
        let folderSize = calculateSize(ofFolderAtPath: path)
        return bytesToHumanReadable(folderSize)
    }

    func folderSize(atPath path: String) -> String? {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/du")
        task.arguments = ["-sh", path]

        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe

        do {
            try task.run()
        } catch {
            print("Error running du command: \(error)")
            return nil
        }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        task.waitUntilExit()

        guard let output = String(data: data, encoding: .utf8) else {
            return nil
        }

        let components = output.split(separator: "\t")
        guard let sizeString = components.first else {
            return nil
        }
        return String(sizeString)
    }

    // 计算文件夹大小
    func calculateSize(ofFolderAtPath path: String) -> Int64 {
        let fileManager = FileManager.default
        var folderSize: Int64 = 0

        guard let contents = try? fileManager.contentsOfDirectory(atPath: path) else {
            return 0
        }

        for content in contents {
            let contentPath = (path as NSString).appendingPathComponent(content)
            var isDirectory: ObjCBool = false
            if fileManager.fileExists(atPath: contentPath, isDirectory: &isDirectory) {
                if isDirectory.boolValue {
                    folderSize += calculateSize(ofFolderAtPath: contentPath)
                } else {
                    if let attributes = try? fileManager.attributesOfItem(atPath: contentPath) {
                        if let fileSize = attributes[.size] as? Int64 {
                            folderSize += fileSize
                        }
                    }
                }
            }
        }

        return folderSize
    }
}
