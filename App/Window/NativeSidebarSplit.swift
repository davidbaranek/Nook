// Licensed under GPL-3.0. See LICENSE.

import SwiftUI
import NookWeb

/// Let macOS own the docked sidebar's material, divider, resizing and collapse.
/// Keep the columns in SwiftUI so Nook's anchored overlays and environment propagate.
struct NativeSidebarSplit<Sidebar: View, Detail: View>: View {
    @EnvironmentObject private var browserManager: BrowserManager
    @Environment(BrowserWindowState.self) private var windowState
    @State private var preferredWidth: CGFloat?

    @ViewBuilder var sidebar: Sidebar
    @ViewBuilder var detail: Detail

    private var visibility: Binding<NavigationSplitViewVisibility> {
        Binding {
            windowState.isSidebarVisible ? .all : .detailOnly
        } set: { value in
            let visible = value != .detailOnly
            guard visible != windowState.isSidebarVisible else { return }
            // Use the same path as the menu/shortcut: saves state and handles sidebar PiP.
            browserManager.toggleSidebar(for: windowState)
        }
    }

    var body: some View {
        NavigationSplitView(columnVisibility: visibility) {
            sidebar
                .frame(minWidth: SidebarWidth.min)
                .ignoresSafeArea(.container, edges: .top)
                .navigationSplitViewColumnWidth(
                    min: SidebarWidth.min,
                    ideal: preferredWidth ?? windowState.savedSidebarWidth,
                    max: SidebarWidth.max
                )
                // Nook already exposes this action in its header and menu commands.
                .toolbar(removing: .sidebarToggle)
                .onGeometryChange(for: CGFloat.self) { proxy in
                    proxy.size.width
                } action: { width in
                    // Collapsing must not overwrite the width used by hover reveal/reopen.
                    guard windowState.isSidebarVisible,
                          width >= SidebarWidth.min,
                          width <= SidebarWidth.max,
                          abs(width - windowState.sidebarWidth) > 0.5 else { return }
                    windowState.sidebarWidth = width
                    windowState.savedSidebarWidth = width
                    windowState.sidebarContentWidth = max(width - 16, 0)
                }
        } detail: {
            detail
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea(.container, edges: .top)
        }
        .navigationSplitViewStyle(.balanced)
        .onAppear {
            // Keep the initial request stable: feeding measured content widths back into
            // the ideal column width can progressively shrink a system-inset sidebar.
            preferredWidth = windowState.savedSidebarWidth
        }
        .task(id: windowState.sidebarWidth) {
            // Avoid writing preferences and broadcasting manager changes on every drag event.
            do { try await Task.sleep(for: .milliseconds(250)) }
            catch { return }
            browserManager.updateSidebarWidth(windowState.sidebarWidth, for: windowState)
            browserManager.saveSidebarWidthToDefaults()
        }
    }
}
