// Licensed under GPL-3.0. See LICENSE.
import SwiftUI
import NookDesign
import NookUI

/// Native buttons supply their own hover, press, focus, disabled and accessibility states.
struct NookButtonStyle: PrimitiveButtonStyle {
    @Environment(\.nookHasGlassSurface) private var onGlass

    let variant: Variant
    let shadowStyle: ShadowStyle
    let role: ButtonRole?

    // Retain the existing call-site API while letting the system own shape and elevation.
    enum Variant { case secondary, primary }
    enum ShadowStyle { case none, subtle, prominent }

    @ViewBuilder
    func makeBody(configuration: Configuration) -> some View {
        if #available(macOS 26.0, *), !onGlass {
            if variant == .primary {
                button(configuration).buttonStyle(.glassProminent)
            } else {
                button(configuration).buttonStyle(.glass)
            }
        } else if variant == .primary {
            button(configuration).buttonStyle(.borderedProminent)
        } else {
            button(configuration).buttonStyle(.bordered)
        }
    }

    private func button(_ configuration: Configuration) -> some View {
        Button(role: role ?? configuration.role, action: configuration.trigger) {
            configuration.label
        }
        .controlSize(.large)
    }
}

// MARK: - Scale Button Style

struct ScaleButtonStyle: ButtonStyle {
    var scale: CGFloat = 0.95

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1.0)
            .animation(
                NookDesign.Motion.quick,
                value: configuration.isPressed
            )
    }
}

// MARK: - Convenience Extensions

extension PrimitiveButtonStyle where Self == NookButtonStyle {
    static var nookButton: NookButtonStyle {
        NookButtonStyle(variant: .secondary, shadowStyle: .subtle, role: nil)
    }

    static func nookButton(role: ButtonRole?) -> NookButtonStyle {
        NookButtonStyle(variant: .secondary, shadowStyle: .subtle, role: role)
    }

    static var nookButtonProminent: NookButtonStyle {
        NookButtonStyle(variant: .primary, shadowStyle: .prominent, role: nil)
    }

    static func nookButtonProminent(role: ButtonRole?) -> NookButtonStyle {
        NookButtonStyle(variant: .primary, shadowStyle: .prominent, role: role)
    }
}

#Preview {
    let colors = [Color.blue, Color.purple, Color.green, Color.orange, Color.pink, Color.red]

    return ScrollView {
        VStack(spacing: 40) {
            ForEach(colors, id: \.self) { color in
                ButtonPreviewSection(color: color)
            }
        }
        .padding()
    }
    .frame(width: 390, height: 1000)
}

private struct ButtonPreviewSection: View {
    let color: Color

    var body: some View {
        VStack(spacing: 20) {
            Text(colorName)
                .font(.headline)
                .foregroundStyle(.secondary)

            buttonStack
        }
        .padding()
        .background(.background.opacity(0.5))
        .clipShape(NookDesign.Radius.shape(NookDesign.Radius.lg))
        .environmentObject(makeColorManager())
    }

    private var colorName: String {
        color.description.capitalized
    }

    private func makeColorManager() -> GradientColorManager {
        let manager = GradientColorManager()
#if canImport(AppKit)
        let hex = color.toHexString(includeAlpha: true) ?? "#FFFFFFFF"
#else
        let hex = "#FFFFFFFF"
#endif
        let n1 = GradientNode(colorHex: hex, location: 0.0)
        let n2 = GradientNode(colorHex: hex, location: 1.0)
        let gradient = SpaceGradient(angle: 45.0, nodes: [n1, n2], grain: 0.05, opacity: 1.0)
        manager.setImmediate(gradient)
        return manager
    }

    private var buttonStack: some View {
        VStack(spacing: 20) {
            Button("Create Space", systemImage: "plus") {
            }
            .buttonStyle(.nookButtonProminent)

            Button("Cancel") {
            }
            .buttonStyle(.nookButton)

            Button("Delete", systemImage: "trash") {
            }
            .buttonStyle(.nookButton(role: .destructive))

            Button("Erase Everything", systemImage: "flame") {
            }
            .buttonStyle(.nookButtonProminent(role: .destructive))

            Button("Disabled") {
            }
            .buttonStyle(.nookButtonProminent)
            .disabled(true)
        }
    }
}
