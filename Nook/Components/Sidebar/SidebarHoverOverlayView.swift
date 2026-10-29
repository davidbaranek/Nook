// Licensed under GPL-3.0. See LICENSE.
//
//  SidebarHoverOverlayView.swift
//  Nook
//
//  Created by Jonathan Caudill on 2025-09-13.
//

import SwiftUI
import AppKit
import NookDesign
import NookTabsCore
import NookWeb
import NookUI

struct SidebarHoverOverlayView: View {
    @EnvironmentObject var browserManager: BrowserManager
    @EnvironmentObject var hoverManager: HoverSidebarManager
    @Environment(BrowserWindowState.self) private var windowState
    @Environment(CommandPalette.self) private var commandPalette
    @Environment(\.nookSettings) var nookSettings
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        // Only render overlay plumbing when the real sidebar is collapsed
        if !windowState.isSidebarVisible {
            ZStack(alignment: nookSettings.sidebarPosition == .left ? .leading : .trailing) {
                // Edge hover hotspot
                Color.clear
                    .frame(width: hoverManager.triggerWidth)
                    .contentShape(Rectangle())
                    .onHoverTracking { isIn in
                        if isIn && !windowState.isSidebarVisible {
                            withAnimation(NookDesign.Motion.quick) {
                                hoverManager.isOverlayVisible = true
                            }
                        }
                        NSCursor.arrow.set()
                    }

                if hoverManager.isOverlayVisible {
                    SpacesSideBarView()
                        .spaceThemeAppearance(overlayTheme)
                        .frame(width: windowState.sidebarWidth)
                        .environmentObject(browserManager)
                        .environment(windowState)
                        .environment(commandPalette)
                        .environmentObject(browserManager.gradientColorManager)
                        .frame(maxHeight: .infinity)
                        .nookSidebarSurface(floating: true)
                        .overlay(alignment: nookSettings.sidebarPosition == .left ? .trailing : .leading) {
                            Rectangle()
                                .fill(.separator)
                                .frame(width: NookDesign.Size.hairlineWidth)
                                .allowsHitTesting(false)
                        }
                        .alwaysArrowCursor()
                        .transition(
                            .move(edge: nookSettings.sidebarPosition == .left ? .leading : .trailing)
                                .combined(with: .opacity)
                        )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: nookSettings.sidebarPosition == .left ? .topLeading : .topTrailing)
            .ignoresSafeArea(.container)
            .transaction { transaction in
                if reduceMotion { transaction.animation = nil }
            }
            // Container remains passive; only overlay/hotspot intercept
        }
    }

    private var overlayTheme: SpaceTheme? {
        guard !windowState.isIncognito, let spaceID = windowState.spaceID, spaceID != browserManager.tabs.agentSpaceID else { return nil }
        return browserManager.tabs.space(spaceID)?.theme
    }

}
