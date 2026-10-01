import SpriteKit
import UIKit
import Metal
import OSLog

@MainActor
final class MineScene: SKScene {
    var onSelect: ((GridPosition) -> Void)?
    private var expedition: Expedition?
    private var outfit: Outfit = .teal
    private var pickaxe: PickaxeKind = .iron
    private var backpackLevel = 1
    private var staminaLevel = 1
    private var weaponNode: SKSpriteNode?
    private var playerNode: SKNode?
    private var textures: [String: SKTexture] = [:]
    private var visibleFirstRow = 0
    private var tileSize: CGFloat = 45
    private var boardOrigin = CGPoint.zero
    private let visibleRows = 6
    private var reportedFrame = false
    override func didMove(to view: SKView) {
        Logger(subsystem: "com.guiborges.deepgems", category: "render").notice("Mine attached: bounds=\(view.bounds.width)x\(view.bounds.height), Metal=\(MTLCreateSystemDefaultDevice() != nil)")
    }
    override func update(_ currentTime: TimeInterval) {
        if !reportedFrame {
            reportedFrame = true
            Logger(subsystem: "com.guiborges.deepgems", category: "render").notice("Mine first frame: width=\(self.size.width), height=\(self.size.height), Metal=\(MTLCreateSystemDefaultDevice() != nil)")
        }
    }
    override init(size: CGSize = CGSize(width: 360, height: 400)) {
        super.init(size: size); scaleMode = .resizeFill
        backgroundColor = UIColor(red: 0.025, green: 0.045, blue: 0.09, alpha: 1)
    }
    required init?(coder: NSCoder) { fatalError("Use init(size:)") }
    override func didChangeSize(_ oldSize: CGSize) { redraw(previous: nil) }
    func render(expedition: Expedition?, outfit: Outfit, pickaxe: PickaxeKind, backpackLevel: Int = 1, staminaLevel: Int = 1) {
        let previous = self.expedition?.player
        self.expedition = expedition; self.outfit = outfit; self.pickaxe = pickaxe
        self.backpackLevel = backpackLevel; self.staminaLevel = staminaLevel
        redraw(previous: previous)
    }
    private func texture(_ key: String, image: () -> UIImage) -> SKTexture {
        if let t = textures[key] { return t }
        let t = SKTexture(image: image()); textures[key] = t; return t
    }
    private func redraw(previous: GridPosition?) {
        removeAllChildren(); weaponNode = nil; playerNode = nil
        guard let e = expedition else { return }
        tileSize = min(size.width / CGFloat(GameEngine.columns), max(1, size.height - 22) / CGFloat(visibleRows))
        boardOrigin = .init(x: (size.width - tileSize * CGFloat(GameEngine.columns)) / 2, y: (size.height - tileSize * CGFloat(visibleRows) - 22) / 2)
        visibleFirstRow = max(0, e.player.row - 2)
        for tile in e.tiles where (visibleFirstRow..<(visibleFirstRow + visibleRows)).contains(tile.position.row) {
            let point = center(for: tile.position)
            let adjacent = tile.position.isAdjacent(to: e.player)
            let terrainIndex = tile.isEmpty ? 2 : tile.hardness % 3
            let rock = SKSpriteNode(texture: texture("terrain-\(terrainIndex)") { GameArtwork.terrain(terrainIndex) })
            rock.size = .init(width: tileSize + 1, height: tileSize + 1); rock.position = point
            if tile.isEmpty { rock.color = .black; rock.colorBlendFactor = 0.75 }
            addChild(rock)
            if tile.isEmpty && tile.position.column == 0 && tile.position.row % 3 == 0 {
                let ladder = SKSpriteNode(texture: texture("ladder") { GameArtwork.terrain(3) })
                ladder.size = .init(width: tileSize * 0.85, height: tileSize * 1.2); ladder.position = point; ladder.zPosition = 1
                addChild(ladder)
            }
            if adjacent {
                let highlight = SKShapeNode(rectOf: .init(width: tileSize-3, height: tileSize-3), cornerRadius: 8)
                highlight.position = point; highlight.fillColor = UIColor.systemOrange.withAlphaComponent(0.04)
                highlight.strokeColor = .systemOrange; highlight.lineWidth = 2; highlight.glowWidth = 3; highlight.zPosition = 3
                addChild(highlight)
            }
            if let gem = tile.gem, !tile.isEmpty {
                let crystal = SKSpriteNode(texture: texture("gem-\(gem.kind.rawValue)") { GameArtwork.gem(gem.kind) })
                crystal.size = .init(width: tileSize * 0.58, height: tileSize * 0.7)
                crystal.position = point; crystal.zPosition = 2; addChild(crystal)
            }
            if !tile.isEmpty && tile.remaining < tile.hardness {
                let crack = CGMutablePath()
                crack.move(to: .init(x: -tileSize*0.4, y: tileSize*0.3)); crack.addLine(to: .init(x: tileSize*0.08, y: 0)); crack.addLine(to: .init(x: -tileSize*0.12, y: -tileSize*0.4))
                let fissure = SKShapeNode(path: crack); fissure.position = point; fissure.strokeColor = .black; fissure.lineWidth = 2 + 3 * CGFloat(tile.hardness-tile.remaining) / CGFloat(tile.hardness); fissure.zPosition = 3; addChild(fissure)
                let health = SKShapeNode(rectOf: .init(width: (tileSize-12)*CGFloat(tile.remaining)/CGFloat(tile.hardness), height: 3), cornerRadius: 1)
                health.position = .init(x: point.x, y: point.y-tileSize*0.4); health.fillColor = .systemOrange; health.strokeColor = .clear; health.zPosition = 4; addChild(health)
            }
        }
        let player = SKNode(); player.position = center(for: e.player); player.zPosition = 5
        let halo = SKShapeNode(circleOfRadius: tileSize * 0.85)
        halo.fillColor = UIColor.systemYellow.withAlphaComponent(0.08); halo.strokeColor = .clear; halo.glowWidth = 10; player.addChild(halo)
        let shadow = SKShapeNode(ellipseOf: .init(width: tileSize*0.8, height: tileSize*0.18)); shadow.fillColor = .black.withAlphaComponent(0.5); shadow.strokeColor = .clear; shadow.position.y = -tileSize*0.38; player.addChild(shadow)
        let rig = SKNode(); player.addChild(rig)
        let image = GameArtwork.explorer(outfit)
        let h = tileSize * 1.35, w = h * image.size.width / max(1, image.size.height)
        if backpackLevel >= 1 {
            let pack = SKSpriteNode(texture: texture("pack-\(backpackLevel >= 6 ? 2 : (backpackLevel >= 3 ? 1 : 0))") { GameArtwork.upgrade(.backpack, level: backpackLevel) })
            pack.size = .init(width: w*0.48, height: h*0.34); pack.position = .init(x: -w*0.27, y: h*0.03); rig.addChild(pack)
        }
        let weapon = SKSpriteNode(texture: texture("weapon-\(pickaxe.rawValue)") { GameArtwork.pickaxe(pickaxe) })
        weapon.size = .init(width: h*0.42, height: h*0.42); weapon.anchorPoint = .init(x: 0.3, y: 0.3)
        weapon.position = .init(x: -w*0.20, y: -h*0.12); weapon.zRotation = CGFloat.pi * 55 / 180; weapon.zPosition = 1
        rig.addChild(weapon); weaponNode = weapon
        let body = SKSpriteNode(texture: texture("explorer-\(outfit.rawValue)") { image })
        body.size = .init(width: w, height: h); body.zPosition = 2; rig.addChild(body)
        if staminaLevel >= 3 {
            let boots = SKSpriteNode(texture: texture("boots-\(staminaLevel >= 6 ? 2 : 1)") { GameArtwork.upgrade(.stamina, level: staminaLevel) })
            boots.size = .init(width: w*0.78, height: h*0.2); boots.position.y = -h*0.39; boots.zPosition = 3; rig.addChild(boots)
        }
        addChild(player); playerNode = player
        rig.run(.repeatForever(.sequence([.moveBy(x: 0, y: 1, duration: 0.9), .moveBy(x: 0, y: -1, duration: 0.9)])))
        if let previous, previous != e.player {
            let destination = player.position; player.position = center(for: previous)
            player.run(.move(to: destination, duration: 0.12))
        }
    }
    func strike(at position: GridPosition) {
        guard expedition != nil else { return }
        let point = center(for: position)
        weaponNode?.run(.sequence([.rotate(byAngle: -0.7, duration: 0.05), .rotate(byAngle: 1.1, duration: 0.09), .rotate(byAngle: -0.4, duration: 0.12)]))
        if let player = playerNode {
            let dx = point.x-player.position.x, dy = point.y-player.position.y
            player.run(.sequence([.moveBy(x: dx*0.1, y: dy*0.1, duration: 0.06), .moveBy(x: -dx*0.1, y: -dy*0.1, duration: 0.1)]))
        }
        burst(at: point, color: pickaxe.impactColor, count: 10)
    }
    func discovery(at position: GridPosition) {
        let point = center(for: position)
        burst(at: point, color: .systemYellow, count: 16)
        let label = SKLabelNode(text: "+1 gema"); label.fontName = "AvenirNext-Bold"; label.fontSize = 15; label.fontColor = .systemYellow; label.position = point; label.zPosition = 20; addChild(label)
        label.run(.sequence([.group([.moveBy(x: 0, y: 45, duration: 0.8), .fadeOut(withDuration: 0.8)]), .removeFromParent()]))
    }
    private func burst(at point: CGPoint, color: UIColor, count: Int) {
        let flash = SKShapeNode(circleOfRadius: tileSize*0.2); flash.position = point; flash.fillColor = color.withAlphaComponent(0.5); flash.strokeColor = .clear; flash.zPosition = 10; addChild(flash)
        flash.run(.sequence([.group([.scale(to: 2, duration: 0.25), .fadeOut(withDuration: 0.25)]), .removeFromParent()]))
        for i in 0..<count {
            let chip = SKShapeNode(rectOf: .init(width: 3, height: 5), cornerRadius: 1); chip.position = point; chip.fillColor = color; chip.strokeColor = .clear; chip.zPosition = 11
            let a = CGFloat(i)*2 * .pi / CGFloat(count); addChild(chip)
            chip.run(.sequence([.group([.moveBy(x: cos(a)*tileSize*0.7, y: sin(a)*tileSize*0.7, duration: 0.4), .rotate(byAngle: a, duration: 0.4), .fadeOut(withDuration: 0.4)]), .removeFromParent()]))
        }
    }
    private func center(for position: GridPosition) -> CGPoint {
        .init(x: boardOrigin.x + (CGFloat(position.column)+0.5)*tileSize, y: boardOrigin.y + (CGFloat(visibleRows-(position.row-visibleFirstRow))-0.5)*tileSize)
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let point = touches.first?.location(in: self) else { return }
        let x = point.x-boardOrigin.x, y = point.y-boardOrigin.y
        guard x >= 0, y >= 0, x < tileSize*CGFloat(GameEngine.columns), y < tileSize*CGFloat(visibleRows) else { return }
        onSelect?(.init(column: Int(x/tileSize), row: visibleFirstRow+visibleRows-1-Int(y/tileSize)))
    }
}
