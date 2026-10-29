// Licensed under GPL-3.0. See LICENSE.

import AppKit
import SwiftUI

/// A semantic system backdrop lets the desktop show through unthemed window chrome.
/// The sidebar's glass is a separate foreground layer, not a manually coloured blur.
struct NativeChromeBackdrop: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = .underWindowBackground
        view.blendingMode = .behindWindow
        view.state = .followsWindowActiveState
        return view
    }

    func updateNSView(_ view: NSVisualEffectView, context: Context) {}
}
