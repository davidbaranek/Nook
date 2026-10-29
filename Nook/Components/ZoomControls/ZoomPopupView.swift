// Licensed under GPL-3.0. See LICENSE.
//
//  ZoomPopupView.swift
//  Nook
//
//  Created by Jonathan Caudill on 13/10/2025.
//

import SwiftUI
import NookDesign

struct ZoomPopupView: View {
    var zoomManager: ZoomManager
    let onZoomIn: () -> Void
    let onZoomOut: () -> Void
    let onZoomReset: () -> Void
    let onDismiss: () -> Void

    @State private var isVisible = false
    @State private var hideTimer: Timer?

    var body: some View {
        HStack(spacing: NookDesign.Spacing.md) {
            Button("Zoom Out", systemImage: "minus") {
                onZoomOut()
                resetHideTimer()
            }
            .labelStyle(.iconOnly)
            .help("Zoom Out")
            .disabled(zoomManager.isAtMinimumZoom)

            Button(zoomManager.getZoomPercentageDisplay()) {
                onZoomReset()
                resetHideTimer()
            }
            .help("Reset Zoom")

            Button("Zoom In", systemImage: "plus") {
                onZoomIn()
                resetHideTimer()
            }
            .labelStyle(.iconOnly)
            .help("Zoom In")
            .disabled(zoomManager.isAtMaximumZoom)
        }
        .buttonStyle(.borderless)
        .controlSize(.small)
        .padding(12)
        .frame(maxWidth: 160)
        .nookFloatingSurface(in: NookDesign.Radius.shape(NookDesign.Radius.lg))
        .scaleEffect(isVisible ? 1.0 : 0.8)
        .opacity(isVisible ? 1.0 : 0.0)
        .animation(NookDesign.Motion.spring, value: isVisible)
        .onAppear {
            isVisible = true
            startHideTimer()
        }
        .onChange(of: zoomManager.currentZoomLevel) {
            resetHideTimer()
        }
        .onDisappear {
            hideTimer?.invalidate()
        }
    }

    // MARK: - Timer Management

    private func startHideTimer() {
        hideTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
            onDismiss()
        }
    }

    private func resetHideTimer() {
        hideTimer?.invalidate()
        startHideTimer()
    }
}

// MARK: - Preview

#Preview {
    ZoomPopupView(
        zoomManager: ZoomManager(),
        onZoomIn: {},
        onZoomOut: {},
        onZoomReset: {},
        onDismiss: {}
    )
    .padding()
    .background(Color.gray.opacity(0.3))
}

