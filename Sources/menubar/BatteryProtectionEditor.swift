import AppKit

extension AppDelegate {
    @MainActor @objc func editProtectionThreshold() {
        guard !protection.isSaving else { return }
        guard daemonRunning(), let current = protection.threshold else {
            showProtectionError()
            return
        }

        let alert = NSAlert()
        alert.messageText = L("低电量保护", "Low-Battery Protection")
        let instructions = L(
            "在「始终开启」模式下，使用电池时，电量达到或低于这个百分比就允许 Mac 休眠。请输入 1 到 100 的整数。",
            "In Always On mode, the Mac allows sleep on battery at or below this percentage. Enter a whole number from 1 to 100.")
        alert.informativeText = instructions
        alert.addButton(withTitle: L("保存", "Save"))
        alert.addButton(withTitle: L("取消", "Cancel")).keyEquivalent = "\u{1b}"
        let field = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
        field.stringValue = String(current)
        field.setAccessibilityLabel(L("电量百分比", "Battery percentage"))
        alert.accessoryView = field
        alert.window.initialFirstResponder = field
        NSApp.activate(ignoringOtherApps: true)

        while true {
            field.selectText(nil)
            guard alert.runModal() == .alertFirstButtonReturn else { return }
            let text = field.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
            guard text.utf8.allSatisfy({ (48...57).contains($0) }),
                  let value = UInt64(text), (1...100).contains(value) else {
                alert.informativeText = L("输入无效。请输入 1 到 100 之间的整数。", "Enter a whole number from 1 to 100.")
                continue
            }
            protection.setThreshold(value) { [weak self] confirmed in
                self?.refresh()
                if !confirmed { self?.showProtectionError() }
            }
            refresh()
            return
        }
    }

    private func showProtectionError() {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = L("未能确认低电量保护设置", "Could Not Confirm Low-Battery Setting")
        alert.informativeText = L(
            "请确认支持此设置的后台服务正在运行，再从菜单检查当前百分比并重试。",
            "Check that a background service supporting this setting is running, then check the percentage in the menu and try again.")
        alert.addButton(withTitle: L("好", "OK"))
        NSApp.activate(ignoringOtherApps: true)
        alert.runModal()
    }
}
