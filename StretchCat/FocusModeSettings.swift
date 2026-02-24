//
//  FocusModeSettings.swift
//  StretchCat
//
//  每个专注模式的独立设置
//

import Foundation

struct ModeTimerSettings: Codable {
    var workMinutes: Int
    var breakMinutes: Int
    
    init(workMinutes: Int = 30, breakMinutes: Int = 2) {
        self.workMinutes = workMinutes
        self.breakMinutes = breakMinutes
    }
}

class FocusModeSettings: ObservableObject {
    @Published var modeSettings: [String: ModeTimerSettings] = [:] {
        didSet {
            saveSettings()
        }
    }
    
    @Published var usePerModeSettings: Bool {
        didSet {
            UserDefaults.standard.set(usePerModeSettings, forKey: "usePerModeSettings")
        }
    }
    
    init() {
        self.usePerModeSettings = UserDefaults.standard.bool(forKey: "usePerModeSettings")
        loadSettings()
    }
    
    func getSettings(for mode: String?) -> ModeTimerSettings {
        guard usePerModeSettings, let mode = mode else {
            // 返回全局默认设置（从 SettingsManager 读取）
            let workMinutes = UserDefaults.standard.integer(forKey: "workMinutes")
            let breakMinutes = UserDefaults.standard.integer(forKey: "breakMinutes")
            return ModeTimerSettings(
                workMinutes: workMinutes > 0 ? workMinutes : 30,
                breakMinutes: breakMinutes > 0 ? breakMinutes : 2
            )
        }
        
        return modeSettings[mode] ?? ModeTimerSettings()
    }
    
    func setSettings(for mode: String, workMinutes: Int, breakMinutes: Int) {
        modeSettings[mode] = ModeTimerSettings(workMinutes: workMinutes, breakMinutes: breakMinutes)
    }
    
    private func saveSettings() {
        if let encoded = try? JSONEncoder().encode(modeSettings) {
            UserDefaults.standard.set(encoded, forKey: "focusModeSettings")
        }
    }
    
    private func loadSettings() {
        if let data = UserDefaults.standard.data(forKey: "focusModeSettings"),
           let decoded = try? JSONDecoder().decode([String: ModeTimerSettings].self, from: data) {
            modeSettings = decoded
        }
    }
}
