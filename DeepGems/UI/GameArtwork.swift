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
    static func gem(_ kind: GemKind) -> UIImage {
        let index = GemKind.allCases.firstIndex(of: kind) ?? 0
        return region(name: "GemAtlas", index: index, count: 5)
    }
    static func explorer(_ outfit: Outfit) -> UIImage {
        let key = "explorer-\(outfit.rawValue)"
        if let image = cache[key] { return image }
        let original = UIImage(named: "ExplorerIllustration") ?? UIImage()
        guard outfit != .teal, let source = original.cgImage else { cache[key] = original; return original }
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
                if outfit == .purple {
                    bytes[i] = UInt8(min(alpha, b * 0.95)); bytes[i + 1] = UInt8(min(alpha, r * 1.05)); bytes[i + 2] = UInt8(min(alpha, g * 1.1))
                } else {
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
        cache[key] = image
        return image
    }
    private static func region(name: String, index: Int, count: Int) -> UIImage {
        let key = "\(name)-\(index)"
        if let image = cache[key] { return image }
        guard let source = UIImage(named: name)?.cgImage else { return UIImage() }
        let left = source.width * index / count
        let right = source.width * (index + 1) / count
        let bounds = CGRect(x: left, y: 0, width: right - left, height: source.height)
        guard let crop = source.cropping(to: bounds) else { return UIImage() }
        let image = UIImage(cgImage: crop)
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

struct ExplorerShowcase: View {
    let outfit: Outfit
    let pickaxe: PickaxeKind
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Image(uiImage: GameArtwork.explorer(outfit)).resizable().scaledToFit()
                PickaxeArt(kind: pickaxe).frame(width: geometry.size.width * 0.42)
                    .rotationEffect(.degrees(-18)).offset(x: geometry.size.width * 0.26, y: geometry.size.height * 0.12)
            }
        }.accessibilityElement(children: .ignore)
            .accessibilityLabel("Explorador usando \(outfit.name), equipado com \(pickaxe.name)")
    }
}

struct BaseShowcase: View {
    let outfit: Outfit
    let pickaxe: PickaxeKind
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                Image("BaseIllustration").resizable().scaledToFill().frame(width: geometry.size.width, height: geometry.size.height).clipped()
                LinearGradient(colors: [.black.opacity(0.05), .clear, Color.deepBackground.opacity(0.85)], startPoint: .top, endPoint: .bottom)
                ExplorerShowcase(outfit: outfit, pickaxe: pickaxe).frame(width: geometry.size.width * 0.7, height: geometry.size.height * 0.82).padding(.bottom, 20)
                VStack {
                    HStack { Label("OFICINA DO EXPLORADOR", systemImage: "sparkles").font(.caption2.bold()).tracking(1.5); Spacer() }
                    Spacer()
                    HStack { VStack(alignment: .leading, spacing: 4) { Text(pickaxe.name).font(.headline); Text(pickaxe.rarity.uppercased()).font(.caption2.bold()).foregroundStyle(pickaxe.color) }; Spacer() }
                }.padding(18)
            }
        }.clipShape(RoundedRectangle(cornerRadius: 26))
            .overlay(RoundedRectangle(cornerRadius: 26).stroke(Color.deepGold.opacity(0.25)))
    }
}
