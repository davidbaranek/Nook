// Licensed under GPL-3.0. See LICENSE.
import AppKit
import SwiftUI
import WebKit
import NookDesign
import NookWeb
import NookUI

struct TopBarView: View {
    @EnvironmentObject var browserManager: BrowserManager
    @Environment(BrowserWindowState.self) private var windowState
    @Environment(CommandPalette.self) private var commandPalette
    @Environment(\.nookSettings) private var nookSettings
    @State private var isHovering = false

    var body: some View {
        GeometryReader { geometry in
            if #available(macOS 26.0, *) {
                GlassEffectContainer(spacing: 0) {
                    controls(width: geometry.size.width)
                }
            } else {
                controls(width: geometry.size.width)
            }
        }
        .frame(height: NookDesign.Toolbar.height)
        .background(.bar)
        .overlay(alignment: .bottom) {
            Rectangle().fill(.separator)
                .frame(height: NookDesign.Size.hairlineWidth)
                .allowsHitTesting(false)
        }
        .background {
            GeometryReader { geometry in
                Color.clear.preference(key: URLBarFramePreferenceKey.self,
                    value: geometry.frame(in: .named("WindowSpace")))
            }
        }
    }

    private func controls(width: CGFloat) -> some View {
        let compact = width < NookDesign.Toolbar.compactBelow
        return HStack(spacing: NookDesign.Spacing.md) {
            if !windowState.isSidebarVisible {
                Button("Toggle Sidebar", systemImage: "sidebar.left") {
                    browserManager.toggleSidebar(for: windowState)
                }
                .help("Toggle Sidebar")
            }
            if !compact { navigationControls }
            Spacer(minLength: 0)
            addressBar
                .buttonBorderShape(.automatic)
                .controlSize(.regular)
                .frame(maxWidth: NookDesign.Toolbar.addressMaxWidth)
                .layoutPriority(1)
            Spacer(minLength: 0)
            trailingControls(compact: compact)
        }
        .padding(.horizontal, NookDesign.Spacing.lg)
        .frame(width: width, height: NookDesign.Toolbar.height)
        .buttonStyle(NookToolbarIconButtonStyle())
        .labelStyle(.iconOnly)
    }

    @ViewBuilder
    private var navigationControls: some View {
        if #available(macOS 26.0, *) {
            navigationGroup.glassEffect(.regular, in: .capsule)
        } else {
            navigationGroup.background(.bar, in: Capsule())
        }
    }

    private var navigationGroup: some View {
        HStack(spacing: NookDesign.Spacing.sm) {
            Button(action: goBack) {
                Label("Go Back", systemImage: "chevron.backward")
                    .frame(width: NookDesign.Toolbar.icon, height: NookDesign.Toolbar.icon)
                    .padding(NookDesign.Toolbar.buttonPadding)
            }
                .disabled(!(session?.canGoBackOrReturn ?? false))
                .help("Go Back")
                .contextMenu {
                    NavigationHistoryContextMenu(historyType: .back, windowState: windowState)
                }
            Divider().frame(height: NookDesign.Toolbar.icon)
            Button(action: goForward) {
                Label("Go Forward", systemImage: "chevron.forward")
                    .frame(width: NookDesign.Toolbar.icon, height: NookDesign.Toolbar.icon)
                    .padding(NookDesign.Toolbar.buttonPadding)
            }
                .disabled(!(session?.canGoForward ?? false))
                .help("Go Forward")
                .contextMenu {
                    NavigationHistoryContextMenu(historyType: .forward, windowState: windowState)
                }
        }
        .buttonStyle(.borderless)
        .labelStyle(.iconOnly)
        .font(.system(size: NookDesign.Toolbar.icon))
        .padding(NookDesign.Spacing.sm)
    }

    private var addressBar: some View {
        HStack(spacing: NookDesign.Spacing.sm) {
            Button {
                if let current = browserManager.tabs.selectedSession(in: windowState) {
                    commandPalette.openWithCurrentURL(current.url)
                } else {
                    commandPalette.open()
                }
            } label: {
                HStack(spacing: 0) {
                    Text(displayAddress.host)
                        .truncationMode(.head)
                        .layoutPriority(1)
                    if !displayAddress.rest.isEmpty {
                        Text(displayAddress.rest)
                            .foregroundStyle(.secondary)
                            .truncationMode(.tail)
                    }
                }
                .font(NookDesign.Font.bodyRegular)
                .foregroundStyle(.primary)
                .lineLimit(1)
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help("Search or Enter URL…")

            if session != nil {
                Button {
                    if session?.isLoading == true { session?.stop() }
                    else { refreshCurrentTab() }
                } label: {
                    Image(systemName: session?.isLoading == true ? "xmark" : "arrow.clockwise")
                        .contentTransition(.symbolEffect(.replace))
                }
                .nookIconButtons()
                .accessibilityLabel(session?.isLoading == true ? "Stop Loading" : "Reload")
            }
        }
        .padding(.leading, NookDesign.Spacing.lg)
        .padding(.trailing, NookDesign.Spacing.xs)
        .frame(height: NookDesign.Toolbar.addressHeight)
        .background(Color(nsColor: .controlBackgroundColor), in: Capsule())
        .overlay(Capsule().strokeBorder(.separator, lineWidth: NookDesign.Size.hairlineWidth)
            .allowsHitTesting(false))
        .onHoverTracking { isHovering = $0 }
    }

    @ViewBuilder
    private func trailingControls(compact: Bool) -> some View {
        HStack(spacing: NookDesign.Spacing.md) {
            if let manager = browserManager.extensionManager {
                if !compact {
                    let pinned = browserManager.nookSettings?.pinnedExtensionIDs ?? []
                    ExtensionActionView(extensions: manager.installedExtensions.filter { pinned.contains($0.id) }, usesToolbarStyle: true)
                        .environmentObject(browserManager)
                }
                ExtensionLibraryButton(usesToolbarStyle: true)
                    .help("Site Controls")
                    .onAppear {
                        browserManager.nookSettings?.migrateExtensionPinStateIfNeeded(
                            installedExtensionIDs: manager.installedExtensions.filter(\.isEnabled).map(\.id))
                    }
            }
            if !compact, nookSettings.showAIAssistant, !windowState.isSidebarAIChatVisible {
                Button("Chat", systemImage: "bubble.left") {
                    browserManager.toggleAISidebar(for: windowState)
                }
                .help("Chat")
            }
        }
    }

    private var displayAddress: (host: String, rest: String) {
        guard let current = browserManager.tabs.selectedSession(in: windowState) else {
            return ("Search or Enter URL…", "")
        }
        guard let host = current.url.host else { return (current.url.absoluteString, "") }
        if isHovering {
            let scheme = current.url.scheme.map { $0 + "://" } ?? ""
            let port = current.url.port.map { ":\($0)" } ?? ""
            let query = current.url.query.map { "?" + $0 } ?? ""
            return (scheme + host + port, current.url.path + query)
        }
        return (host.hasPrefix("www.") ? String(host.dropFirst(4)) : host, "")
    }

    /// Nil while another window holds the page: its controls stay inert until Move Here.
    private var session: PageSession? {
        browserManager.tabs.controllableSession(in: windowState)
    }

    /// This window's own view of the page, so a clone navigates in its window.
    private var windowWebView: WKWebView? {
        session.flatMap { browserManager.webViewCoordinator?.getWebView(for: $0.itemID, in: windowState.id) }
    }

    private func goBack() {
        session?.goBack(in: windowWebView)
    }

    private func goForward() {
        if let webView = windowWebView { webView.goForward() } else { session?.goForward() }
    }

    private func refreshCurrentTab() {
        session?.refresh()
    }

}
