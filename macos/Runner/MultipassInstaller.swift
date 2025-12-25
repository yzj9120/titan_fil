import AppKit
import Foundation

class MultipassInstaller {
    /// 检查并安装 Multipass
    static func installIfNeeded(completion: @escaping (Bool, String?) -> Void) {
        // 1. 检查是否已安装
        guard !isMultipassInstalled() else {
            completion(true, "Multipass is already installed")
            return
        }

        // 2. 获取安装包路径
        guard let pkgPath = Bundle.main.path(forResource: "multipass-1.15.1", ofType: "pkg") else {
            completion(false, "Multipass.pkg not found in app bundle")
            return
        }

        // 3. 执行静默安装
        installMultipass(pkgPath: pkgPath, completion: completion)
    }

    /// 检查 Multipass 是否已安装
    private static func isMultipassInstalled() -> Bool {
        let fileManager = FileManager.default
        return fileManager.fileExists(atPath: "/usr/local/bin/multipass")
    }

    /// 执行静默安装
    private static func installMultipass(pkgPath: String, completion: @escaping (Bool, String?) -> Void) {
        let installTask = Process()
        let outputPipe = Pipe()
        let errorPipe = Pipe()

        installTask.launchPath = "/usr/sbin/installer"
        installTask.arguments = ["-pkg", pkgPath, "-target", "/", "-verbose"]
        installTask.standardOutput = outputPipe
        installTask.standardError = errorPipe

        installTask.terminationHandler = { process in
            let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
            let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: outputData, encoding: .utf8) ?? ""
            let error = String(data: errorData, encoding: .utf8) ?? ""

            DispatchQueue.main.async {
                if process.terminationStatus == 0 {
                    completion(true, "Success:\n\(output)")
                } else {
                    completion(false, """
                    Exit Code: \(process.terminationStatus)
                    Output: \(output)
                    Error: \(error)
                    """)
                }
            }
        }

        do {
            try installTask.run()
        } catch {
            completion(false, "Process failed: \(error.localizedDescription)")
        }
    }
}
