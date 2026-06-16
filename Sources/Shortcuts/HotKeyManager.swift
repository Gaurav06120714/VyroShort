//
//  HotKeyManager.swift
//  VyroShort
//
//  Global keyboard shortcuts via Carbon RegisterEventHotKey
//  (works without extra entitlements). Defaults:
//    ⌘⇧Q Region · ⌘⇧2 Window · ⌘⇧1 Full Screen
//    (⌘⇧3/4/5 are reserved by macOS for its own screenshots, so we avoid them.)
//

import AppKit
import Carbon.HIToolbox

@MainActor
final class HotKeyManager {
    enum Action: UInt32 { case region = 1, window = 2, fullScreen = 3 }

    private var handlers: [Action: () -> Void] = [:]
    private var hotKeyRefs: [EventHotKeyRef?] = []
    private var eventHandler: EventHandlerRef?

    static let shared = HotKeyManager()
    private init() {}

    func register(region: @escaping () -> Void,
                  window: @escaping () -> Void,
                  fullScreen: @escaping () -> Void) {
        handlers[.region] = region
        handlers[.window] = window
        handlers[.fullScreen] = fullScreen

        installEventHandler()
        let mods = UInt32(cmdKey | shiftKey)
        register(action: .region, keyCode: UInt32(kVK_ANSI_Q), modifiers: mods)
        register(action: .window, keyCode: UInt32(kVK_ANSI_2), modifiers: mods)
        register(action: .fullScreen, keyCode: UInt32(kVK_ANSI_1), modifiers: mods)
    }

    func unregisterAll() {
        hotKeyRefs.forEach { if let ref = $0 { UnregisterEventHotKey(ref) } }
        hotKeyRefs.removeAll()
        if let eventHandler { RemoveEventHandler(eventHandler) }
        eventHandler = nil
    }

    fileprivate func fire(_ action: Action) {
        handlers[action]?()
    }

    // MARK: - Private

    private func installEventHandler() {
        guard eventHandler == nil else { return }
        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard),
                                 eventKind: UInt32(kEventHotKeyPressed))
        let selfPtr = Unmanaged.passUnretained(self).toOpaque()
        InstallEventHandler(GetApplicationEventTarget(), { _, event, userData in
            guard let event, let userData else { return noErr }
            var hotKeyID = EventHotKeyID()
            GetEventParameter(event, EventParamName(kEventParamDirectObject),
                              EventParamType(typeEventHotKeyID), nil,
                              MemoryLayout<EventHotKeyID>.size, nil, &hotKeyID)
            let manager = Unmanaged<HotKeyManager>.fromOpaque(userData).takeUnretainedValue()
            if let action = Action(rawValue: hotKeyID.id) {
                DispatchQueue.main.async { MainActor.assumeIsolated { manager.fire(action) } }
            }
            return noErr
        }, 1, &spec, selfPtr, &eventHandler)
    }

    private func register(action: Action, keyCode: UInt32, modifiers: UInt32) {
        let signature = OSType(0x56535254) // 'VSRT'
        var ref: EventHotKeyRef?
        let id = EventHotKeyID(signature: signature, id: action.rawValue)
        RegisterEventHotKey(keyCode, modifiers, id, GetApplicationEventTarget(), 0, &ref)
        hotKeyRefs.append(ref)
    }
}
