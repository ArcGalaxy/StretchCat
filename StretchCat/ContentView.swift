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
    @State private var showingSettings = false
    private let breakWindowController = BreakWindowController()
    
    init() {
        let settings = SettingsManager()
        _timerManager = StateObject(wrappedValue: TimerManager(workMinutes: settings.workMinutes, breakMinutes: settings.breakMinutes))
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
        .frame(minWidth: 400, minHeight: 450)
        .sheet(isPresented: $showingSettings) {
            SettingsView(
                settings: settings,
                timerManager: timerManager,
                focusModeManager: focusModeManager,
                autoStartSettings: autoStartSettings
            )
        }
        .onAppear {
            timerManager.onBreakTimeStart = {
                breakWindowController.show(timerManager: timerManager)
            }
            checkAutoStart()
        }
        .onChange(of: timerManager.state) { newState in
            if newState == .idle {
                breakWindowController.hide()
            }
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
}

#Preview {
    ContentView()
}
