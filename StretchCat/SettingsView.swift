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
    @Environment(\.dismiss) var dismiss
    @State private var newModeName = ""
    @State private var showingAddMode = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("设置")
                .font(.system(size: 28, weight: .bold))
            
            ScrollView {
                VStack(alignment: .leading, spacing: 25) {
                    // 基础设置
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
                                                    Toggle(mode, isOn: Binding(
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
                                                
                                                if focusModeManager.isDoNotDisturbActive {
                                                    HStack(spacing: 4) {
                                                        Image(systemName: "checkmark.circle.fill")
                                                            .foregroundColor(.green)
                                                        Text("系统专注模式已激活")
                                                            .font(.caption)
                                                            .foregroundColor(.green)
                                                    }
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
                                        
                                        HStack {
                                            if let currentMode = focusModeManager.currentFocusMode {
                                                HStack {
                                                    Image(systemName: "moon.fill")
                                                        .foregroundColor(.purple)
                                                    Text(currentMode)
                                                        .font(.body)
                                                }
                                                
                                                Button("清除") {
                                                    focusModeManager.setCurrentFocusMode(nil)
                                                }
                                                .buttonStyle(.bordered)
                                                .controlSize(.small)
                                            } else {
                                                Text("未激活")
                                                    .foregroundColor(.secondary)
                                            }
                                            
                                            Spacer()
                                            
                                            Menu("手动设置") {
                                                ForEach(focusModeManager.availableFocusModes, id: \.self) { mode in
                                                    Button(mode) {
                                                        focusModeManager.setCurrentFocusMode(mode)
                                                    }
                                                }
                                            }
                                            .buttonStyle(.bordered)
                                            .controlSize(.small)
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
                    timerManager.updateDurations(workMinutes: settings.workMinutes, breakMinutes: settings.breakMinutes)
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
}
