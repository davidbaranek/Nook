// Licensed under GPL-3.0. See LICENSE.
//
//  SidebarMenu.swift
//  Nook
//
//  Created by Maciek Bagiński on 23/09/2025.
//

import AppKit
import SwiftUI
import NookDesign
import NookTabsCore
import NookWeb
import NookUI

struct SidebarMenu: View {
    @Environment(BrowserWindowState.self) private var windowState
    @EnvironmentObject var browserManager: BrowserManager
    @Environment(\.nookSettings) var nookSettings

    private let tabColumnWidth: CGFloat = NookWeb.SidebarWidth.min

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            if nookSettings.sidebarPosition == .left{
                tabs
            }
            VStack {
                switch windowState.sidebarMenuSelectedTab {
                case .history:
                    SidebarMenuHistoryTab()
                case .downloads:
                    SidebarMenuDownloadsTab()
                case .spaces:
                    SidebarMenuSpacesTab(onOpenSpace: openSpace, onNewSpace: newSpace)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            if nookSettings.sidebarPosition == .right{
                tabs
            }
        }
        .frame(maxWidth: .infinity)
        .ignoresSafeArea()
    }

    private func close() {
        LibraryMotion.close(windowState)
    }

    private func openSpace(_ id: UUID) {
        close()
        withAnimation(NookDesign.Motion.standard) {
            browserManager.tabs.setSpace(id, in: windowState)
        }
    }

    private func newSpace() {
        close()
        withAnimation(NookDesign.Motion.standard) {
            windowState.spaceDraftTheme = .randomPreset()
        }
    }

    private var selection: Binding<NookWeb.SidebarMenuTab?> {
        Binding {
            windowState.sidebarMenuSelectedTab
        } set: { tab in
            if let tab { windowState.sidebarMenuSelectedTab = tab }
        }
    }

    private var tabs: some View {
        VStack(alignment: .leading, spacing: NookDesign.Spacing.md) {
            HStack {
                Text("Library")
                    .font(.headline)
                Spacer()
                Button("Back", systemImage: "arrow.backward", action: close)
                    .labelStyle(.iconOnly)
                    .buttonStyle(.plain)
                    .help("Back to Browser")
            }
            .padding(.horizontal, NookDesign.Spacing.lg)
            .padding(.top, NookDesign.Spacing.lg)

            List(selection: selection) {
                Label("History", systemImage: "clock")
                    .tag(NookWeb.SidebarMenuTab.history)
                Label("Spaces", systemImage: "square.on.square")
                    .tag(NookWeb.SidebarMenuTab.spaces)
                Label("Downloads", systemImage: "arrow.down.circle")
                    .tag(NookWeb.SidebarMenuTab.downloads)
            }
            .listStyle(.sidebar)
            .scrollContentBackground(.hidden)
        }
        .frame(width: tabColumnWidth)
        .frame(maxHeight: .infinity)
        .background(NookDesign.Surface.fill)
    }
}
