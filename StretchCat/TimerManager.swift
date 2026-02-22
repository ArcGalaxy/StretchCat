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
    
    var onBreakTimeStart: (() -> Void)?
    
    init(workMinutes: Int = 30, breakMinutes: Int = 2) {
        self.workDuration = workMinutes * 60
        self.breakDuration = breakMinutes * 60
        self.remainingSeconds = workDuration
        self.totalSeconds = workDuration
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
        state = .idle
        remainingSeconds = workDuration
        totalSeconds = workDuration
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
                state = .idle
                remainingSeconds = workDuration
                totalSeconds = workDuration
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
