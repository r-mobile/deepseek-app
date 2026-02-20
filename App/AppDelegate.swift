//
//  AppDelegate.swift
//  AIChat Desktop
//

import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        NotificationCenter.default.post(name: Notification.Name("openMainWindow"), object: nil)
        return true
    }
}
