//
//  FocusModeManager.swift
//  StretchCat
//
//  专注模式管理器
//

import Foundation
import Combine
import AppKit

class FocusModeManager: ObservableObject {
    @Published var availableFocusModes: [String] = []
    @Published var currentFocusMode: String?
    @Published var userDefinedModes: [String] = []
    @Published var isDoNotDisturbActive: Bool = false
    
    private var timer: Timer?
    private let focusModesPath = NSHomeDirectory() + "/Library/DoNotDisturb/DB/ModeConfigurations.json"
    private let assertionsPath = NSHomeDirectory() + "/Library/DoNotDisturb/DB/Assertions.json"
    private var fileMonitor: DispatchSourceFileSystemObject?
    
    init() {
        loadUserDefinedModes()
        loadSystemFocusModes()
        setupNotificationObserver()
        setupFileMonitoring()
        startMonitoring()
    }
    
    deinit {
        timer?.invalidate()
        fileMonitor?.cancel()
        DistributedNotificationCenter.default().removeObserver(self)
    }
    
    private func setupFileMonitoring() {
        // 监控 Assertions.json 文件变化
        let fileDescriptor = open(assertionsPath, O_EVTONLY)
        guard fileDescriptor >= 0 else {
            print("⚠️ 无法打开文件进行监控: \(assertionsPath)")
            return
        }
        
        let queue = DispatchQueue(label: "com.stretchcat.focusmode.monitor")
        fileMonitor = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fileDescriptor,
            eventMask: [.write, .extend, .attrib],
            queue: queue
        )
        
        fileMonitor?.setEventHandler { [weak self] in
            print("📁 检测到断言文件变化")
            DispatchQueue.main.async {
                self?.checkCurrentFocusMode()
            }
        }
        
        fileMonitor?.setCancelHandler {
            close(fileDescriptor)
        }
        
