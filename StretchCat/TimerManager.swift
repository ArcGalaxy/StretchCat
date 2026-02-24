//
//  TimerManager.swift
//  StretchCat
//
//  定时器管理器
//

import Foundation
import Combine

enum TimerState {
    case idle
    case working
    case breaking
    case paused
}

class TimerManager: ObservableObject {
    @Published var state: TimerState = .idle
    @Published var remainingSeconds: Int = 0
    @Published var totalSeconds: Int = 0
    
    private var timer: Timer?
    private var workDuration: Int
    private var breakDuration: Int
    private var wasRunningBeforeLock: Bool = false
    
    var onBreakTimeStart: (() -> Void)?
    
    init(workMinutes: Int = 30, breakMinutes: Int = 2) {
        self.workDuration = workMinutes * 60
        self.breakDuration = breakMinutes * 60
        self.remainingSeconds = workDuration
        self.totalSeconds = workDuration
        
        setupScreenLockObservers()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func setupScreenLockObservers() {
        // 监听屏幕锁定
        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(screenDidLock),
            name: NSNotification.Name("com.apple.screenIsLocked"),
            object: nil
        )
        
        // 监听屏幕解锁
        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(screenDidUnlock),
            name: NSNotification.Name("com.apple.screenIsUnlocked"),
            object: nil
        )
    }
    
    @objc private func screenDidLock() {
        print("🔒 屏幕已锁定")
        // 如果正在运行，暂停计时
        if state == .working || state == .breaking {
            wasRunningBeforeLock = true
            pause()
            print("⏸️ 计时已暂停（锁屏）")
        } else {
            wasRunningBeforeLock = false
        }
    }
    
    @objc private func screenDidUnlock() {
        print("🔓 屏幕已解锁")
        // 如果锁屏前正在运行，恢复计时
        if wasRunningBeforeLock {
            start()
            wasRunningBeforeLock = false
            print("▶️ 计时已恢复（解锁）")
        }
    }
    
    func updateDurations(workMinutes: Int, breakMinutes: Int) {
        self.workDuration = workMinutes * 60
        self.breakDuration = breakMinutes * 60
        if state == .idle {
            self.remainingSeconds = workDuration
            self.totalSeconds = workDuration
        }
    }
    
    func start() {
        guard state == .idle || state == .paused else { return }
        
        if state == .idle {
            state = .working
            remainingSeconds = workDuration
            totalSeconds = workDuration
        } else {
            state = .working
        }
        
        startTimer()
    }
    
    func pause() {
        timer?.invalidate()
        timer = nil
        state = .paused
    }
    
    func reset() {
        timer?.invalidate()
        timer = nil
        state = .idle
        remainingSeconds = workDuration
        totalSeconds = workDuration
    }
    
    func startBreak() {
        state = .breaking
        remainingSeconds = breakDuration
        totalSeconds = breakDuration
        startTimer()
        onBreakTimeStart?()
    }
    
    func skipBreak() {
        timer?.invalidate()
        timer = nil
        // 跳过休息后，立即开始下一个工作周期
        state = .working
        remainingSeconds = workDuration
        totalSeconds = workDuration
        startTimer()
        print("⏭️ 跳过休息，开始新的工作周期")
    }
    
    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }
    
    private func tick() {
        remainingSeconds -= 1
        
        if remainingSeconds <= 0 {
            timer?.invalidate()
            timer = nil
            
            if state == .working {
                startBreak()
            } else if state == .breaking {
                // 休息结束后，自动开始下一个工作周期
                state = .working
                remainingSeconds = workDuration
                totalSeconds = workDuration
                startTimer()
            }
        }
    }
    
    var progress: Double {
        guard totalSeconds > 0 else { return 0 }
        return Double(totalSeconds - remainingSeconds) / Double(totalSeconds)
    }
    
    var timeString: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
