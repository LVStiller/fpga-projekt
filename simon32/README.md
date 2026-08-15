# Simon32/64 Hardware-Implementierung

FPGA-Implementierung des leichtgewichtigen Blockchiffre Simon32/64
mit UART-Anbindung und Area-Optimierung.

**Kurs:** Security Hardware Design (Prof. Dr. Bernhard Jungk)
**Board:** Digilent Basys3 (Artix-7 XC7A35TCPG236-1)
**Autor:** Luis Vincent Stiller

## Struktur

| Pfad | Inhalt |
|---|---|
| `src/simon_core.vhd` | Chiffre-Kern, iterativ (1 Runde/Takt) |
| `src/simon_core_x2.vhd` | Entrollte Variante (2 Runden/Takt) |
| `src/uart_rx.vhd`, `src/uart_tx.vhd` | UART 115200 Baud |
| `src/simon_top.vhd` | Top-Level: UART-Protokoll + Core |
| `src/echo_top.vhd` | Hilfsdesign fuer Hardware-Bringup |
| `tb/` | Testbenches (alle selbstpruefend) |
| `constraints/basys3_simon.xdc` | Pins + QSPI-Konfiguration |
| `scripts/test.py` | Hardware-Test ueber serielle Schnittstelle |
| `flash/simon_top.mcs` | Fertiges Flash-Image (QSPI-Boot) |

## Simulation (NVC)

    make all        # alle Testbenches
    make core       # nur Basis-Core
    make core_x2    # nur entrollte Variante
    make clean

Referenz: offizieller Testvektor Simon32/64
(Klartext 0x65656877, Schluessel 0x1918111009080100
→ Chiffretext 0xC69BE9BB).

## Synthese und Hardware

Vivado 2024.2: `src/*.vhd` (ohne echo_top) + Constraints,
Top-Level `simon_top`, Bitstream generieren und flashen —
oder das fertige Flash-Image aus `flash/` in den QSPI-Flash
schreiben (Jumper JP1 auf QSPI: Board bootet autark).

## Hardware-Test

    python3 -m venv .venv && source .venv/bin/activate
    pip install pyserial
    python scripts/test.py <PORT>    # z.B. /dev/tty.usbserial-XXXX oder COM4