        fileMonitor?.resume()
        print("✅ 已启动文件监控")
    }
    
    private func loadSystemFocusModes() {
        // 尝试从系统配置文件读取用户配置的专注模式
        var systemModes: [String] = []
        var modeIdentifierMap: [String: String] = [:] // 标识符 -> 名称映射
        
        if let data = try? Data(contentsOf: URL(fileURLWithPath: focusModesPath)),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            
            print("📄 成功读取配置文件")
            
            if let dataArray = json["data"] as? [[String: Any]],
               let firstData = dataArray.first,
               let modeConfigurations = firstData["modeConfigurations"] as? [String: Any] {
                
                print("📱 读取到 \(modeConfigurations.count) 个专注模式配置")
                
                for (modeId, configValue) in modeConfigurations {
                    if let config = configValue as? [String: Any],
                       let mode = config["mode"] as? [String: Any] {
                        
                        let name = mode["name"] as? String ?? ""
                        let identifier = mode["modeIdentifier"] as? String ?? ""
                        
                        if !name.isEmpty && !identifier.isEmpty {
                            systemModes.append(name)
                            modeIdentifierMap[identifier] = name
                            print("  ✅ 映射: \(identifier) -> \(name)")
                        }
                    }
                }
                
                // 保存映射关系
                if !modeIdentifierMap.isEmpty {
                    UserDefaults.standard.set(modeIdentifierMap, forKey: "focusModeIdentifierMap")
                    print("💾 保存了 \(modeIdentifierMap.count) 个模式映射")
                }
            } else {
                print("⚠️ 无法解析 modeConfigurations")
            }
        } else {
            print("⚠️ 无法读取配置文件: \(focusModesPath)")
        }
        
        // 如果无法读取，使用默认列表
        if systemModes.isEmpty {
            systemModes = [
                "勿扰模式",
                "工作",
                "个人时间",
                "睡眠",
                "游戏",
                "健身",
                "阅读",
                "驾驶"
            ]
        }
        
        // 合并系统模式和用户自定义模式
        availableFocusModes = Array(Set(systemModes + userDefinedModes)).sorted()
        
        print("📱 加载的专注模式列表: \(availableFocusModes)")
    }
    
    private func loadUserDefinedModes() {
        if let modes = UserDefaults.standard.array(forKey: "userDefinedFocusModes") as? [String] {
            userDefinedModes = modes
        }
    }
    
    func addUserDefinedMode(_ modeName: String) {
        guard !modeName.isEmpty, !userDefinedModes.contains(modeName) else { return }
        userDefinedModes.append(modeName)
        saveUserDefinedModes()
        loadSystemFocusModes()
    }
    
    func removeUserDefinedMode(_ modeName: String) {
        userDefinedModes.removeAll { $0 == modeName }
        saveUserDefinedModes()
        loadSystemFocusModes()
    }
    
    private func saveUserDefinedModes() {
        UserDefaults.standard.set(userDefinedModes, forKey: "userDefinedFocusModes")
    }
    
    private func setupNotificationObserver() {
        let center = DistributedNotificationCenter.default()
        
        // 监听专注模式变化
        center.addObserver(
            self,
            selector: #selector(focusModeChanged),
            name: NSNotification.Name("com.apple.controlcenter.FocusModes.changed"),
            object: nil
        )
        
        center.addObserver(
            self,
            selector: #selector(focusModeChanged),
            name: NSNotification.Name("com.apple.donotdisturb.changed"),
            object: nil
        )
        
        // 监听断言变化（专注模式激活状态）
        center.addObserver(
            self,
            selector: #selector(focusModeChanged),
            name: NSNotification.Name("com.apple.donotdisturb.assertions.changed"),
            object: nil
        )
    }
    
    @objc private func focusModeChanged(_ notification: Notification) {
        print("🔔 专注模式通知触发: \(notification.name)")
        DispatchQueue.main.async {
            self.checkCurrentFocusMode()
        }
    }
    
    private func startMonitoring() {
        // 每5秒检查一次专注模式（作为备用）
        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.checkCurrentFocusMode()
        }
        checkCurrentFocusMode()
    }
    
    private func checkCurrentFocusMode() {
        print("🔍 开始检查专注模式...")
        
        // 方法1: 尝试通过 AppleScript 获取
        let script = """
        tell application "System Events"
            try
                return do shell script "defaults read ~/Library/Preferences/com.apple.controlcenter.plist FocusModes 2>/dev/null || echo ''"
            end try
        end tell
        """
        
        if let appleScript = NSAppleScript(source: script) {
            var error: NSDictionary?
            let result = appleScript.executeAndReturnError(&error)
            if error == nil, let output = result.stringValue {
                print("📱 AppleScript 结果: \(output)")
            }
        }
        
        // 方法2: 尝试读取 plist 文件
        let plistPath = NSHomeDirectory() + "/Library/Preferences/com.apple.controlcenter.plist"
        if let plistData = try? Data(contentsOf: URL(fileURLWithPath: plistPath)),
           let plist = try? PropertyListSerialization.propertyList(from: plistData, format: nil) as? [String: Any] {
            print("📋 控制中心 plist 键: \(plist.keys)")
            
            // 查找专注模式相关的键
            for (key, value) in plist {
                if key.lowercased().contains("focus") || key.lowercased().contains("dnd") || key.lowercased().contains("disturb") {
                    print("  🔑 \(key): \(value)")
                }
            }
        }
        
        // 方法3: 使用 JXA (JavaScript for Automation)
        let jxaScript = """
        (() => {
            const app = Application.currentApplication();
            app.includeStandardAdditions = true;
            
            try {
                // 尝试读取专注模式状态
                const result = app.doShellScript('plutil -extract "NSStatusItem Visible FocusModes" raw ~/Library/Preferences/com.apple.controlcenter.plist 2>/dev/null || echo "false"');
                return result;
            } catch (e) {
                return "error: " + e.toString();
            }
        })();
        """
        
        if let script = NSAppleScript(source: "use framework \"Foundation\"\n" + jxaScript) {
            var error: NSDictionary?
            let result = script.executeAndReturnError(&error)
            if error == nil {
                print("🔧 JXA 结果: \(result.stringValue ?? "nil")")
            } else {
                print("❌ JXA 错误: \(error ?? [:])")
            }
        }
        
        // 方法4: 尝试读取断言文件
        let assertionsURL = URL(fileURLWithPath: assertionsPath)
        print("📂 断言文件路径: \(assertionsPath)")
        
        if FileManager.default.fileExists(atPath: assertionsPath) {
            print("✅ 断言文件存在")
            
            // 检查文件权限
            if FileManager.default.isReadableFile(atPath: assertionsPath) {
                print("✅ 文件可读")
            } else {
                print("❌ 文件不可读，可能需要完全磁盘访问权限")
            }
        } else {
            print("⚠️ 断言文件不存在")
        }
        
        guard let data = try? Data(contentsOf: assertionsURL) else {
            print("❌ 无法读取断言文件")
            
            // 降级方案：使用手动设置
            isDoNotDisturbActive = false
            if let manualMode = UserDefaults.standard.string(forKey: "manualCurrentFocusMode") {
                currentFocusMode = manualMode
                print("📝 使用手动设置的模式: \(manualMode)")
            } else {
                currentFocusMode = nil
            }
            return
        }
        
        print("✅ 成功读取断言文件，大小: \(data.count) bytes")
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            print("❌ 无法解析 JSON")
            isDoNotDisturbActive = false
            return
        }
        
        print("📋 JSON 根键: \(json.keys)")
        
        guard let assertions = json["data"] as? [[String: Any]] else {
            print("❌ 无法获取 data 数组")
            isDoNotDisturbActive = false
            return
        }
        
        print("📊 找到 \(assertions.count) 个断言")
        
        // 查找当前激活的断言
        for (index, assertion) in assertions.enumerated() {
            print("🔎 检查断言 #\(index): \(assertion.keys)")
            
            // 检查 storeAssertionRecords
            if let records = assertion["storeAssertionRecords"] as? [[String: Any]] {
                print("  📝 找到 \(records.count) 个断言记录")
                
                for (recordIndex, record) in records.enumerated() {
                    print("    🔍 记录 #\(recordIndex): \(record.keys)")
                    
                    // 查找 assertionDetails
                    if let details = record["assertionDetails"] as? [String: Any] {
                        print("      📋 assertionDetails: \(details.keys)")
                        
                        // 正确的键名
                        if let modeIdentifier = details["assertionDetailsModeIdentifier"] as? String {
                            print("      🎯 找到模式标识符: \(modeIdentifier)")
                            
                            let modeName = extractModeName(from: modeIdentifier)
                            
                            if !modeName.isEmpty {
                                print("✅ 检测到激活的专注模式: \(modeName)")
                                isDoNotDisturbActive = true
                                setCurrentFocusMode(modeName)
                                return
                            }
                        }
                        
                        // 兼容旧的键名
                        if let modeIdentifier = details["modeIdentifier"] as? String {
                            print("      🎯 找到模式标识符: \(modeIdentifier)")
                            
                            let modeName = extractModeName(from: modeIdentifier)
                            
                            if !modeName.isEmpty {
                                print("✅ 检测到激活的专注模式: \(modeName)")
                                isDoNotDisturbActive = true
                                setCurrentFocusMode(modeName)
                                return
                            }
                        }
                    }
                    
                    // 也检查 storeAssertionRecordDetails
                    if let details = record["storeAssertionRecordDetails"] as? [String: Any] {
                        print("      📋 storeAssertionRecordDetails: \(details.keys)")
                        
                        if let modeIdentifier = details["modeIdentifier"] as? String {
                            print("      🎯 找到模式标识符: \(modeIdentifier)")
                            
                            let modeName = extractModeName(from: modeIdentifier)
                            
                            if !modeName.isEmpty {
                                print("✅ 检测到激活的专注模式: \(modeName)")
                                isDoNotDisturbActive = true
                                setCurrentFocusMode(modeName)
                                return
                            }
                        }
                    }
                    
                    // 打印整个记录以便调试
                    if let jsonData = try? JSONSerialization.data(withJSONObject: record, options: .prettyPrinted),
                       let jsonString = String(data: jsonData, encoding: .utf8) {
                        print("      📄 完整记录: \(jsonString)")
                    }
                }
            }
            
            // 旧的检查方式（兼容）
            if let details = assertion["storeAssertionRecordDetails"] as? [String: Any] {
                print("  📝 断言详情: \(details.keys)")
                
                if let modeIdentifier = details["modeIdentifier"] as? String {
                    print("  🎯 找到模式标识符: \(modeIdentifier)")
                    
                    let modeName = extractModeName(from: modeIdentifier)
                    
                    if !modeName.isEmpty {
                        print("✅ 检测到激活的专注模式: \(modeName)")
                        isDoNotDisturbActive = true
                        setCurrentFocusMode(modeName)
                        return
                    }
                }
            }
        }
        
        print("❌ 未检测到激活的专注模式")
        isDoNotDisturbActive = false
        
        if let manualMode = UserDefaults.standard.string(forKey: "manualCurrentFocusMode") {
            currentFocusMode = manualMode
        } else {
            currentFocusMode = nil
        }
    }
    
    private func extractModeName(from identifier: String) -> String {
        print("  🔤 提取模式名称，标识符: \(identifier)")
        
        // 首先尝试从保存的映射中查找
        if let modeMap = UserDefaults.standard.dictionary(forKey: "focusModeIdentifierMap") as? [String: String],
           let name = modeMap[identifier] {
            print("  ✅ 从映射表匹配到模式: \(name)")
            return name
        }
        
        print("  ⚠️ 映射表中未找到，尝试其他方法")
        
        // 从标识符中提取模式名称（备用方案）
        let modeMap: [String: String] = [
            "default": "勿扰模式",
            "work": "工作",
            "personal": "个人时间",
            "sleep": "睡眠",
            "gaming": "游戏",
            "fitness": "健身",
            "reading": "阅读",
            "driving": "驾驶"
        ]
        
        let lowerIdentifier = identifier.lowercased()
        
        for (key, value) in modeMap {
            if lowerIdentifier.contains(key) {
                print("  ✅ 匹配到模式: \(value)")
                return value
            }
        }
        
        print("  ❌ 无法提取模式名称")
        return ""
    }
    
    func setCurrentFocusMode(_ modeName: String?) {
        currentFocusMode = modeName
        if let mode = modeName {
            UserDefaults.standard.set(mode, forKey: "manualCurrentFocusMode")
        } else {
            UserDefaults.standard.removeObject(forKey: "manualCurrentFocusMode")
        }
    }
    
    func isFocusModeActive(_ modeName: String) -> Bool {
        return currentFocusMode == modeName
    }
    
    // 刷新专注模式列表
    func refreshFocusModes() {
        loadSystemFocusModes()
        checkCurrentFocusMode()
    }
}
