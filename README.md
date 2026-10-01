# DeepGems ⛏️💎

Protótipo iOS de exploração, lapidação e evolução. SwiftUI nas telas; SpriteKit na mina. Arte geométrica desenhada em código, inspirada na direção de cores dos conceitos visuais — ainda não são as ilustrações finais.

## Abrir no Mac

Requisitos: **Xcode 15 ou superior**, iOS 17 ou superior. Não precisa de CocoaPods, Tuist, XcodeGen, servidor ou API key.

```bash
git clone https://github.com/guiborges710/deep-gems-ios.git
cd deep-gems-ios
open DeepGems.xcodeproj
```

Selecione o scheme **DeepGems**, um iPhone no simulador e pressione **⌘R**. Para iPhone físico, selecione seu Team em Signing & Capabilities e ajuste o Bundle Identifier se necessário. Para futuras atualizações:

```bash
git pull --ff-only
```

Abra o `.xcodeproj`, não o Package.swift. O package serve para os testes independentes da lógica.

## Primeiro teste: 5 minutos

1. Veja o tutorial e entre na mina. Personagem começa no nível 0.
2. Toque no quartzo imediatamente abaixo do personagem: primeira descoberta garantida.
3. Escave outros blocos adjacentes; confira energia e mochila.
4. Feche e reabra o app durante a expedição: posição, energia e saque devem continuar.
5. Volte à base e abra Oficina. Selecione uma pedra bruta e toque Lapidar.
6. Alinhe a linha dourada com a pontilhada, depois deslize verticalmente ou toque Executar corte.
7. Feche e reabra durante a lapidação: cortes concluídos devem persistir.
8. Termine, venda a peça e confira moedas. Com 60 moedas, compre a primeira melhoria na Base.
9. Confira Coleção e Personagem. Roupas extras desbloqueiam nos níveis 3 e 6.
10. Retorne à mina: uma nova expedição começa com energia cheia.

## Conteúdo

- Mina procedural em trechos: blocos adjacentes, resistência, coleta e profundidade crescente.
- Cinco pedras: Quartzo (0 m), Ametista (8 m), Esmeralda (20 m), Rubi (35 m), Diamante (55 m). Profundidade permite o surgimento, não garante a descoberta.
- Lapidação: três cortes, quatro no diamante. Tolerância varia; ametista alterna ângulos e esmeralda tem uma fissura a evitar. São regras fictícias de jogo, não simulação gemológica.
- Valor depende de quilates, pureza e qualidade do corte. Uma lapidação ruim continua tendo valor.
- Venda ao próprio jogo; picareta, mochila e resistência melhoráveis.
- XP com limiares crescentes, catálogo de descobertas e três roupas.
- Auto-save após ações, cópia da versão anterior, recuperação de backup e erro visível se salvar falhar.
- Gestos e botões alternativos; layouts roláveis para aparelhos menores.

## Persistência e limites

Save em Application Support/DeepGems (`progress-v1.json` e `progress-v1.backup.json`). A cópia anterior é uma proteção local, não backup em nuvem. Desinstalar o app pode apagar os dados. Reinstalações e troca de Bundle Identifier não mantêm necessariamente o save.

Corrompimento dos dois arquivos bloqueia as ações; o app oferece tentar carregar novamente ou começar novo jogo. O reset copia os arquivos anteriores para uma pasta de arquivo antes de reiniciar. Em falha de gravação, o estado permanece em memória e novas ações ficam bloqueadas até uma tentativa bem-sucedida.

A mina mantém poucos trechos na memória; não permite revisitar toda a expedição. Retornar à base encerra essa mina; outra expedição gera um novo mapa. Esta versão não implementa perda de saque, perigos, inimigos, biomas, prestígio ou mineração offline. Limites técnicos do protótipo: equipamentos até nível 1.000, profundidade até 10 milhões de metros e saldos/XP até 1 bilhão. Não anunciamos conteúdo literalmente infinito.

Ainda não há compras, anúncios, pets, multiplayer, conta online ou mercado entre jogadores. A loja e a economia de dinheiro real vêm depois de validar o ciclo de diversão. Um futuro mercado exige servidor autoritativo; este save local não é confiável para itens negociáveis.

## Organização

- `DeepGems/Core`: modelos Codable, regras sem dependência de UI, geração procedural e SaveStore.
- `DeepGems/UI`: estado de apresentação, telas SwiftUI, arte geométrica e MineScene.
- `Tests/DeepGemsCoreTests`: regras de coleta, venda, progressão, lapidação e recuperação do save.
- `.github/workflows/ios.yml`: testes Swift e build do app para simulador em macOS.

```bash
swift test
xcodebuild -project DeepGems.xcodeproj -scheme DeepGems -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build
```

A compilação iOS e o teste visual precisam de macOS/Xcode. Consulte o status real do workflow; não considere o app compilado apenas porque os arquivos estão no Git.
