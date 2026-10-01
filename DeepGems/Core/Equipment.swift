import Foundation

public enum PickaxeKind: String, Codable, CaseIterable, Identifiable {
    case iron, copper, amethyst
    public var id: String { rawValue }
    public var name: String {
        switch self { case .iron: return "Ferro do Explorador"; case .copper: return "Garra de Cobre"; case .amethyst: return "Coração de Ametista" }
    }
    public var rarity: String {
        switch self { case .iron: return "Comum"; case .copper: return "Rara"; case .amethyst: return "Épica" }
    }
    public var bonus: Int {
        switch self { case .iron: return 0; case .copper: return 2; case .amethyst: return 5 }
    }
    public var price: Int {
        switch self { case .iron: return 0; case .copper: return 180; case .amethyst: return 650 }
    }
    public var detail: String {
        switch self {
        case .iron: return "O primeiro passo para grandes descobertas. Ferro resistente e cabo de madeira."
        case .copper: return "Cobre reforçado para golpes mais fortes. Deixa faíscas quentes a cada impacto."
        case .amethyst: return "Um núcleo de cristal violeta. Força superior e fragmentos luminosos ao escavar."
        }
    }
}
