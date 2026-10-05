import SwiftUI
import UIKit

/// Atlas regions are read from the original generated PNGs at runtime.
/// The source images remain intact, and the cached crops are shared by SwiftUI and SpriteKit.
@MainActor
enum GameArtwork {
    private static var cache: [String: UIImage] = [:]
    static func pickaxe(_ kind: PickaxeKind) -> UIImage {
        let index = PickaxeKind.allCases.firstIndex(of: kind) ?? 0
        return region(name: "PickaxeAtlas", index: index, count: 3)
    }
    static func portrait(_ outfit: Outfit) -> UIImage {
        let key = "portrait-\(outfit.rawValue)"
        if let image = cache[key] { return image }
        let source = explorer(outfit)
        guard let cg = source.cgImage, let crop = cg.cropping(to: CGRect(x: CGFloat(cg.width) * 0.24, y: CGFloat(cg.height) * 0.02, width: CGFloat(cg.width) * 0.6, height: CGFloat(cg.height) * 0.3)) else { return source }
        let image = UIImage(cgImage: crop); cache[key] = image; return image
    }
    static func terrain(_ index: Int) -> UIImage { region(name: "TerrainAtlas", index: index, count: 4) }
    static func upgrade(_ kind: Upgrade, level: Int, pickaxe: PickaxeKind = .iron) -> UIImage {
        if kind == .pickaxe { return self.pickaxe(pickaxe) }
        let tier = level >= 3 ? 2 : (level >= 2 ? 1 : 0)
        return region(name: "UpgradeAtlas", index: (kind == .backpack ? 0 : 3) + tier, count: 6)
    }
    static func gem(_ kind: GemKind) -> UIImage {
        let index = GemKind.allCases.firstIndex(of: kind) ?? 0
        return region(name: "GemAtlas", index: index, count: 5)
    }
    static func explorer(_ outfit: Outfit, tier: Int = 2) -> UIImage {
        let key = "explorer-\(outfit.rawValue)-\(tier)"
        if let image = cache[key] { return image }
        let original = UIImage(named: "ExplorerV2") ?? UIImage()
        guard let source = original.cgImage else { cache[key] = original; return original }
        // Recolor only teal cloth pixels at render time. Skin, helmet, leather and alpha are preserved.
        let width = source.width, height = source.height
        var bytes = [UInt8](repeating: 0, count: width * height * 4)
        let space = CGColorSpaceCreateDeviceRGB()
        let drewSource = bytes.withUnsafeMutableBytes { buffer -> Bool in
            guard let context = CGContext(data: buffer.baseAddress, width: width, height: height, bitsPerComponent: 8,
                                          bytesPerRow: width * 4, space: space,
                                          bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return false }
            context.draw(source, in: CGRect(x: 0, y: 0, width: width, height: height))
            return true
        }
        guard drewSource else { return original }
        // The hue test is restricted to the jacket band, excluding the cave glow around the silhouette.
        for y in (height / 4)..<(height * 3 / 5) {
            for x in (width / 6)..<(width * 5 / 6) {
                let i = (y * width + x) * 4
                let r = Double(bytes[i]), g = Double(bytes[i + 1]), b = Double(bytes[i + 2])
                guard bytes[i + 3] > 180, g > r * 1.25, b > r * 1.2, abs(g - b) < max(g, b) * 0.55 else { continue }
                let alpha = Double(bytes[i + 3])
                if tier == 1 {
                    bytes[i] = UInt8(min(alpha, g * 0.85)); bytes[i + 1] = UInt8(min(alpha, g * 0.65)); bytes[i + 2] = UInt8(min(alpha, g * 0.42))
                } else if outfit == .purple || tier == 3 {
                    bytes[i] = UInt8(min(alpha, b * 0.95)); bytes[i + 1] = UInt8(min(alpha, r * 1.05)); bytes[i + 2] = UInt8(min(alpha, g * 1.1))
                } else if outfit == .orange {
                    bytes[i] = UInt8(min(alpha, g * 1.2)); bytes[i + 1] = UInt8(min(alpha, b * 0.65)); bytes[i + 2] = UInt8(min(alpha, r * 0.7))
                }
            }
        }
        // A second context reads the changed buffer; avoid retaining temporary pointer storage.
        let image: UIImage = bytes.withUnsafeMutableBytes { buffer in
            guard let output = CGContext(data: buffer.baseAddress, width: width, height: height, bitsPerComponent: 8,
                                         bytesPerRow: width * 4, space: space,
                                         bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)?.makeImage() else { return original }
            return UIImage(cgImage: output)
        }
        let renderer = UIGraphicsImageRenderer(size: image.size)
        let result = renderer.image { _ in
            image.draw(at: .zero)
            let w = image.size.width, h = image.size.height
            if tier == 1 {
                UIColor.brown.setFill()
                UIBezierPath(ovalIn: CGRect(x: w * 0.63, y: h * 0.044, width: w * 0.11, height: h * 0.07)).fill()
                UIColor.darkGray.setFill()
                UIBezierPath(ovalIn: CGRect(x: w * 0.65, y: h * 0.052, width: w * 0.075, height: h * 0.052)).fill()
            } else if tier == 3 {
                UIColor.systemPurple.withAlphaComponent(0.8).setFill()
                UIBezierPath(roundedRect: CGRect(x: w * 0.41, y: h * 0.105, width: w * 0.2, height: h * 0.025), cornerRadius: h * 0.01).fill()
                UIColor.white.setFill()
                UIBezierPath(ovalIn: CGRect(x: w * 0.65, y: h * 0.052, width: w * 0.075, height: h * 0.052)).fill()
            }
        }
        cache[key] = result
        return result
    }
    private static func trimmed(_ image: UIImage) -> UIImage {
        guard let source = image.cgImage else { return image }
        let w = source.width, h = source.height
        var bytes = [UInt8](repeating: 0, count: w * h * 4)
        let ok = bytes.withUnsafeMutableBytes { buffer -> Bool in
            guard let c = CGContext(data: buffer.baseAddress, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 4, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return false }
            c.draw(source, in: CGRect(x: 0, y: 0, width: w, height: h)); return true
        }
        guard ok else { return image }
        var left = w, right = 0, top = h, bottom = 0
        for y in 0..<h { for x in 0..<w where bytes[(y*w+x)*4+3] > 40 {
            left = min(left, x); right = max(right, x); top = min(top, y); bottom = max(bottom, y)
        } }
        guard right > left, bottom > top, let crop = source.cropping(to: CGRect(x: left, y: top, width: right-left+1, height: bottom-top+1)) else { return image }
        return UIImage(cgImage: crop)
    }
    private static func region(name: String, index: Int, count: Int) -> UIImage {
        let key = "\(name)-\(index)"
        if let image = cache[key] { return image }
        guard let source = UIImage(named: name)?.cgImage else { return UIImage() }
        let left = source.width * index / count
        let right = source.width * (index + 1) / count
        let bounds = CGRect(x: left, y: 0, width: right - left, height: source.height)
        guard let crop = source.cropping(to: bounds) else { return UIImage() }
        let image = trimmed(UIImage(cgImage: crop))
        cache[key] = image
        return image
    }
}

