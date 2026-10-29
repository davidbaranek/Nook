// Licensed under GPL-3.0. See LICENSE.
// AppKit layout check; the window is never shown.
// Run from the repository root on macOS 26+:
// sed '/^import NookWeb$/d' App/Window/NativeSidebarSplitView.swift > /tmp/NookNativeSidebarSplitView.swift
// swiftc -parse-as-library Packages/NookWeb/Sources/NookWeb/SidebarWidth.swift /tmp/NookNativeSidebarSplitView.swift scripts/tests/NativeSidebarSplitCheck.swift -o /tmp/nook-native-sidebar-check && /tmp/nook-native-sidebar-check
// Only the package import is removed; this compiles the actual controller and width rules.

import AppKit
import SwiftUI

@main
struct NativeSidebarSplitCheck {
    @MainActor static func main() {
        guard #available(macOS 26.0, *) else {
            print("NativeSidebarSplitCheck requires macOS 26+")
            return
        }
        let app = NSApplication.shared
        app.setActivationPolicy(.prohibited)
        let controller = NativeSidebarSplitView<Text, Text>.Controller()
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 1200, height: 800), styleMask: [.titled, .resizable, .fullSizeContentView], backing: .buffered, defer: false)
        window.contentViewController = controller
        controller.sidebarHost.rootView = AnyView(Text("Tabs"))
        controller.contentHost.rootView = AnyView(Text("Page"))
        window.setContentSize(NSSize(width: 1200, height: 800))
        func settle() {
            window.contentView?.layoutSubtreeIfNeeded()
            RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.02))
        }
        func checkWidth(_ width: CGFloat, right: Bool, label: String) {
            controller.configure(width: width, visible: true, onRight: right, maximum: 840)
            settle()
            let actual = controller.sidebarHost.view.frame.width
            precondition(abs(actual - width) < 2, "\(label): expected \(width), got \(actual)")
            let sidebar = controller.splitViewItems.first { $0.behavior == .sidebar }!
            precondition(!sidebar.isCollapsed)
            precondition(controller.splitViewItems[right ? 1 : 0] === sidebar)
            let content = controller.splitViewItems.first { $0.behavior != .sidebar }!
            precondition(content.automaticallyAdjustsSafeAreaInsets)
            precondition(controller.contentHost.view.frame.minY == 0, "Toolbar must remain at the top edge")
            print("\(label): \(actual)")
        }
        checkWidth(260, right: false, label: "left tabs")
        checkWidth(840, right: false, label: "left library")
        checkWidth(420, right: false, label: "left history")
        checkWidth(260, right: false, label: "restore tabs")
        controller.configure(width: 260, visible: false, onRight: false, maximum: 500)
        settle()
        precondition(controller.splitViewItems[0].isCollapsed, "Sidebar must collapse")
        checkWidth(260, right: true, label: "right tabs")
        checkWidth(840, right: true, label: "right library")
        checkWidth(260, right: true, label: "right restore")
        window.setContentSize(NSSize(width: 600, height: 700))
        checkWidth(260, right: true, label: "narrow window")
        var reportedWidth: CGFloat = 0
        controller.onResize = { reportedWidth = $0 }
        controller.splitView.setPosition(280, ofDividerAt: 0)
        settle()
        precondition(abs(reportedWidth - 320) < 2, "Native and accessibility resize must update Nook state")
        precondition(abs(controller.sidebarHost.view.frame.width - reportedWidth) < 2)
        print("native resize callback:", reportedWidth)
        print("NativeSidebarSplitCheck passed")
    }
}
