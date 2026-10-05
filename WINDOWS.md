# DeepGems com SwiftUIWeb no Windows

Branch: `feature/swiftuiweb-windows`, criada a partir da implementação mais recente do jogo (`afa1c3c`).

SwiftUIWeb **0.1.0** está instalado via Swift Package Manager, com versão exata no `Package.swift`. O target `DeepGemsWebPreview` importa a apresentação portátil `DeepGemsWebUI`, que usa SwiftUIWeb e o mesmo `DeepGemsCore` do app. O projeto Xcode continua nativo; a dependência web pertence aos targets SPM.

## Preparar o Windows uma vez

Instale Git e Swift **6.0 ou superior**, incluindo o compilador C++ e o Windows SDK exigidos pelo Swift, seguindo o guia oficial: https://www.swift.org/install/windows/ . Reabra o PowerShell após a instalação e confirme:

```powershell
git --version
swift --version
```

## Gerar e abrir

Na pasta do repositório:

```powershell
git fetch origin
git switch --track origin/feature/swiftuiweb-windows
swift package resolve
swift run DeepGemsWebPreview
Start-Process .\WebPreview\preview.html
```

Se a branch já existe localmente: `git switch feature/swiftuiweb-windows`, depois `git pull`.

Ou execute o script que resolve a dependência, gera e abre a prévia:

```powershell
.\Scripts\preview-windows.ps1
```

Se a política local impedir scripts, os comandos `swift` acima funcionam sem mudar essa política.

## Visualizar um save existente

Copie o arquivo `progress-v1.json` exportado do app para o PC. A ferramenta valida e lê o arquivo, sem modificá-lo:

```powershell
swift run DeepGemsWebPreview --save "C:\Meus arquivos\progress-v1.json" --output "C:\Meus arquivos\DeepGemsPreview"
Start-Process "C:\Meus arquivos\DeepGemsPreview\preview.html"
```

Sem `--save`, um cenário de demonstração é gerado pelas regras do jogo. Execute na raiz do repositório; `--assets-root` permite indicar outra localização dos assets. Copie a pasta completa `WebPreview` ao compartilhar a prévia, pois o HTML usa imagens locais em `assets`.

## Escopo desta instalação

A prévia mostra base, um corte da mina, objetivo, equipamentos e inventário. A navegação por âncoras funciona no navegador. Ela é **HTML estático**, não uma versão jogável: não executa SwiftUI/UIKit/SpriteKit, animações, compras, venda ou escavação. SwiftUIWeb 0.1.0 não traduz as telas nativas automaticamente; callbacks Swift de botões não rodam no navegador após exportar HTML. Um port jogável precisa de runtime web ou servidor, além desta instalação.

Não abra o `.xcodeproj` no Windows esperando compilar iOS. Use os targets SPM com Swift/VS Code; Xcode e o simulador iOS continuam exigindo macOS.

## Verificação

```powershell
swift build
swift test
swift run DeepGemsWebPreview --help
```

O workflow `SwiftUIWeb Windows checks` valida resolução, build, testes e exportação no runner Windows. A pasta gerada é disponibilizada como artifact no GitHub Actions, para abrir o HTML mesmo sem instalar Swift no computador.

Fonte da biblioteca: https://github.com/guiborges710/SwiftUIWeb
