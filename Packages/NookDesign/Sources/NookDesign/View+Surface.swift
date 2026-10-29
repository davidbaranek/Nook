// Licensed under GPL-3.0. See LICENSE.
//
//  View+Surface.swift
//  Nook
//
//  System materials for navigation and floating controls; ordinary fills for content rows.
//

import SwiftUI
#if os(macOS)
import AppKit
#endif

private struct DefaultSpaceThemeKey: EnvironmentKey {
    static let defaultValue = false
}

public extension EnvironmentValues {
    /// Controls inside a material-backed surface avoid an additional glass layer.
    @Entry var nookHasGlassSurface = false
    @Entry var nookSelectedTab = false
    /// True while the chrome shows a space with no custom theme.
    var nookUsesDefaultSpaceTheme: Bool {
        get { self[DefaultSpaceThemeKey.self] }
        set { self[DefaultSpaceThemeKey.self] = newValue }
    }
}

public extension View {
    /// A soft page-frame shadow, drawn separately from live WebKit content.
    /// Removing the silhouette's fill keeps split gutters transparent to the window theme.
    func nookWebPageShadow<S: Shape>(in shape: S, enabled: Bool = true) -> some View {
        background {
            if enabled {
                shape.fill(Color.black)
                    .shadow(color: .black.opacity(0.20), radius: 6, x: 0, y: 2)
                    .shadow(color: .black.opacity(0.08), radius: 1, x: 0, y: 0)
                    .overlay {
                        shape.fill(Color.black).blendMode(.destinationOut)
                    }
                    // Only the shadow is composited; the page and its video layers
                    // remain outside this group.
                    .compositingGroup()
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
        }
    }

    /// Text-heavy transient panels use the semantic popover material. Unlike a generic
    /// glass effect for a control, this surface suppresses distracting background detail.
    @ViewBuilder
    func nookFloatingSurface<S: InsettableShape>(in shape: S) -> some View {
        #if os(macOS)
        self.clipShape(shape)
            .background {
                NookPopoverMaterial()
                    .clipShape(shape)
                    .allowsHitTesting(false)
            }
            .overlay(shape.strokeBorder(NookDesign.Surface.hairline, lineWidth: NookDesign.Size.hairlineWidth)
                .allowsHitTesting(false))
            .nookElevation(.floating)
            .environment(\.nookHasGlassSurface, true)
        #else
        self.clipShape(shape)
            .background(shape.fill(NookDesign.Surface.raised))
            .overlay(shape.strokeBorder(NookDesign.Surface.hairline, lineWidth: NookDesign.Size.hairlineWidth))
            .nookElevation(.floating)
        #endif
    }

    /// Glass is behind the column only: do not clip its live pager or anchored address panel.
    func nookSidebarSurface(floating: Bool = false) -> some View {
        background {
            Group {
                if floating {
                    sidebarMaterial
                } else {
                    // A docked column shares an edge with the page; its glass must not
                    // cast the floating-panel shadow across that adjacent content.
                    sidebarMaterial.clipped()
                }
            }
            .allowsHitTesting(false)
        }
        .environment(\.nookHasGlassSurface, true)
    }

    /// Controls over video: a dark scrim, whatever the page or appearance.
    func nookMediaControl<S: Shape>(in shape: S) -> some View {
        background(shape.fill(NookDesign.Surface.mediaScrim))
    }

    /// Anything chosen from a set outside the tab list (Settings sidebar, library tabs, history):
    /// a solid raised fill and hairline, readable on plain backgrounds. Tab rows use
    /// `nookTabSurface`. Branch-free; the row applies its own `.raised` elevation.
    func nookRowSelection(_ isSelected: Bool, radius: CGFloat = NookDesign.Radius.md) -> some View {
        let shape = NookDesign.Radius.shape(radius)
        return background(shape.fill(isSelected ? NookDesign.Surface.raised : .clear))
            .overlay(shape.strokeBorder(NookDesign.Surface.hairline.opacity(isSelected ? 1 : 0), lineWidth: NookDesign.Size.hairlineWidth))
    }

    /// A sidebar chrome control or group: history, sidebar and AI toggles, bottom bar buttons,
    /// search fields, filter chips. `tint` marks the chosen one of a set.
    func nookControlSurface<S: InsettableShape>(_ isOn: Bool = true, tint: Color? = nil, in shape: S) -> some View {
        background(shape.fill(isOn ? (tint?.opacity(NookDesign.Surface.tintOpacity) ?? NookDesign.Surface.fill) : .clear))
    }
}

#if os(macOS)
/// These panels live inside the browser window, so sample its content rather than the
/// desktop. AppKit owns material density, vibrancy and Reduce Transparency behavior.
private struct NookPopoverMaterial: NSViewRepresentable {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.colorSchemeContrast) private var contrast

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = .popover
        view.blendingMode = .withinWindow
        view.state = .followsWindowActiveState
        return view
    }

    func updateNSView(_ view: NSVisualEffectView, context: Context) {
        let dark = colorScheme == .dark
        let name: NSAppearance.Name = contrast == .increased
            ? (dark ? .accessibilityHighContrastDarkAqua : .accessibilityHighContrastAqua)
            : (dark ? .darkAqua : .aqua)
        view.appearance = NSAppearance(named: name)
    }
}
#endif

