//
//  BreakWindowController.swift
//  StretchCat
//
//  全屏休息提醒窗口控制器
//

import SwiftUI
import AppKit

class BreakWindowController {
    private var window: NSWindow?
    
    func show(timerManager: TimerManager) {
        let contentView = BreakReminderView(timerManager: timerManager) { [weak self] in
            // 跳过休息
            timerManager.skipBreak()
            self?.hide()
        }
        
        let hostingController = NSHostingController(rootView: contentView)
        
        window = NSWindow(contentViewController: hostingController)
        window?.styleMask = [.borderless, .fullSizeContentView]
        window?.level = .screenSaver
        window?.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window?.isOpaque = false
        window?.backgroundColor = .clear
        
        if let screen = NSScreen.main {
            window?.setFrame(screen.frame, display: true)
        }
        
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func hide() {
        window?.close()
        window = nil
    }
}
