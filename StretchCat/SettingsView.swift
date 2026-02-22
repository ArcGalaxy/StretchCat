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
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 30) {
            Text("设置")
                .font(.system(size: 28, weight: .bold))
            
            VStack(alignment: .leading, spacing: 20) {
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
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
            
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
        .padding(40)
        .frame(width: 450, height: 350)
    }
}
