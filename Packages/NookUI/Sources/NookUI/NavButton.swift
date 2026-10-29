// Licensed under GPL-3.0. See LICENSE.
//
//  NavButton.swift
//  Nook
//
//  Created by Maciek Bagiński on 30/07/2025.
//  Updated by Aether Aurelia on 11/10/2025.
//

import SwiftUI
import NookDesign

/// System icon buttons retain Nook's hit area without hand-drawn hover/press effects.
public struct NookIconButtonStyle: PrimitiveButtonStyle {
    @Environment(\.nookHasGlassSurface) private var onGlass
    let size: CGFloat
    let radius: CGFloat

    public init(size: CGFloat = NookDesign.Size.iconButton, radius: CGFloat = NookDesign.Radius.md) {
        self.size = size
        self.radius = radius
    }

    @ViewBuilder
    public func makeBody(configuration: Configuration) -> some View {
        #if os(macOS)
        if #available(macOS 26.0, *), !onGlass {
            // The system owns the glass button's font, padding and intrinsic size.
            GlassButtonStyle().makeBody(configuration: configuration)
        } else {
            inlineButton(configuration).buttonStyle(.borderless)
        }
        #else
        inlineButton(configuration).buttonStyle(.borderless)
        #endif
    }

    private func inlineButton(_ configuration: Configuration) -> some View {
        Button(role: configuration.role, action: configuration.trigger) {
            configuration.label
                .frame(width: size, height: size)
                .contentShape(Rectangle())
        }
    }

}

/// A roomy label inside the system's circular bezel; no outer frame clips the glass.
public struct NookToolbarIconButtonStyle: PrimitiveButtonStyle {
    public init() {}

    @ViewBuilder
    public func makeBody(configuration: Configuration) -> some View {
        if #available(macOS 26.0, *) {
            button(configuration).buttonStyle(.glass)
        } else {
            button(configuration).buttonStyle(.bordered)
        }
    }

    private func button(_ configuration: Configuration) -> some View {
        Button(role: configuration.role, action: configuration.trigger) {
            configuration.label
                .font(.system(size: NookDesign.Toolbar.icon))
                .frame(width: NookDesign.Toolbar.icon, height: NookDesign.Toolbar.icon)
                .padding(NookDesign.Toolbar.buttonPadding)
        }
        .labelStyle(.iconOnly)
        .buttonBorderShape(.circle)
        .controlSize(.large)
    }
}

public extension View {
    func nookSidebarIconButtons() -> some View {
        labelStyle(.iconOnly)
            .font(.system(size: NookDesign.SidebarChrome.icon, weight: .regular))
            .buttonStyle(NookIconButtonStyle(size: NookDesign.SidebarChrome.button))
    }

    func nookIconButtons() -> some View {
        labelStyle(.iconOnly)
            .buttonStyle(NookIconButtonStyle())
    }
}

/// Labeled controls use the standard borderless style; system controlSize determines sizing.
public struct RectNavButtonStyle: PrimitiveButtonStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        Button(role: configuration.role, action: configuration.trigger) {
            configuration.label
                .padding(.horizontal, NookDesign.Spacing.sm)
        }
        .buttonStyle(.borderless)
    }
}

#Preview("Square Buttons") {
    VStack(spacing: 20) {
        // Default
        Button {
        } label: {
            Image(systemName: "arrow.left")
        }
        .buttonStyle(NookIconButtonStyle())
        .foregroundStyle(Color.primary)

        // With foregroundStyle
        Button {
        } label: {
            Image(systemName: "heart.fill")
        }
        .buttonStyle(NookIconButtonStyle())
        .foregroundStyle(.red)

        // Different sizes
        HStack {
            Button { } label: { Image(systemName: "star") }
                .buttonStyle(NookIconButtonStyle(size: 24))
                .foregroundStyle(Color.pink)

            Button { } label: { Image(systemName: "star") }
                .buttonStyle(NookIconButtonStyle(size: 28))
                .foregroundStyle(Color.purple)

            Button { } label: { Image(systemName: "star") }
                .buttonStyle(NookIconButtonStyle())
                .foregroundStyle(Color.yellow)

            Button { } label: { Image(systemName: "star") }
                .buttonStyle(NookIconButtonStyle(size: 40))
                .foregroundStyle(Color.orange)
        }

        // Disabled
        Button {
        } label: {
            Image(systemName: "trash")
        }
        .buttonStyle(NookIconButtonStyle())
        .foregroundStyle(Color.primary)
        .disabled(true)
    }
    .padding()
}

#Preview("Rectangular Buttons") {
    VStack(spacing: 20) {
        // Icon with text
        Button {
        } label: {
            Label("New Space", systemImage: "plus")
        }
        .buttonStyle(RectNavButtonStyle())
        .foregroundStyle(Color.primary)

        // Icon only (still rectangular due to padding)
        Button {
        } label: {
            Image(systemName: "plus")
        }
        .buttonStyle(RectNavButtonStyle())
        .foregroundStyle(Color.primary)

        // Different sizes
        VStack(spacing: 12) {
            Button { } label: { Label("Mini", systemImage: "star") }
                .buttonStyle(RectNavButtonStyle())
                .foregroundStyle(Color.pink)
                .controlSize(.mini)

            Button { } label: { Label("Small", systemImage: "star") }
                .buttonStyle(RectNavButtonStyle())
                .foregroundStyle(Color.purple)
                .controlSize(.small)

            Button { } label: { Label("Regular", systemImage: "star") }
                .buttonStyle(RectNavButtonStyle())
                .foregroundStyle(Color.yellow)

            Button { } label: { Label("Large", systemImage: "star") }
                .buttonStyle(RectNavButtonStyle())
                .foregroundStyle(Color.orange)
                .controlSize(.large)
        }

        // Disabled
        Button {
        } label: {
            Label("Disabled", systemImage: "xmark")
        }
        .buttonStyle(RectNavButtonStyle())
        .foregroundStyle(Color.primary)
        .disabled(true)
    }
    .padding()
}
