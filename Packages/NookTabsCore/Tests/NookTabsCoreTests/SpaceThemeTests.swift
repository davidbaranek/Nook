// Licensed under GPL-3.0. See LICENSE.
import Foundation
import Testing
@testable import NookTabsCore

struct SpaceThemeTests {
    @Test func transparencySettingsSurviveSavingASpace() throws {
        var f = Fixture()
        for style in SpaceTheme.TransparencyStyle.allCases {
            let theme = SpaceTheme(points: [.center], transparency: 0.65, transparencyStyle: style)
            try f.tree.setTheme(f.spaceA, theme: theme, now: fixedNow)
            let data = try JSONEncoder().encode(try #require(f.tree.space(f.spaceA)))
            let restored = try JSONDecoder().decode(SpaceRecord.self, from: data)
            #expect(restored.theme?.transparency == 0.65)
            #expect(restored.theme?.transparencyStyle == style)
        }
    }

    @Test func legacyThemesKeepTheirTransparencyFallback() throws {
        let theme = try JSONDecoder().decode(SpaceTheme.self, from: Data(#"{"intensity":0.4}"#.utf8))
        #expect(theme.transparency == nil)
        #expect(theme.transparencyStyle == .blur)
        let saved = try JSONDecoder().decode(SpaceTheme.self, from: JSONEncoder().encode(theme))
        #expect(saved.transparency == nil)
    }

    @Test func transparencyDecodeClampsAndToleratesFutureStyles() throws {
        let high = try JSONDecoder().decode(SpaceTheme.self, from: Data(#"{"transparency":9,"transparencyStyle":"future"}"#.utf8))
        #expect(high.transparency == 1)
        #expect(high.transparencyStyle == .blur)
        let low = SpaceTheme(points: [], transparency: -1)
        #expect(low.transparency == 0)
        let opaque = SpaceTheme(points: [], transparency: 0, transparencyStyle: .glass)
        let saved = try JSONDecoder().decode(SpaceTheme.self, from: JSONEncoder().encode(opaque))
        #expect(saved.transparency == 0)
    }

    @Test func canvasPointRoundTripsHueAndSaturation() {
        for hue in stride(from: 0.0, to: 360, by: 37) {
            let p = SpaceTheme.Point(hue: hue, saturation: 0.7)
            #expect(abs(p.hue - hue) < 1e-6)
            #expect(abs(p.saturation - 0.7) < 1e-6)
        }
        #expect(SpaceTheme.Point.center.saturation == 0)
    }

    @Test func pointsClampToCanvas() {
        let p = SpaceTheme.Point(x: -2, y: 5)
        #expect(p.x == 0 && p.y == 1)
        #expect(SpaceTheme.Point(hue: 90, saturation: 4).saturation <= 1)
    }

    @Test func everyHueResolvesInsideSRGB() {
        for hue in stride(from: 0.0, to: 360, by: 15) {
            let theme = SpaceTheme(points: [.init(hue: hue, saturation: 1)], intensity: 1)
            for dark in [true, false] {
                let resolved = theme.resolve(systemDark: dark)
                for c in resolved.stops + [resolved.accent, SpaceTheme.puckColor(theme.points[0], dark: dark)] {
                    #expect((0...1).contains(c.r) && (0...1).contains(c.g) && (0...1).contains(c.b))
                }
            }
        }
    }

    @Test func chromeKeepsTextContrast() {
        // Primary text is white on dark chrome and black on light chrome; both need 4.5:1.
        for hue in stride(from: 0.0, to: 360, by: 15) {
            let theme = SpaceTheme(points: [.init(hue: hue, saturation: 1)], intensity: 1)
            for stop in theme.resolve(systemDark: true).stops {
                #expect((1.05) / (stop.luminance + 0.05) >= 4.5)
            }
            for stop in theme.resolve(systemDark: false).stops {
                #expect((stop.luminance + 0.05) / 0.05 >= 4.5)
            }
        }
    }

    @Test func modeOverridesSystemAppearance() {
        #expect(SpaceTheme(points: [], mode: .dark).resolve(systemDark: false).isDark)
        #expect(!SpaceTheme(points: [], mode: .light).resolve(systemDark: true).isDark)
        #expect(SpaceTheme(points: [], mode: .auto).resolve(systemDark: true).isDark)
    }

    @Test func accentHexSeedsTheSameColor() throws {
        let hex = "#D6603A"
        let theme = SpaceTheme(accentHex: hex)
        let original = try #require(ThemeRGB(hex: hex))
        let back = SpaceTheme.accentColor(theme.points[0])
        // Same hue family: the accent is re-derived at a fixed lightness, so compare hue only.
        #expect(abs(back.oklch.h - original.oklch.h) < 2)
        #expect(ThemeRGB(hex: "nonsense") == nil)
    }

    @Test func colorCountIsOneToThree() {
        #expect(SpaceTheme(points: []).points.count == 1)
        #expect(SpaceTheme(points: [.center, .center, .center, .center]).points.count == 3)
    }

    @Test func decodingToleratesUnknownValues() throws {
        let json = #"{"points":[{"x":0.2,"y":0.3}],"mode":"sepia","intensity":"high"}"#
        let theme = try JSONDecoder().decode(SpaceTheme.self, from: Data(json.utf8))
        #expect(theme.mode == .auto && theme.intensity == 0.6 && theme.points.count == 1)
        // A space saved before themes existed still decodes.
        let saved = SpaceRecord(name: "A", icon: "", accentHex: "#3A8FA3", order: OrderKey("m"))
        var object = try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(saved)) as? [String: Any])
        object["theme"] = nil
        let record = try JSONDecoder().decode(SpaceRecord.self, from: JSONSerialization.data(withJSONObject: object))
        #expect(record.theme == nil)
    }

    @Test func setThemeDerivesAccent() throws {
        var f = Fixture()
        let theme = SpaceTheme(points: [.init(hue: 150, saturation: 1)])
        try f.tree.setTheme(f.spaceA, theme: theme, now: fixedNow)
        let space = try #require(f.tree.space(f.spaceA))
        #expect(space.theme == theme)
        #expect(space.accentHex == SpaceTheme.accentColor(theme.points[0]).hex)
    }
}
