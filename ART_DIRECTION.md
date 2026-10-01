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


## Reference-led art pass 0.3

New production assets in `DeepGems/Resources/Assets.xcassets`: BaseV2, ExplorerV2, TerrainAtlas (four cells), UpgradeAtlas (six cells). Generated using the built-in image tool from the supplied Base / Exploração / Personagem reference. Original PNGs are preserved; transparent atlas padding is cropped and cached at runtime. Prompts: cartoon blue cave workshop with amber lanterns and empty foreground platform; youthful teal-shirt miner with amber helmet and empty glove; gray, earth and blue stone blocks plus lantern ladder; three leather-to-crystal backpacks and three leather-to-crystal boots. Explorer edit removed the handle so the equipped pickaxe can attach behind the glove.

Backpacks and boots change artwork at levels 3 and 6; later levels retain the epic artwork while stats continue increasing. Pickaxe upgrades improve strength; owned pickaxe kinds keep their own art. Lapidation now clips the sprite and reveals facets after each cut (stylized bevels, not a geometric gem simulation). The reference's pet and treasure chest are future features, not implemented mechanics.

Simulator preview arguments seed isolated temporary saves only and cannot replace the player's normal progress. CI captures Base, Loja, Melhorias, Mina and Lapidação.

Visual QA adjustment: remove the baked-in backpack from ExplorerV2 while preserving straps, pose and empty fist. Draw one equipped backpack behind the character at all levels. Calibrate pickaxe grip behind the glove with -55° SwiftUI rotation / +55° SpriteKit rotation. Reserve upper space for the miner's helmet at depth zero. Capture character, acquisition and partially/finally cut gems as well as main screens.

### Exact prompt set for the reference pass

All used the built-in image tool. The supplied three-phone illustration was the style reference for the four original production generations; the edits referenced the generated explorer sprite. TerrainAtlas, UpgradeAtlas and ExplorerV2 requested transparent backgrounds; BaseV2 requested an opaque background. Intermediate explorer variants are not used by the app.

**TerrainAtlas**
> Create a production game sprite atlas, using the attached image ONLY as STYLE REFERENCE. Match its charming polished cartoon mobile mining game, rounded chunky stones, amber lamps and dark blue cave palette. A horizontal strip of EXACTLY FOUR equal square cells, isolated sprites centered inside each cell, transparent background, no text no UI: cell1 chunky square gray stone block with beveled edges and cracks; cell2 square earthy brown stone block; cell3 square dark blue stone block; cell4 wooden ladder with amber hanging lantern. Blocks almost fill cells but clear gaps between objects. Front view 2D game, not isometric. No phone mockup.

**UpgradeAtlas**
> Create a production game item atlas using attached image as STYLE REFERENCE ONLY. EXACTLY SIX equally sized square cells in ONE horizontal strip on genuinely transparent background. Polished charming cartoon mobile game, thick clean shapes, warm gold lighting and blue rim light. Left to right: simple brown leather explorer backpack, upgraded brown leather backpack with metal clasps and a purple crystal sticking out, epic ornate backpack with golden plates and crystals, simple leather explorer boots pair, upgraded sturdy boots pair with bronze guards, epic boots pair with gold guards and cyan crystal accents. Each object centered wholly inside its own equal cell with ample transparent margin. No words, no frames, no UI, no phone.

**ExplorerV2 generation**
> Create a single production character sprite using attached image as style reference ONLY. Match the cute youthful male miner proportions, expressive big eyes, amber hardhat with bright lamp, turquoise shirt, brown gloves and leather backpack, dark pants and brown boots in the rightmost phone. Full body front three-quarter view facing slightly right, standing confidently. His right hand (viewer right) holds a short visible brown handle at hip height with NO pickaxe head: game attaches interchangeable weapon there. The other hand relaxed. Entire body visible centered, minimal transparent padding, genuinely transparent background. Polished 2D cartoon mobile game, not realistic, clean readable silhouette, no companion, no background, no text or UI.

**ExplorerV2 first edit**
> Edit ONLY the hand holding the wooden handle: remove the entire visible wooden handle, leaving that same hand at the same location as a closed gloved fist (empty). Preserve every other part of the character, exact pose, scale, proportions, colors and transparent background. Remove colored haze outside the silhouette to get clean transparent sprite edges. Do not add any weapon or new objects.

**ExplorerV2 final edit**
> Edit this EXACT character sprite. Remove ONLY the backpack body and rolled sleeping mat behind his left shoulder and left torso (viewer left). Preserve leather shoulder straps worn over his shirt. Keep exact face, helmet, empty fist, clothing, boots, pose, proportions and pixel placement. The game will draw an interchangeable backpack behind him. Truly transparent background, clean alpha edges, no haze outside silhouette. Do not add objects.

**BaseV2**
> Use attached image ONLY as style reference. Create a portrait 2D cartoon mobile game background matching the leftmost phone's cave base exactly in mood: cozy wooden miner workshop under dark blue cave arch, amber lanterns, distant purple-blue mountain view on upper right, wooden workbench left, small purple crystal clusters by floor, stone platform foreground bottom center reserved for character. Charming clean rounded shapes, rich painterly cartoon detail, dramatic amber and blue light. No people, no pets, no UI, no typography, no phone, no border. Portrait composition with darker upper fifth to hold game HUD.
