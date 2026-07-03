//
//  LaunchAtLogin.swift
//  VyroShort
//
//  Registers VyroShort as a macOS login item via ServiceManagement.
//

import ServiceManagement

@MainActor
enum LaunchAtLogin {
    static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    static func set(_ enabled: Bool) {
        do {
            if enabled {
                if SMAppService.mainApp.status != .enabled {
                    try SMAppService.mainApp.register()
                }
            } else {
                if SMAppService.mainApp.status == .enabled {
                    try SMAppService.mainApp.unregister()
                }
            }
        } catch {
            NSLog("VyroShort LaunchAtLogin error: \(error.localizedDescription)")
        }
    }
}
