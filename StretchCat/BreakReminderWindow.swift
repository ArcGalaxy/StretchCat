//
//  BreakReminderWindow.swift
//  StretchCat
//
//  全屏休息提醒窗口
//

import SwiftUI

struct BreakReminderView: View {
    @ObservedObject var timerManager: TimerManager
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.95)
                .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Image(systemName: "figure.walk")
                    .font(.system(size: 120))
                    .foregroundColor(.white)
                
                Text("休息时间到了！")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.white)
                
                Text("站起来活动一下吧 🐱")
                    .font(.system(size: 28))
                    .foregroundColor(.white.opacity(0.8))
                
                Text(timerManager.timeString)
                    .font(.system(size: 80, weight: .bold, design: .monospaced))
                    .foregroundColor(.green)
                    .padding(.top, 20)
                
                VStack(spacing: 20) {
                    Text("建议活动：")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.white)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "arrow.up.and.down")
                            Text("站起来伸展身体")
                        }
                        HStack {
                            Image(systemName: "eye")
                            Text("眺望远处放松眼睛")
                        }
                        HStack {
                            Image(systemName: "drop")
                            Text("喝一口水")
                        }
                    }
                    .font(.system(size: 20))
                    .foregroundColor(.white.opacity(0.9))
                }
                .padding(.top, 30)
            }
        }
    }
}
