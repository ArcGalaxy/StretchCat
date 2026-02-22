//
//  SettingsManager.swift
//  StretchCat
//
//  设置管理器
//

import Foundation

class SettingsManager: ObservableObject {
    @Published var workMinutes: Int {
        didSet {
            UserDefaults.standard.set(workMinutes, forKey: "workMinutes")
        }
    }
    
    @Published var breakMinutes: Int {
        didSet {
            UserDefaults.standard.set(breakMinutes, forKey: "breakMinutes")
        }
    }
    
    init() {
        self.workMinutes = UserDefaults.standard.integer(forKey: "workMinutes")
        self.breakMinutes = UserDefaults.standard.integer(forKey: "breakMinutes")
        
        if workMinutes == 0 {
            workMinutes = 30
        }
        if breakMinutes == 0 {
            breakMinutes = 2
        }
    }
}
