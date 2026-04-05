# Aufgabe 1.4 - 8-Bit Addierer (Variante 1)

## Beschreibung

Zwei 8-Bit-Zahlen werden gleichzeitig über die 16 Switches des BASYS3-Boards
eingegeben und addiert. Das Ergebnis wird auf der 7-Segment-Anzeige als
Dezimalzahl (0–510) und auf den LEDs als Binärzahl (9 Bit) angezeigt.

## Belegung auf dem BASYS3-Board

| Hardware       | Funktion                        |
|---------------|---------------------------------|
| SW 0–7        | Zahl A (8 Bit, 0–255)          |
| SW 8–15       | Zahl B (8 Bit, 0–255)          |
| LED 0–8       | Ergebnis binär (9 Bit)         |
| 7-Segment     | Ergebnis dezimal (0–510)       |

## Projektstruktur

```
fpga-projekt/
├── src/
│   ├── adder_top.vhd          # Hauptmodul (Addierer + 7-Segment)
│   └── adder_top_tb.vhd       # Testbench
├── constraints/
│   └── Basys3_adder.xdc       # Pin-Zuordnung für BASYS3
├── Makefile                    # GHDL Build-Automatisierung
└── README.md                  # Diese Datei
```

## Simulation mit GHDL (nativ auf Mac)

```bash
# Alles kompilieren und simulieren
make

# Waveform anschauen
make wave

# Aufräumen
make clean
```

## Synthese mit Vivado (in der VM)

1. Vivado öffnen → Create Project → RTL Project
2. FPGA: Artix-7 XC7A35T-1CPG236C
3. `src/adder_top.vhd` als Design Source hinzufügen
4. `constraints/Basys3_adder.xdc` als Constraints hinzufügen
5. Run Synthesis → Run Implementation → Generate Bitstream
6. Open Hardware Manager → Program Device