extension PickaxeKind {
    var color: Color {
        switch self { case .iron: return .gray; case .copper: return .orange; case .amethyst: return .purple }
    }
    var impactColor: UIColor {
        switch self { case .iron: return .lightGray; case .copper: return .systemOrange; case .amethyst: return .systemPurple }
    }
}

struct PickaxeArt: View {
    let kind: PickaxeKind
    var body: some View {
        Image(uiImage: GameArtwork.pickaxe(kind)).resizable().scaledToFit()
            .shadow(color: kind.color.opacity(0.4), radius: kind == .amethyst ? 14 : 5)
            .accessibilityLabel(kind.name)
    }
}

struct UpgradeArt: View {
    let kind: Upgrade
    let level: Int
    var pickaxe: PickaxeKind = .iron
    var body: some View {
        Image(uiImage: GameArtwork.upgrade(kind, level: level, pickaxe: pickaxe)).resizable().scaledToFit()
            .shadow(color: (kind == .stamina ? Color.deepTeal : .deepGold).opacity(0.25), radius: 8)
            .accessibilityLabel("\(kind.name), nível \(level)")
    }
}

struct ExplorerShowcase: View {
    let outfit: Outfit
    let pickaxe: PickaxeKind
    var backpackLevel = 1
    var staminaLevel = 1
    var body: some View {
        GeometryReader { geometry in
            let image = GameArtwork.explorer(outfit, tier: backpackLevel >= 3 || pickaxe == .amethyst ? 3 : (backpackLevel >= 2 || pickaxe == .copper ? 2 : 1))
            let ratio = image.size.width / max(1, image.size.height)
            let h = min(geometry.size.height, geometry.size.width / ratio)
            let w = h * ratio
            ZStack {
                if backpackLevel >= 1 {
                    UpgradeArt(kind: .backpack, level: backpackLevel).frame(width: w * 0.48, height: h * 0.34)
                        .offset(x: -w * 0.27, y: -h * 0.03)
                }
                Image(uiImage: image).resizable().frame(width: w, height: h)
                // Grip is calibrated against ExplorerV2's left glove and the normalized pickaxe shaft.
                Image(uiImage: GameArtwork.pickaxe(pickaxe)).resizable().scaledToFit()
                    .frame(width: h * 0.42, height: h * 0.42)
                    .rotationEffect(.degrees(-18), anchor: UnitPoint(x: 0.26, y: 0.75))
                    .position(x: geometry.size.width / 2 - w * 0.19 + h * 0.42 * 0.24, y: geometry.size.height / 2 + h * 0.14 - h * 0.42 * 0.25)
                    .allowsHitTesting(false)
                Ellipse().fill(Color(red: 0.38, green: 0.20, blue: 0.09)).frame(width: w * 0.075, height: h * 0.023)
                    .offset(x: -w * 0.19, y: h * 0.14)
                if staminaLevel >= 3 {
                    UpgradeArt(kind: .stamina, level: staminaLevel).frame(width: w * 0.78, height: h * 0.2).offset(y: h * 0.39)
                }
            }.frame(width: geometry.size.width, height: geometry.size.height)
        }.accessibilityElement(children: .ignore)
            .accessibilityLabel("Explorador usando \(outfit.name), equipado com \(pickaxe.name), mochila nível \(backpackLevel)")
    }
}

struct BaseShowcase: View {
    let outfit: Outfit
    let pickaxe: PickaxeKind
    var backpackLevel = 1
    var staminaLevel = 1
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                Image("BaseV2").resizable().scaledToFill().frame(width: geometry.size.width, height: geometry.size.height).clipped()
                ExplorerShowcase(outfit: outfit, pickaxe: pickaxe, backpackLevel: backpackLevel, staminaLevel: staminaLevel)
                    .frame(width: geometry.size.width * 0.78, height: geometry.size.height * 0.83).padding(.bottom, 18)
            }
        }.clipShape(RoundedRectangle(cornerRadius: 22))
    }
}
