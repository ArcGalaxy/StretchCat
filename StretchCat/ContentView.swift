//
//  ContentView.swift
//  StretchCat
//
//  Created by 梁波 on 2026/2/22.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var settings = SettingsManager()
    @StateObject private var timerManager: TimerManager
    @StateObject private var focusModeManager = FocusModeManager()
    @StateObject private var autoStartSettings = AutoStartSettings()
    @StateObject private var focusModeSettings = FocusModeSettings()
    @State private var showingSettings = false
    private let breakWindowController = BreakWindowController()
    
    init() {
        let settings = SettingsManager()
        let focusModeSettings = FocusModeSettings()
        let focusModeManager = FocusModeManager()
        
        // 根据当前专注模式获取对应的时间设置
        let modeSettings = focusModeSettings.getSettings(for: focusModeManager.currentFocusMode)
        
        _timerManager = StateObject(wrappedValue: TimerManager(
            workMinutes: modeSettings.workMinutes,
            breakMinutes: modeSettings.breakMinutes
        ))
    }
    
    var body: some View {
        VStack(spacing: 30) {
            // 标题
            HStack {
                Image(systemName: "cat.fill")
                    .font(.system(size: 32))
                Text("伸展猫")
                    .font(.system(size: 32, weight: .bold))
            }
            .foregroundColor(.blue)
            
            // 自动启动状态提示
            if autoStartSettings.autoStartMode != .manual {
                HStack(spacing: 5) {
                    Image(systemName: "clock.badge.checkmark")
                        .foregroundColor(.green)
                    Text("自动模式: \(autoStartSettings.autoStartMode.description)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // 状态显示
            VStack(spacing: 10) {
                Text(statusText)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.secondary)
                
                Text(timerManager.timeString)
                    .font(.system(size: 72, weight: .bold, design: .monospaced))
                    .foregroundColor(timerColor)
            }
            
            // 进度条
            ProgressView(value: timerManager.progress)
                .progressViewStyle(LinearProgressViewStyle(tint: timerColor))
                .frame(width: 300)
            
            // 控制按钮
            HStack(spacing: 20) {
                if timerManager.state == .idle || timerManager.state == .paused {
                    Button(action: { timerManager.start() }) {
                        Label(timerManager.state == .idle ? "开始" : "继续", systemImage: "play.fill")
                            .frame(width: 100)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!canStart)
                }
                
                if timerManager.state == .working {
                    Button(action: { timerManager.pause() }) {
                        Label("暂停", systemImage: "pause.fill")
                            .frame(width: 100)
                    }
                    .buttonStyle(.bordered)
                }
                
                if timerManager.state != .idle {
                    Button(action: { timerManager.reset() }) {
                        Label("重置", systemImage: "arrow.counterclockwise")
                            .frame(width: 100)
                    }
                    .buttonStyle(.bordered)
                }
            }
            
            // 启动条件提示
            if !canStart && (timerManager.state == .idle || timerManager.state == .paused) {
                Text(startBlockedReason)
                    .font(.caption)
                    .foregroundColor(.orange)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Divider()
                .padding(.vertical, 10)
            
            // 设置按钮
            HStack(spacing: 15) {
                Button(action: { showingSettings.toggle() }) {
                    Label("设置", systemImage: "gearshape")
                }
                
                #if DEBUG
                Button(action: { timerManager.startBreak() }) {
                    Label("测试休息", systemImage: "ladybug")
                }
                .buttonStyle(.bordered)
                .tint(.orange)
                #endif
            }
        }
        .padding(40)
        .frame(minWidth: 400, minHeight: 500)
        .sheet(isPresented: $showingSettings) {
            SettingsView(
                settings: settings,
                timerManager: timerManager,
                focusModeManager: focusModeManager,
                autoStartSettings: autoStartSettings,
                focusModeSettings: focusModeSettings
            )
        }
        .onAppear {
            timerManager.onBreakTimeStart = {
                breakWindowController.show(timerManager: timerManager)
            }
            // 初始化时根据当前模式更新时间
            updateTimerForFocusMode(focusModeManager.currentFocusMode)
            checkAutoStart()
        }
        .onChange(of: timerManager.state) { newState in
            if newState == .idle {
                breakWindowController.hide()
            }
        }
        .onChange(of: focusModeManager.currentFocusMode) { newMode in
            updateTimerForFocusMode(newMode)
            checkShouldStopTimer()
        }
        .onReceive(Timer.publish(every: 60, on: .main, in: .common).autoconnect()) { _ in
            // 每分钟检查一次是否还满足运行条件
            checkShouldStopTimer()
        }
    }
    
    private func checkShouldStopTimer() {
        // 如果计时器正在运行，检查是否还满足条件
        if timerManager.state == .working || timerManager.state == .breaking {
            // 如果不满足启动条件，暂停计时器
            if !canStart {
                timerManager.pause()
                print("⚠️ 不再满足运行条件，已暂停计时器")
            }
        }
        // 如果计时器是暂停状态，且是因为条件不满足而暂停的，检查是否可以恢复
        else if timerManager.state == .paused {
            // 只有在自动模式下才自动恢复
            if autoStartSettings.autoStartMode != .manual && canStart {
                timerManager.start()
                print("✅ 条件重新满足，已自动恢复计时器")
            }
        }
        // 如果计时器是空闲状态，检查是否应该自动启动
        else if timerManager.state == .idle {
            checkAutoStart()
        }
    }
    
    private func updateTimerForFocusMode(_ mode: String?) {
        let modeSettings = focusModeSettings.getSettings(for: mode)
        timerManager.updateDurations(workMinutes: modeSettings.workMinutes, breakMinutes: modeSettings.breakMinutes)
        
        if timerManager.state == .idle {
            // 如果处于空闲状态，重置计时器
            timerManager.reset()
        }
    }
    
    private func checkAutoStart() {
        // 检查是否应该自动启动
        if autoStartSettings.shouldAutoStart(
            currentTime: Date(),
            focusMode: focusModeManager.currentFocusMode
        ) && timerManager.state == .idle {
            timerManager.start()
        }
    }
    
    private var statusText: String {
        switch timerManager.state {
        case .idle:
            return "准备开始"
        case .working:
            return "工作中..."
        case .breaking:
            return "休息时间"
        case .paused:
            return "已暂停"
        }
    }
    
    private var timerColor: Color {
        switch timerManager.state {
        case .working:
            return .blue
        case .breaking:
            return .green
        case .paused:
            return .orange
        case .idle:
            return .gray
        }
    }
    
    private var canStart: Bool {
        // 检查是否满足启动条件
        switch autoStartSettings.autoStartMode {
        case .manual:
            return true
            
        case .timeOnly:
            return autoStartSettings.isWithinTimeRange(Date())
            
        case .focusMode:
            return focusModeManager.currentFocusMode != nil &&
                   autoStartSettings.selectedFocusModes.contains(focusModeManager.currentFocusMode!)
            
        case .both:
            guard let currentMode = focusModeManager.currentFocusMode else {
                return false
            }
            return autoStartSettings.isWithinTimeRange(Date()) &&
                   autoStartSettings.selectedFocusModes.contains(currentMode)
        }
    }
    
    private var startBlockedReason: String {
        switch autoStartSettings.autoStartMode {
        case .manual:
            return ""
            
        case .timeOnly:
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            let start = formatter.string(from: autoStartSettings.startTime)
            let end = formatter.string(from: autoStartSettings.endTime)
            return "⏰ 当前不在设定的时间范围内（\(start) - \(end)）"
            
        case .focusMode:
            if focusModeManager.currentFocusMode == nil {
                return "🌙 请先激活一个专注模式"
            } else {
                return "🌙 当前专注模式未在选中列表中"
            }
            
        case .both:
            if focusModeManager.currentFocusMode == nil {
                return "🌙 请先激活一个专注模式"
            } else if !autoStartSettings.isWithinTimeRange(Date()) {
                let formatter = DateFormatter()
                formatter.timeStyle = .short
                let start = formatter.string(from: autoStartSettings.startTime)
                let end = formatter.string(from: autoStartSettings.endTime)
                return "⏰ 当前不在设定的时间范围内（\(start) - \(end)）"
            } else {
                return "🌙 当前专注模式未在选中列表中"
            }
        }
    }
}

#Preview {
    ContentView()
}
