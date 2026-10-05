# Evolução do DeepGems

## O que mudou

- Uma mina fixa por save: túneis, dano parcial e estruturas continuam entre expedições.
- Janela de até 102 blocos ativos; histórico guarda somente blocos alterados.
- Três regiões: terra (0–11 m), cavernas de cobre (12–29 m), abismo de cristais (30 m+).
- Cobre e ferro aparecem nos blocos e financiam estruturas. As cavernas rendem mais cobre; o abismo rende mais ferro.
- Personagem com três estágios de roupa/lanterna e mochila visual a partir dos níveis 1, 2 e 3.
- Picareta presa à mão, com o mesmo ponto de apoio na base e na mina.
- Acampamento em três estágios: barraca, cabana e base ampliada; oficina, depósito e exposição acessíveis.
- Escadas permitem subir; luzes iluminam três blocos ao redor; elevadores conectam estações construídas à superfície.
- Relíquias em blocos especiais e uma sala secreta com uma ametista de alta pureza.
- Objetivos sequenciais com moedas concedidas uma única vez.
- Mapa vertical da escavação mostra os blocos alterados e construções, sem revelar minérios desconhecidos.

## Compatibilidade

O save permanece em `progress-v1.json`, com campos adicionais opcionais e cópia anterior automática. Moedas, XP, equipamentos, coleção, inventário, lapidação e expedição ativa são preservados. Saves antigos adotam a semente e os blocos alterados ainda presentes na expedição ativa. Túneis que a versão antiga já havia descartado não podem ser reconstruídos retroativamente.

## Testar no Xcode

1. Faça checkout de `feature/visible-mining-progression` e abra `DeepGems.xcodeproj`.
2. Execute o esquema `DeepGems` no simulador ou iPhone com iOS 17+.
3. Entre na mina, quebre o primeiro bloco abaixo e volte à base. Entre novamente: o bloco deve continuar vazio e não conceder outra gema.
4. Feche e reabra o app, inclusive no meio de uma escavação parcial. Confira dinheiro, recursos, inventário, profundidade e túneis.
5. Lapide a primeira gema e venda na Oficina. Melhore a mochila; confira a mudança na roupa, lanterna e mochila do explorador.
6. Quebre mais blocos. Construa uma luz usando cobre. Construa uma escada no bloco atual usando ferro e use a seta para cima. Sem energia, andar em blocos vazios e voltar à base continuam disponíveis.
7. Alcance 12 m, reúna 120 moedas e 8 ferros e instale um elevador. Pelo menu do elevador, viaje à superfície e volte à estação. Fora de uma estação, uma viagem deve ser recusada sem cobrar recursos.
8. Na base, construa a cabana (60 moedas, 3 ferros). A base ampliada requer 180 moedas, 8 ferros e 24 m. Confira as mudanças no cenário.
9. Explore os blocos `?`, confira a exposição e o mapa. A parede especial de 18 m dá acesso à descoberta da sala secreta.
10. Continue usando venda individual/em lote, lapidação, roupas e picaretas. Confira que objetivos não pagam novamente ao reabrir o app.

## Capturas reproduzíveis

Use os argumentos `-deepgems-preview -deepgems-screenshot` no esquema para um save temporário separado. Acrescente um destes argumentos:

| Tela | Argumento |
| --- | --- |
| Iniciante | `-deepgems-starter-preview` |
| Cabana | `-deepgems-camp2-preview` |
| Base avançada | `-deepgems-camp3-preview` |
| Mina profunda e estruturas | `-deepgems-depth-preview` |

O workflow iOS executa `swift test`, compila sem assinatura e publica as capturas no artifact `deepgems-screenshots`.

## Limites desta entrega

- Trilhos, carrinhos, perfuradoras e monetização continuam fora do escopo.
- Estágios do acampamento usam ilustrações vetoriais nativas; personagem e equipamentos reaproveitam os atlas existentes.
- Custos iniciais foram reduzidos a marcos acessíveis, mas a meta de evolução em dez minutos ainda precisa de uma sessão cronometrada com jogadores.
