// Licensed under GPL-3.0. See LICENSE.
//
//  ExtensionLibraryButton.swift
//  Nook
//

import SwiftUI
import NookDesign
import NookWeb
import NookUI

struct ExtensionLibraryButton: View {
    @EnvironmentObject var browserManager: BrowserManager
    @Environment(BrowserWindowState.self) private var windowState

    var usesToolbarStyle = false
    @State private var showsMore = false

    private var presented: Binding<Bool> {
        Binding {
            windowState.isExtensionLibraryVisible
        } set: { visible in
            windowState.isExtensionLibraryVisible = visible
            if !visible { showsMore = false }
        }
    }

    @ViewBuilder
    private var control: some View {
        if usesToolbarStyle {
            Button("Site Controls", systemImage: "slider.horizontal.3") { presented.wrappedValue.toggle() }
                .buttonStyle(NookToolbarIconButtonStyle())
        } else {
            Button("Site Controls", systemImage: "slider.horizontal.3") { presented.wrappedValue.toggle() }
                .buttonStyle(NookIconButtonStyle())
        }
    }

    var body: some View {
        control
        .labelStyle(.iconOnly)
        .popover(isPresented: presented, attachmentAnchor: .rect(.bounds), arrowEdge: .bottom) {
            if let settings = browserManager.nookSettings {
                Group {
                    if showsMore {
                        VStack(alignment: .leading, spacing: NookDesign.Spacing.md) {
                            Button("Back", systemImage: "chevron.backward") { showsMore = false }
                                .buttonStyle(.borderless)
                                .padding(.horizontal, NookDesign.Spacing.lg)
                            MoreMenuView(browserManager: browserManager, windowState: windowState,
                                         onDismiss: { showsMore = false })
                        }
                        .padding(.vertical, NookDesign.Spacing.lg)
                        .frame(width: 300)
                    } else {
                        ExtensionLibraryView(browserManager: browserManager, windowState: windowState,
                            settings: settings,
                            onDismiss: { presented.wrappedValue = false },
                            onShowMoreMenu: { showsMore = true })
                    }
                }
                // As with the theme picker, macOS supplies the entire presentation:
                // background, arrow, rim, shadow, placement and transient dismissal.
                .environment(\.nookHasGlassSurface, true)
                .buttonBorderShape(.automatic)
                .controlSize(.regular)
                .onExitCommand { presented.wrappedValue = false }
            }
        }
        .onChange(of: windowState.selectedItemID) { _, _ in presented.wrappedValue = false }
        .onChange(of: windowState.commandPalette?.isVisible) { _, visible in
            if visible == true { presented.wrappedValue = false }
        }
        .onChange(of: windowState.isExtensionLibraryVisible) { _, visible in
            if !visible { showsMore = false }
        }
        .onDisappear { presented.wrappedValue = false }
    }
}
