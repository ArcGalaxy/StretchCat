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
        
        // 根据当前设置模式获取正确的时间
        let workMinutes: Int
        let breakMinutes: Int
        
        if focusModeSettings.usePerModeSettings, let currentMode = focusModeManager.currentFocusMode {
            let modeSettings = focusModeSettings.getSettings(for: currentMode)
            workMinutes = modeSettings.workMinutes
            breakMinutes = modeSettings.breakMinutes
        } else {
            workMinutes = settings.workMinutes
            breakMinutes = settings.breakMinutes
        }
        
        _timerManager = StateObject(wrappedValue: TimerManager(
            workMinutes: workMinutes,
            breakMinutes: breakMinutes
        ))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 顶部标题栏
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "cat.fill")
                        .font(.system(size: 20))
                    Text("伸展猫")
                        .font(.system(size: 20, weight: .semibold))
                }
                .foregroundColor(.blue)
                
                Spacer()
                
                Button(action: { 
                    showingSettings.toggle()
                    print("设置按钮被点击")
                }) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 18))
                        .foregroundColor(.secondary)
                        .frame(width: 32, height: 32)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help("设置")
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(Color(nsColor: .controlBackgroundColor))
            
            Divider()
            
            ScrollView {
                VStack(spacing: 24) {
                    // 当前模式显示
                    if let currentMode = focusModeManager.currentFocusMode {
                        HStack(spacing: 6) {
                            Image(systemName: getModeIcon(for: currentMode))
                                .font(.system(size: 14))
                            Text(translateModeName(currentMode))
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundColor(.purple)
                        .padding(.top, 20)
                    }
                    
                    // 圆形进度 + 倒计时
                    ZStack {
                        // 背景圆环
                        Circle()
                            .stroke(Color.gray.opacity(0.2), lineWidth: 12)
                            .frame(width: 200, height: 200)
                        
                        // 进度圆环
                        Circle()
                            .trim(from: 0, to: timerManager.progress)
                            .stroke(timerColor, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                            .frame(width: 200, height: 200)
                            .rotationEffect(.degrees(-90))
                            .animation(.linear(duration: 0.5), value: timerManager.progress)
                        
                        // 中心内容
                        VStack(spacing: 8) {
                            Text(timerManager.timeString)
                                .font(.system(size: 48, weight: .bold, design: .monospaced))
                                .foregroundColor(timerColor)
                            
                            Text(statusText)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 20)
                    
                    // 控制按钮
                    HStack(spacing: 16) {
                        if timerManager.state == .idle || timerManager.state == .paused {
                            Button(action: { timerManager.start() }) {
                                Label(timerManager.state == .idle ? "开始" : "继续", systemImage: "play.fill")
                                    .frame(width: 100)
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.large)
                            .disabled(!canStart)
                        }
                        
                        if timerManager.state == .working {
                            Button(action: { timerManager.pause() }) {
                                Label("暂停", systemImage: "pause.fill")
                                    .frame(width: 100)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.large)
                        }
                        
                        if timerManager.state != .idle {
                            Button(action: { timerManager.reset() }) {
                                Label("重置", systemImage: "arrow.counterclockwise")
                                    .frame(width: 100)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.large)
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
                        .padding(.vertical, 8)
                    
                    // 配置区域
                    VStack(alignment: .leading, spacing: 16) {
                        Label("⏱️ 配置", systemImage: "")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.secondary)
                        
                        VStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("工作")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                HStack(spacing: 8) {
                                    Slider(value: Binding(
                                        get: { Double(getCurrentWorkMinutes()) },
                                        set: { newValue in
                                            updateCurrentSettings(workMinutes: Int(newValue), breakMinutes: nil)
                                        }
                                    ), in: 5...120, step: 5)
                                    Text("\(getCurrentWorkMinutes())min")
                                        .font(.system(size: 12, design: .monospaced))
                                        .frame(width: 45, alignment: .trailing)
                                }
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("休息")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                HStack(spacing: 8) {
                                    Slider(value: Binding(
                                        get: { Double(getCurrentBreakMinutes()) },
                                        set: { newValue in
                                            updateCurrentSettings(workMinutes: nil, breakMinutes: Int(newValue))
                                        }
                                    ), in: 1...10, step: 1)
                                    Text("\(getCurrentBreakMinutes())min")
                                        .font(.system(size: 12, design: .monospaced))
                                        .frame(width: 45, alignment: .trailing)
                                }
                            }
                        }
                        
                        if focusModeSettings.usePerModeSettings && focusModeManager.currentFocusMode != nil {
                            Toggle("☑️ 仅此模式使用", isOn: .constant(true))
                                .font(.caption)
                                .disabled(true)
                        }
                    }
                    .padding(16)
                    .background(Color(nsColor: .controlBackgroundColor))
                    .cornerRadius(8)
                    
                    // 自动运行状态
                    if autoStartSettings.autoStartMode != .manual {
                        HStack(spacing: 6) {
                            Image(systemName: "clock.badge.checkmark")
                                .font(.system(size: 12))
                            Text("🤖 自动: \(autoStartSettings.autoStartMode.description)")
                                .font(.system(size: 12))
                            if autoStartSettings.autoStartMode == .timeOnly || autoStartSettings.autoStartMode == .both {
                                let formatter = DateFormatter()
                                let _ = formatter.timeStyle = .short
                                Text("(\(formatter.string(from: autoStartSettings.startTime))-\(formatter.string(from: autoStartSettings.endTime)))")
                                    .font(.system(size: 12))
                            }
                        }
                        .foregroundColor(.secondary)
                    }
                    
                    // 今日统计
                    if autoStartSettings.autoStartMode == .timeOnly || autoStartSettings.autoStartMode == .both {
                        let stats = calculateTodayStats()
                        HStack(spacing: 6) {
                            Image(systemName: "chart.bar.fill")
                                .font(.system(size: 12))
                            Text("📊 今日 \(stats.completed)/\(stats.total) 周期")
                                .font(.system(size: 12))
                            if stats.remaining > 0 {
                                Text("| 还需 \(String(format: "%.1f", stats.remaining)) 小时")
                                    .font(.system(size: 12))
                            }
                        }
                        .foregroundColor(.secondary)
                    }
                    
                    #if DEBUG
                    Button(action: { timerManager.startBreak() }) {
                        Label("测试休息", systemImage: "ladybug")
                    }
                    .buttonStyle(.bordered)
                    .tint(.orange)
                    .controlSize(.small)
                    .padding(.top, 8)
                    #endif
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
            }
        }
        .frame(minWidth: 360, idealWidth: 380, maxWidth: 400, minHeight: 650, idealHeight: 700)
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
            // 当状态不是休息时，关闭休息窗口
            if newState != .breaking {
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
        .onChange(of: focusModeSettings.usePerModeSettings) { _ in
            // 当切换设置模式时，更新计时器
            updateTimerForFocusMode(focusModeManager.currentFocusMode)
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
        // 根据当前设置模式获取正确的时间
        let workMinutes: Int
        let breakMinutes: Int
        
        if focusModeSettings.usePerModeSettings, let mode = mode {
            let modeSettings = focusModeSettings.getSettings(for: mode)
            workMinutes = modeSettings.workMinutes
            breakMinutes = modeSettings.breakMinutes
        } else {
            workMinutes = settings.workMinutes
            breakMinutes = settings.breakMinutes
        }
        
        timerManager.updateDurations(workMinutes: workMinutes, breakMinutes: breakMinutes)
        
        if timerManager.state == .idle {
            // 如果处于空闲状态，重置计时器
            timerManager.reset()
        }
    }
    
    private func getCurrentWorkMinutes() -> Int {
        if focusModeSettings.usePerModeSettings, let mode = focusModeManager.currentFocusMode {
            return focusModeSettings.getSettings(for: mode).workMinutes
        } else {
            return settings.workMinutes
        }
    }
    
    private func getCurrentBreakMinutes() -> Int {
        if focusModeSettings.usePerModeSettings, let mode = focusModeManager.currentFocusMode {
            return focusModeSettings.getSettings(for: mode).breakMinutes
        } else {
            return settings.breakMinutes
        }
    }
    
    private func updateCurrentSettings(workMinutes: Int?, breakMinutes: Int?) {
        if focusModeSettings.usePerModeSettings, let mode = focusModeManager.currentFocusMode {
            // 使用每个模式的独立设置
            let current = focusModeSettings.getSettings(for: mode)
            focusModeSettings.setSettings(
                for: mode,
                workMinutes: workMinutes ?? current.workMinutes,
                breakMinutes: breakMinutes ?? current.breakMinutes
            )
        } else {
            // 使用全局设置
            if let work = workMinutes {
                settings.workMinutes = work
            }
            if let breakMin = breakMinutes {
                settings.breakMinutes = breakMin
            }
        }
        
        // 更新 timerManager
        timerManager.updateDurations(
            workMinutes: getCurrentWorkMinutes(),
            breakMinutes: getCurrentBreakMinutes()
        )
    }
    
    private func calculateTodayStats() -> (completed: Int, total: Int, remaining: Double) {
        // 简单计算：根据时间范围估算
        let calendar = Calendar.current
        let now = Date()
        
        let startComponents = calendar.dateComponents([.hour, .minute], from: autoStartSettings.startTime)
        let endComponents = calendar.dateComponents([.hour, .minute], from: autoStartSettings.endTime)
        
        guard let startMinutes = startComponents.hour.map({ $0 * 60 + (startComponents.minute ?? 0) }),
              let endMinutes = endComponents.hour.map({ $0 * 60 + (endComponents.minute ?? 0) }) else {
            return (0, 0, 0)
        }
        
        let totalMinutes = endMinutes - startMinutes
        let modeSettings = focusModeSettings.getSettings(for: focusModeManager.currentFocusMode)
        let cycleMinutes = modeSettings.workMinutes + modeSettings.breakMinutes
        let totalCycles = totalMinutes / cycleMinutes
        
        // 这里简化处理，实际应该记录完成的周期数
        let completed = 3 // 临时值，后续可以添加持久化
        let remaining = Double(totalCycles - completed) * Double(cycleMinutes) / 60.0
        
        return (completed, totalCycles, max(0, remaining))
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
    
    private func translateModeName(_ name: String) -> String {
        let translations: [String: String] = [
            "Do Not Disturb": "勿扰模式",
            "Work": "工作",
            "Personal": "个人",
            "Sleep": "睡眠",
            "Gaming": "游戏",
            "Fitness": "健身",
            "Reading": "阅读",
            "Driving": "驾驶"
        ]
        return translations[name] ?? name
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
