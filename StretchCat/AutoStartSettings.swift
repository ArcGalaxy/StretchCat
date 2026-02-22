//
//  AutoStartSettings.swift
//  StretchCat
//
//  自动启动设置
//

import Foundation

enum AutoStartMode: String, CaseIterable, Codable {
    case manual = "手动启动"
    case timeOnly = "仅时间触发"
    case focusMode = "专注模式触发"
    case both = "时间+专注模式"
    
    var description: String {
        return self.rawValue
    }
}

class AutoStartSettings: ObservableObject {
    @Published var autoStartMode: AutoStartMode {
        didSet {
            if let encoded = try? JSONEncoder().encode(autoStartMode) {
                UserDefaults.standard.set(encoded, forKey: "autoStartMode")
            }
        }
    }
    
    @Published var startTime: Date {
        didSet {
            UserDefaults.standard.set(startTime, forKey: "startTime")
        }
    }
    
    @Published var endTime: Date {
        didSet {
            UserDefaults.standard.set(endTime, forKey: "endTime")
        }
    }
    
    @Published var selectedFocusModes: Set<String> {
        didSet {
            UserDefaults.standard.set(Array(selectedFocusModes), forKey: "selectedFocusModes")
        }
    }
    
    init() {
        // 加载自动启动模式
        if let data = UserDefaults.standard.data(forKey: "autoStartMode"),
           let mode = try? JSONDecoder().decode(AutoStartMode.self, from: data) {
            self.autoStartMode = mode
        } else {
            self.autoStartMode = .manual
        }
        
        // 加载时间设置，默认 9:00 - 18:00
        if let savedStartTime = UserDefaults.standard.object(forKey: "startTime") as? Date {
            self.startTime = savedStartTime
        } else {
            let calendar = Calendar.current
            self.startTime = calendar.date(from: DateComponents(hour: 9, minute: 0)) ?? Date()
        }
        
        if let savedEndTime = UserDefaults.standard.object(forKey: "endTime") as? Date {
            self.endTime = savedEndTime
        } else {
            let calendar = Calendar.current
            self.endTime = calendar.date(from: DateComponents(hour: 18, minute: 0)) ?? Date()
        }
        
        // 加载选中的专注模式
        if let modes = UserDefaults.standard.array(forKey: "selectedFocusModes") as? [String] {
            self.selectedFocusModes = Set(modes)
        } else {
            self.selectedFocusModes = []
        }
    }
    
    func shouldAutoStart(currentTime: Date, focusMode: String?) -> Bool {
        switch autoStartMode {
        case .manual:
            return false
            
        case .timeOnly:
            return isWithinTimeRange(currentTime)
            
        case .focusMode:
            guard let mode = focusMode else { return false }
            return selectedFocusModes.contains(mode)
            
        case .both:
            guard let mode = focusMode else { return false }
            return isWithinTimeRange(currentTime) && selectedFocusModes.contains(mode)
        }
    }
    
    func isWithinTimeRange(_ currentTime: Date) -> Bool {
        let calendar = Calendar.current
        let currentComponents = calendar.dateComponents([.hour, .minute], from: currentTime)
        let startComponents = calendar.dateComponents([.hour, .minute], from: startTime)
        let endComponents = calendar.dateComponents([.hour, .minute], from: endTime)
        
        guard let currentMinutes = currentComponents.hour.map({ $0 * 60 + (currentComponents.minute ?? 0) }),
              let startMinutes = startComponents.hour.map({ $0 * 60 + (startComponents.minute ?? 0) }),
              let endMinutes = endComponents.hour.map({ $0 * 60 + (endComponents.minute ?? 0) }) else {
            return false
        }
        
        return currentMinutes >= startMinutes && currentMinutes <= endMinutes
    }
}
