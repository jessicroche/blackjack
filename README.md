# Blackjack em FPGA (VHDL)

Este projeto implementa o jogo de Blackjack (21) em uma FPGA DE1 - Cyclone II, utilizando VHDL. O sistema é composto por duas máquinas de estados finitas (FSMs): uma para o controle do jogo e outra para a geração de cartas (aleatória ou manual). O projeto foi desenvolvido para a disciplina de Sistemas Digitais na UFFS.

## Funcionalidades

- Distribuição automática de cartas para jogador e dealer
- Lógica completa de HIT, STAY, vitória, derrota e empate
- Ás tratado como 1 ou 11 automaticamente
- Geração de cartas aleatória ou manual (para testes)
- Exibição das cartas e somas em displays de 7 segmentos
- Indicação de vitória, derrota e empate por LEDs
- Reset do jogo via botão START

## Estrutura do Projeto

```
Blackjack/
├── codigos em VHDL/
│   ├── blackjack.vhd         -- FSM principal do jogo
│   ├── cards.vhd             -- Gerador de cartas (aleatório/manual)
│   └── top_blackjack.vhd     -- Top-level para integração e mapeamento FPGA
├── quartus_blackjack/        -- Projeto Quartus II
├── arquivos de texto/        -- Documentação, imagens e relatório
└── README.md
```



## Mapeamento FPGA

| Sinal        | FPGA         | Função                        |
|--------------|--------------|-------------------------------|
| clk          | KEY(0)       | Clock                         |
| reset/start  | KEY(1)       | Reset do sistema              |
| hit          | SW(0)        | HIT (pedir carta)             |
| stay         | SW(1)        | STAY (parar)                  |
| reqManual    | SW(5)        | Modo manual de carta          |
| cartaManual  | SW(9:6)      | Valor da carta manual         |
| Plose        | LEDR(0)      | Derrota                       |
| TIE          | LEDR(1)      | Empate                        |
| Pwin         | LEDR(2)      | Vitória                       |
| HEX0         | HEX0         | Dígito 1 da soma              |
| HEX1         | HEX1         | Dígito 2 da soma              |
| HEX3         | HEX3         | Carta atual (hexadecimal)     |


## Autores

- Arthur Emanuel da Silva
- Jéssica Brito da Silva

**UFFS - Ciência da Computação - Sistemas Digitais - 2025**