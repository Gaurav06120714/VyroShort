//
//  MoveToApplications.swift
//  VyroShort
//
//  First-launch helper: offers to move the app into /Applications (the standard
//  macOS behaviour) and relaunches from there. Running from a stable location
//  keeps Screen Recording permission attached to the app across launches.
//

import AppKit

@MainActor
enum MoveToApplications {
    /// Returns `true` if a move + relaunch was started — the caller should stop
    /// launching because this instance is about to terminate.
    static func offerIfNeeded() -> Bool {
        let fm = FileManager.default
        let bundleURL = Bundle.main.bundleURL
        let path = bundleURL.path

        // Already in a system / user Applications folder → nothing to do.
        if path.hasPrefix("/Applications/") { return false }
        if let userApps = fm.urls(for: .applicationDirectory, in: .userDomainMask).first?.path,
           path.hasPrefix(userApps) { return false }

        // Don't nag while developing from Xcode's build products.
        if path.contains("/DerivedData/") || path.contains("/Build/Products/") { return false }

        let dest = URL(fileURLWithPath: "/Applications").appendingPathComponent(bundleURL.lastPathComponent)

        let alert = NSAlert()
        alert.messageText = "Move VyroShort to your Applications folder?"
        alert.informativeText = """
        VyroShort works best from the Applications folder. Moving it there also keeps \
        Screen Recording permission stable so you only have to grant it once.
        """
        alert.addButton(withTitle: "Move to Applications")
        alert.addButton(withTitle: "Not Now")
        NSApp.activate(ignoringOtherApps: true)
        guard alert.runModal() == .alertFirstButtonReturn else { return false }

        if !copy(from: bundleURL, to: dest, fm: fm) {
            let fail = NSAlert()
            fail.messageText = "Couldn't move VyroShort"
            fail.informativeText = "Please drag VyroShort into your Applications folder manually."
            fail.runModal()
            return false
        }

        // Clear the quarantine flag so the moved copy opens without extra warnings.
        _ = try? Process.run(URL(fileURLWithPath: "/usr/bin/xattr"),
                             arguments: ["-dr", "com.apple.quarantine", dest.path])
        relaunch(at: dest)
        return true
    }

    private static func copy(from: URL, to: URL, fm: FileManager) -> Bool {
        do {
            if fm.fileExists(atPath: to.path) { try fm.removeItem(at: to) }
            try fm.copyItem(at: from, to: to)
            return true
        } catch {
            // /Applications may need admin rights — fall back to a privileged copy.
            return privilegedCopy(from: from, to: to)
        }
    }

    private static func privilegedCopy(from: URL, to: URL) -> Bool {
        let source = from.path.replacingOccurrences(of: "'", with: "'\\''")
        let target = to.path.replacingOccurrences(of: "'", with: "'\\''")
        let shell = "rm -rf '\(target)' && cp -R '\(source)' '\(target)'"
        let script = "do shell script \"\(shell)\" with administrator privileges"
        var err: NSDictionary?
        NSAppleScript(source: script)?.executeAndReturnError(&err)
        return err == nil
    }

    private static func relaunch(at url: URL) {
        let config = NSWorkspace.OpenConfiguration()
        config.createsNewApplicationInstance = true
        NSWorkspace.shared.openApplication(at: url, configuration: config) { _, _ in
            DispatchQueue.main.async { NSApp.terminate(nil) }
        }
        // Safety net in case the open callback is delayed.
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { NSApp.terminate(nil) }
    }
}
