//
//  SettingsView.swift
//  StretchCat
//
//  设置界面
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: SettingsManager
    @ObservedObject var timerManager: TimerManager
    @ObservedObject var focusModeManager: FocusModeManager
    @ObservedObject var autoStartSettings: AutoStartSettings
    @ObservedObject var focusModeSettings: FocusModeSettings
    @Environment(\.dismiss) var dismiss
    @State private var newModeName = ""
    @State private var showingAddMode = false
    @State private var selectedMode: String?
    
    var body: some View {
        VStack(spacing: 20) {
            Text("设置")
                .font(.system(size: 28, weight: .bold))
            
            ScrollView {
                VStack(alignment: .leading, spacing: 25) {
                    // 模式设置开关
                    GroupBox(label: Label("计时器模式", systemImage: "switch.2")) {
                        VStack(alignment: .leading, spacing: 15) {
                            Toggle("为每个专注模式单独设置时间", isOn: $focusModeSettings.usePerModeSettings)
                            
                            if focusModeSettings.usePerModeSettings {
                                Text("切换专注模式时，自动使用对应的时间设置")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            } else {
                                Text("所有模式使用统一的时间设置")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(10)
                    }
                    
                    // 基础设置或模式设置
                    if focusModeSettings.usePerModeSettings {
                        GroupBox(label: Label("专注模式时间设置", systemImage: "clock.badge.checkmark")) {
                            VStack(alignment: .leading, spacing: 15) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("选择专注模式")
                                        .font(.headline)
                                    
                                    Picker("", selection: $selectedMode) {
                                        Text("请选择一个模式").tag(nil as String?)
                                        ForEach(focusModeManager.availableFocusModes, id: \.self) { mode in
                                            HStack {
                                                Image(systemName: getModeIcon(for: mode))
                                                Text(translateModeName(mode))
                                            }
                                            .tag(mode as String?)
                                        }
                                    }
                                    .pickerStyle(.menu)
                                }
                                
                                if let mode = selectedMode {
                                    let modeSettings = focusModeSettings.getSettings(for: mode)
                                    
                                    Divider()
                                    
                                    HStack {
                                        Image(systemName: getModeIcon(for: mode))
                                            .font(.title)
                                            .foregroundColor(.blue)
                                        Text(translateModeName(mode))
                                            .font(.title3)
                                            .fontWeight(.semibold)
                                    }
                                    .padding(.vertical, 5)
                                    
                                    VStack(alignment: .leading, spacing: 15) {
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text("工作时长")
                                                .font(.headline)
                                            HStack {
                                                Slider(value: Binding(
                                                    get: { Double(modeSettings.workMinutes) },
                                                    set: { newValue in
                                                        focusModeSettings.setSettings(
                                                            for: mode,
                                                            workMinutes: Int(newValue),
                                                            breakMinutes: modeSettings.breakMinutes
                                                        )
                                                    }
                                                ), in: 5...120, step: 5)
                                                Text("\(modeSettings.workMinutes) 分钟")
                                                    .frame(width: 80, alignment: .trailing)
                                                    .font(.system(.body, design: .monospaced))
                                            }
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text("休息时长")
                                                .font(.headline)
                                            HStack {
                                                Slider(value: Binding(
                                                    get: { Double(modeSettings.breakMinutes) },
                                                    set: { newValue in
                                                        focusModeSettings.setSettings(
                                                            for: mode,
                                                            workMinutes: modeSettings.workMinutes,
                                                            breakMinutes: Int(newValue)
                                                        )
                                                    }
                                                ), in: 1...10, step: 1)
                                                Text("\(modeSettings.breakMinutes) 分钟")
                                                    .frame(width: 80, alignment: .trailing)
                                                    .font(.system(.body, design: .monospaced))
                                            }
                                        }
                                    }
                                } else {
                                    Text("👆 请先选择一个专注模式")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .frame(maxWidth: .infinity, alignment: .center)
                                        .padding()
                                }
                            }
                            .padding(10)
                        }
                    } else {
                        // 全局基础设置
                        GroupBox(label: Label("基础设置", systemImage: "timer")) {
                            VStack(alignment: .leading, spacing: 15) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("工作时长")
                                        .font(.headline)
                                    HStack {
                                        Slider(value: Binding(
                                            get: { Double(settings.workMinutes) },
                                            set: { settings.workMinutes = Int($0) }
                                        ), in: 5...120, step: 5)
                                        Text("\(settings.workMinutes) 分钟")
                                            .frame(width: 80, alignment: .trailing)
                                            .font(.system(.body, design: .monospaced))
                                    }
                                }
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("休息时长")
                                        .font(.headline)
                                    HStack {
                                        Slider(value: Binding(
                                            get: { Double(settings.breakMinutes) },
                                            set: { settings.breakMinutes = Int($0) }
                                        ), in: 1...10, step: 1)
                                        Text("\(settings.breakMinutes) 分钟")
                                            .frame(width: 80, alignment: .trailing)
                                            .font(.system(.body, design: .monospaced))
                                    }
                                }
                            }
                            .padding(10)
                        }
                    }
                    
                    // 自动启动设置
                    GroupBox(label: Label("自动启动", systemImage: "clock.arrow.circlepath")) {
                        VStack(alignment: .leading, spacing: 15) {
                            Picker("启动模式", selection: $autoStartSettings.autoStartMode) {
                                ForEach(AutoStartMode.allCases, id: \.self) { mode in
                                    Text(mode.description).tag(mode)
                                }
                            }
                            .pickerStyle(.segmented)
                            
                            if autoStartSettings.autoStartMode == .timeOnly || autoStartSettings.autoStartMode == .both {
                                Divider()
                                
                                HStack {
                                    Text("开始时间")
                                        .frame(width: 80, alignment: .leading)
                                    DatePicker("", selection: $autoStartSettings.startTime, displayedComponents: .hourAndMinute)
                                        .labelsHidden()
                                }
                                
                                HStack {
                                    Text("结束时间")
                                        .frame(width: 80, alignment: .leading)
                                    DatePicker("", selection: $autoStartSettings.endTime, displayedComponents: .hourAndMinute)
                                        .labelsHidden()
                                }
                            }
                            
                            if autoStartSettings.autoStartMode == .focusMode || autoStartSettings.autoStartMode == .both {
                                Divider()
                                
                                VStack(alignment: .leading, spacing: 10) {
                                    HStack {
                                        Text("选择专注模式")
                                            .font(.headline)
                                        Spacer()
                                        Button(action: { showAddModeAlert() }) {
                                            Image(systemName: "plus.circle")
                                        }
                                        .buttonStyle(.plain)
                                        .help("添加自定义专注模式")
                                    }
                                    
                                    if !focusModeManager.availableFocusModes.isEmpty {
                                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 120))], spacing: 10) {
                                            ForEach(focusModeManager.availableFocusModes, id: \.self) { mode in
                                                HStack {
                                                    Toggle(translateModeName(mode), isOn: Binding(
                                                        get: { autoStartSettings.selectedFocusModes.contains(mode) },
                                                        set: { isSelected in
                                                            if isSelected {
                                                                autoStartSettings.selectedFocusModes.insert(mode)
                                                            } else {
                                                                autoStartSettings.selectedFocusModes.remove(mode)
                                                            }
                                                        }
                                                    ))
                                                    .toggleStyle(.button)
                                                    
                                                    if focusModeManager.userDefinedModes.contains(mode) {
                                                        Button(action: {
                                                            focusModeManager.removeUserDefinedMode(mode)
                                                            autoStartSettings.selectedFocusModes.remove(mode)
                                                        }) {
                                                            Image(systemName: "xmark.circle.fill")
                                                                .foregroundColor(.red)
                                                        }
                                                        .buttonStyle(.plain)
                                                        .help("删除自定义模式")
                                                    }
                                                }
                                            }
                                        }
                                    }
                                    
                                    Divider()
                                    
                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text("当前专注模式")
                                                    .font(.subheadline)
                                                    .foregroundColor(.secondary)
                                                
                                                if let currentMode = focusModeManager.currentFocusMode {
                                                    HStack(spacing: 8) {
                                                        Image(systemName: getModeIcon(for: currentMode))
                                                            .foregroundColor(.purple)
                                                        Text(translateModeName(currentMode))
                                                            .font(.body)
                                                            .fontWeight(.medium)
                                                    }
                                                } else {
                                                    Text("当前没有激活的专注模式")
                                                        .foregroundColor(.secondary)
                                                }
                                            }
                                            
                                            Spacer()
                                            
                                            Button(action: {
                                                focusModeManager.refreshFocusModes()
                                            }) {
                                                Image(systemName: "arrow.clockwise")
                                            }
                                            .buttonStyle(.bordered)
                                            .controlSize(.small)
                                            .help("刷新专注模式状态")
                                        }
                                        
                                        Text("✅ 已禁用沙盒，可自动检测系统专注模式")
                                            .font(.caption)
                                            .foregroundColor(.green)
                                    }
                                    .padding(10)
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(8)
                                }
                            }
                        }
                        .padding(10)
                    }
                }
                .padding()
            }
            
            HStack(spacing: 20) {
                Button("取消") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                
                Button("保存") {
                    // 如果使用全局设置，更新 timerManager
                    if !focusModeSettings.usePerModeSettings {
                        timerManager.updateDurations(workMinutes: settings.workMinutes, breakMinutes: settings.breakMinutes)
                    } else {
                        // 如果使用专注模式设置，根据当前模式更新
                        let currentModeSettings = focusModeSettings.getSettings(for: focusModeManager.currentFocusMode)
                        timerManager.updateDurations(workMinutes: currentModeSettings.workMinutes, breakMinutes: currentModeSettings.breakMinutes)
                    }
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(30)
        .frame(width: 600, height: 650)
        .alert("添加自定义专注模式", isPresented: $showingAddMode) {
            TextField("模式名称", text: $newModeName)
            Button("取消", role: .cancel) {
                newModeName = ""
            }
            Button("添加") {
                if !newModeName.isEmpty {
                    focusModeManager.addUserDefinedMode(newModeName)
                    newModeName = ""
                }
            }
        } message: {
            Text("输入自定义专注模式的名称")
        }
    }
    
    private func showAddModeAlert() {
        showingAddMode = true
    }
    
    private func translateModeName(_ name: String) -> String {
        let translations: [String: String] = [
            "Do Not Disturb": "勿扰模式",
            "Work": "工作",
            "Personal": "个人时间",
            "Sleep": "睡眠",
            "Gaming": "游戏",
            "Fitness": "健身",
            "Reading": "阅读",
            "Driving": "驾驶"
        ]
        return translations[name] ?? name
    }
    
    private func getModeIcon(for mode: String) -> String {
        let icons: [String: String] = [
            "Do Not Disturb": "moon.fill",
            "勿扰模式": "moon.fill",
            "Work": "briefcase.fill",
            "工作": "briefcase.fill",
            "Personal": "person.fill",
            "个人时间": "person.fill",
            "个人": "person.fill",
            "Sleep": "bed.double.fill",
            "睡眠": "bed.double.fill",
            "Gaming": "gamecontroller.fill",
            "游戏": "gamecontroller.fill",
            "Fitness": "figure.run",
            "健身": "figure.run",
            "Reading": "book.fill",
            "阅读": "book.fill",
            "Driving": "car.fill",
            "驾驶": "car.fill"
        ]
        return icons[mode] ?? "circle.fill"
    }
}
