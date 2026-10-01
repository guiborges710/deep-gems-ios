# DeepGems — arte 0.2

Direção: aventura 2D ilustrada, azul profundo, luz âmbar e cristais violetas. Assets criados com a geração de imagens integrada; as imagens originais são preservadas no catálogo do Xcode.

Arquivos: `DeepGems/Resources/Assets.xcassets/{BaseIllustration,ExplorerIllustration,PickaxeAtlas,GemAtlas}.imageset/asset.png`.

Os atlas são recortados em memória por `GameArtwork.swift`, sem alteração dos arquivos originais. A recoloração das roupas ocorre em tempo de execução. O personagem ainda não possui frames de animação independentes; movimento e golpes usam transformações e partículas.

Os conceitos anteriores não são screenshots do app. A captura automática da Base fica nos artifacts do workflow iOS.

## Prompts utilizados

### base

Use case: stylized-concept. Asset type: actual portrait mobile 2D game background, NOT a UI mockup. Create a richly illustrated cozy mining base inside a cavern: wooden workbench and workshop to left, crates of ore at lower left, glowing violet crystals right, amber lanterns, distant twilight blue cavern opening at upper right. Hand painted polished 2D fantasy game art with soft 3D volume, teal navy purple amber palette matching an inviting miner adventure. Portrait 2:3 composition, central lower floor area clear and empty for overlaying a separate explorer sprite. Top quarter relatively dark and quiet for HUD overlay, bottom quiet for buttons. No people, no tools in central clear foreground, no text, no lettering, no UI, no borders, no logos. Detailed surroundings, atmospheric warm lighting, crisp readable silhouettes.

### explorer

Use case: stylized-concept. Asset type: actual transparent character sprite for a 2D mobile mining game. ONE full body young adult explorer, charming stylized hand-painted 2D game illustration with soft 3D volume, facing three-quarter right. Amber miner helmet with round lamp, brown hair, teal jacket, brown belt, dark trousers, sturdy brown boots, small brown backpack. Neutral standing pose, feet level, right hand in a natural grasping pose at hip height ready for a separately overlaid tool, BOTH HANDS EMPTY, no pickaxe or weapon. Isolated centered figure fills 80 percent of tall canvas, all body visible, adequate empty margin around helmet and boots, clean silhouette. Polished mobile game art, matching navy teal amber violet mining world. Truly transparent background, no floor, no scenery, no text, no checkerboard painted in, no drop shadow outside character.

### pickaxes

Use case: stylized-concept. Asset type: actual transparent equipment sprite sheet for mobile mining game. A landscape sheet split into exactly THREE EQUAL WIDTH INVISIBLE CELLS in ONE horizontal row. Each cell contains exactly ONE complete isolated pickaxe centered, entire item fully inside its cell with generous margins. No visible cell separators. All pickaxes same orientation: wooden handle diagonally from bottom-left to upper-right, metal pickaxe head at top. First cell: humble worn iron pickaxe, wood handle, rugged metal. Second cell: impressive heavy copper pickaxe with reinforced leather handle and polished copper head. Third cell: spectacular amethyst pickaxe with large purple crystals integrated in curved steel blade, engraved gold fittings, restrained luminous violet highlights. Hand painted detailed 2D fantasy game item illustrations, soft 3D volume, coherent realistic silhouettes, beautiful collectible equipment. Each item about 75 percent of its cell width and height, consistent size, no overlapping cells. True transparent background everywhere between objects, no labels, no prices, no UI, no ground, no frame, no external cast shadows.

### gems

Use case: stylized-concept. Asset type: actual transparent collectible gemstone sprite sheet. Landscape image with exactly FIVE EQUAL WIDTH INVISIBLE CELLS in ONE horizontal row. In cell 1 a milky translucent quartz crystal, cell 2 vivid violet amethyst, cell 3 saturated green emerald, cell 4 ruby red gemstone, cell 5 icy cyan diamond. Exactly one isolated gem per cell, all similar size centered precisely in cell, gems occupy about 65 percent cell width with generous clear transparent margins and no overlap. Brilliant faceted hand painted polished 2D fantasy mobile game illustrations with soft 3D volume, crisp silhouettes, restrained inner glow and highlights. Transparent background, no labels, no text, no numbers, no ground, no frames, no cast shadows outside each object.

