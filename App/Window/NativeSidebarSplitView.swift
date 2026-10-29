// Licensed under GPL-3.0. See LICENSE.

import AppKit
import SwiftUI
import NookWeb

/// AppKit owns the sidebar material and divider; the existing Nook views own its content.
@available(macOS 26.0, *)
struct NativeSidebarSplitView<Sidebar: View, Content: View>: NSViewControllerRepresentable, Animatable {
    @Environment(\.self) private var environment
    var width: CGFloat
    let isVisible: Bool
    let onRight: Bool
    let maximumWidth: CGFloat
    let onResize: (CGFloat) -> Void
    let onCollapse: () -> Void
    @ViewBuilder let sidebar: Sidebar
    @ViewBuilder let content: Content

    var animatableData: CGFloat {
        get { width }
        set { width = newValue }
    }

    func makeNSViewController(context: Context) -> Controller {
        Controller()
    }

    func updateNSViewController(_ controller: Controller, context: Context) {
        controller.sidebarHost.rootView = AnyView(sidebar.environment(\.self, environment))
        controller.contentHost.rootView = AnyView(content.environment(\.self, environment))
        controller.onResize = onResize
        controller.onCollapse = onCollapse
        controller.configure(width: width, visible: isVisible, onRight: onRight, maximum: maximumWidth)
    }

    final class Controller: NSSplitViewController {
        let sidebarHost = NSHostingController(rootView: AnyView(EmptyView()))
        let contentHost = NSHostingController(rootView: AnyView(EmptyView()))
        private var sidebarItem: NSSplitViewItem!
        private var contentItem: NSSplitViewItem!
        private var collapseObservation: NSKeyValueObservation?
        private var applying = false
        private var onRight = false
        private var requestedWidth: CGFloat = SidebarWidth.standard
        var onResize: (CGFloat) -> Void = { _ in }
        var onCollapse: () -> Void = {}

        override func viewDidLoad() {
            super.viewDidLoad()
            splitView.isVertical = true
            sidebarHost.sizingOptions = []
            sidebarHost.safeAreaRegions = []
            contentHost.sizingOptions = []
            contentHost.safeAreaRegions = []

            sidebarItem = NSSplitViewItem(sidebarWithViewController: sidebarHost)
            sidebarItem.collapseBehavior = .preferResizingSiblingsWithFixedSplitView
            sidebarItem.canCollapseFromWindowResize = false
            sidebarItem.holdingPriority = NSLayoutConstraint.Priority(260)

            // Extend the page's appearance under the system sidebar without obscuring the page.
            let extendedContent = NSViewController()
            extendedContent.addChild(contentHost)
            let background = NSBackgroundExtensionView()
            background.automaticallyPlacesContentView = false
            background.contentView = contentHost.view
            contentHost.view.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                contentHost.view.leadingAnchor.constraint(equalTo: background.safeAreaLayoutGuide.leadingAnchor),
                contentHost.view.trailingAnchor.constraint(equalTo: background.safeAreaLayoutGuide.trailingAnchor),
                contentHost.view.topAnchor.constraint(equalTo: background.topAnchor),
                contentHost.view.bottomAnchor.constraint(equalTo: background.bottomAnchor),
            ])
            extendedContent.view = background
            contentItem = NSSplitViewItem(viewController: extendedContent)
            contentItem.automaticallyAdjustsSafeAreaInsets = true
            addSplitViewItem(sidebarItem)
            addSplitViewItem(contentItem)

            collapseObservation = sidebarItem.observe(\.isCollapsed, options: [.new]) { [weak self] item, _ in
                guard let self, !self.applying, item.isCollapsed else { return }
                DispatchQueue.main.async { self.onCollapse() }
            }
        }

        func configure(width: CGFloat, visible: Bool, onRight: Bool, maximum: CGFloat) {
            applying = true
            defer { applying = false }
            loadViewIfNeeded()
            if self.onRight != onRight {
                self.onRight = onRight
                splitViewItems = onRight ? [contentItem, sidebarItem] : [sidebarItem, contentItem]
            }
            requestedWidth = width
            sidebarItem.minimumThickness = min(SidebarWidth.min, max(1, width))
            sidebarItem.maximumThickness = maximum
            sidebarItem.isCollapsed = !visible
            view.layoutSubtreeIfNeeded()
            applyWidth()
        }

        override func viewDidLayout() {
            super.viewDidLayout()
            // The first update can precede attachment to a window.
            if !view.inLiveResize, NSApp.currentEvent?.type != .leftMouseDragged {
                applyWidth()
            }
        }

        private func applyWidth() {
            guard sidebarItem != nil, !sidebarItem.isCollapsed, splitView.bounds.width > 0,
                  abs(sidebarHost.view.frame.width - requestedWidth) > 1 else { return }
            let position = onRight
                ? splitView.bounds.width - requestedWidth - splitView.dividerThickness
                : requestedWidth
            let wasApplying = applying
            applying = true
            defer { applying = wasApplying }
            splitView.setPosition(position, ofDividerAt: 0)
        }

        override func splitViewDidResizeSubviews(_ notification: Notification) {
            super.splitViewDidResizeSubviews(notification)
            guard !applying, sidebarItem != nil, !sidebarItem.isCollapsed else { return }
            let width = sidebarHost.view.frame.width
            requestedWidth = width
            DispatchQueue.main.async { self.onResize(width) }
        }
    }
}
