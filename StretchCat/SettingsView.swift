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
    
    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                Text("⚙️ 设置")
                    .font(.system(size: 20, weight: .semibold))
                
                Spacer()
                
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(Color(nsColor: .controlBackgroundColor))
            
            Divider()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // 计时器模式
                    VStack(alignment: .leading, spacing: 12) {
                        Text("📋 计时器模式")
                            .font(.system(size: 14, weight: .semibold))
                        
                        Toggle("为每个专注模式单独设置时间", isOn: $focusModeSettings.usePerModeSettings)
                            .toggleStyle(.switch)
                        
                        Text(focusModeSettings.usePerModeSettings ? "切换专注模式时，自动使用对应的时间设置" : "所有模式使用统一的时间设置")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(16)
                    .background(Color(nsColor: .controlBackgroundColor))
                    .cornerRadius(8)
                    
                    Divider()
                    
                    // 自动运行
                    VStack(alignment: .leading, spacing: 12) {
                        Text("🤖 自动运行")
                            .font(.system(size: 14, weight: .semibold))
                        
                        Picker("", selection: $autoStartSettings.autoStartMode) {
                            Text("手动").tag(AutoStartMode.manual)
                            Text("时间").tag(AutoStartMode.timeOnly)
                            Text("专注").tag(AutoStartMode.focusMode)
                            Text("时间+专注").tag(AutoStartMode.both)
                        }
                        .pickerStyle(.segmented)
                        
                        if autoStartSettings.autoStartMode == .timeOnly || autoStartSettings.autoStartMode == .both {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("时间范围")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                HStack {
                                    DatePicker("", selection: $autoStartSettings.startTime, displayedComponents: .hourAndMinute)
                                        .labelsHidden()
                                    
                                    Text("-")
                                        .foregroundColor(.secondary)
                                    
                                    DatePicker("", selection: $autoStartSettings.endTime, displayedComponents: .hourAndMinute)
                                        .labelsHidden()
                                }
                            }
                        }
                        
                        if autoStartSettings.autoStartMode == .focusMode || autoStartSettings.autoStartMode == .both {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("专注模式")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                FlowLayout(spacing: 8) {
                                    ForEach(focusModeManager.availableFocusModes, id: \.self) { mode in
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
                                        .controlSize(.small)
                                    }
                                }
                            }
                        }
                    }
                    .padding(16)
                    .background(Color(nsColor: .controlBackgroundColor))
                    .cornerRadius(8)
                    
                    Divider()
                    
                    // 通知
                    VStack(alignment: .leading, spacing: 12) {
                        Text("🔔 通知")
                            .font(.system(size: 14, weight: .semibold))
                        
                        Toggle("工作开始时通知", isOn: .constant(true))
                            .toggleStyle(.switch)
                            .disabled(true)
                        
                        Toggle("休息开始时通知", isOn: .constant(true))
                            .toggleStyle(.switch)
                            .disabled(true)
                        
                        Toggle("休息结束前 10 秒提醒", isOn: .constant(true))
                            .toggleStyle(.switch)
                            .disabled(true)
                        
                        Text("通知功能即将推出")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(16)
                    .background(Color(nsColor: .controlBackgroundColor))
                    .cornerRadius(8)
                    
                    Divider()
                    
                    // 启动
                    VStack(alignment: .leading, spacing: 12) {
                        Text("🚀 启动")
                            .font(.system(size: 14, weight: .semibold))
                        
                        Toggle("登录时自动启动", isOn: .constant(false))
                            .toggleStyle(.switch)
                            .disabled(true)
                        
                        Toggle("启动时最小化到菜单栏", isOn: .constant(false))
                            .toggleStyle(.switch)
                            .disabled(true)
                        
                        Text("启动选项即将推出")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(16)
                    .background(Color(nsColor: .controlBackgroundColor))
                    .cornerRadius(8)
                    
                    Divider()
                    
                    // 关于
                    VStack(alignment: .leading, spacing: 12) {
                        Text("ℹ️ 关于")
                            .font(.system(size: 14, weight: .semibold))
                        
                        HStack {
                            Text("伸展猫")
                                .font(.body)
                            Spacer()
                            Text("v1.0.0")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack(spacing: 12) {
                            Button("检查更新") {
                                // TODO: 检查更新
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            
                            Button("反馈问题") {
                                // TODO: 打开反馈页面
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                    }
                    .padding(16)
                    .background(Color(nsColor: .controlBackgroundColor))
                    .cornerRadius(8)
                }
                .padding(24)
            }
        }
        .frame(width: 500, height: 600)
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
}

// 流式布局（用于专注模式按钮）
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.frames[index].minX, y: bounds.minY + result.frames[index].minY), proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var frames: [CGRect] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if currentX + size.width > maxWidth && currentX > 0 {
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }
                
                frames.append(CGRect(x: currentX, y: currentY, width: size.width, height: size.height))
                lineHeight = max(lineHeight, size.height)
                currentX += size.width + spacing
            }
            
            self.size = CGSize(width: maxWidth, height: currentY + lineHeight)
        }
    }
}