@ViewBuilder
private var sidebarMaterial: some View {
    #if os(macOS)
    if #available(macOS 26.0, *) {
        Rectangle().fill(.clear)
            .glassEffect(.regular, in: Rectangle())
    } else {
        Rectangle().fill(.regularMaterial)
    }
    #else
    Rectangle().fill(.regularMaterial)
    #endif
}

/// Native tab interaction; Reduce Motion keeps the pressed card at its original scale.
public struct NookTabButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? NookDesign.Tab.pressScale : 1)
            .animation(reduceMotion ? nil : NookDesign.Motion.quick, value: configuration.isPressed)
    }
}

public extension View {
    /// Tab card shared by sidebar rows, split rows and native drag previews: the theme-tinted
    /// selection fill, a hover fill, and a continuous `Tab.radius` shape.
    func nookTabSurface(selected: Bool, hovered: Bool = false) -> some View {
        modifier(NookTabSurface(selected: selected, hovered: hovered))
    }
}

private struct NookTabSurface: ViewModifier {
    let selected: Bool
    let hovered: Bool
    #if os(macOS)
    @Environment(\.controlActiveState) private var activeState
    #endif

    func body(content: Content) -> some View {
        let shape = NookDesign.Radius.shape(NookDesign.Tab.radius)
        content
            .clipShape(shape)
            .background(shape.fill(fill))
            .contentShape(shape)
            .environment(\.nookSelectedTab, selected)
    }

    private var fill: Color {
        guard selected else { return hovered ? NookDesign.Surface.fill : .clear }
        #if os(macOS)
        return activeState == .inactive ? NookDesign.Surface.inactiveSelectedTab : NookDesign.Surface.selectedTab
        #else
        return NookDesign.Surface.selection
        #endif
    }
}

public extension View {
    /// Text and monochrome symbols use the foreground paired with the system selection fill.
    func nookTabForeground() -> some View { modifier(NookTabForeground()) }
}

private struct NookTabForeground: ViewModifier {
    @Environment(\.nookSelectedTab) private var selected
    #if os(macOS)
    @Environment(\.controlActiveState) private var activeState
    #endif

    func body(content: Content) -> some View {
        #if os(macOS)
        content.foregroundStyle(selected
            ? (activeState == .inactive ? NookDesign.Surface.inactiveSelectedTabText : NookDesign.Surface.selectedTabText)
            : Color.primary)
        #else
        content.foregroundStyle(.primary)
        #endif
    }
}
