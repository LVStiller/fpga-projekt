# ============================================================
# Makefile fuer Aufgabe 1.4 - GHDL Simulation
# ============================================================
# Befehle:
#   make          -> Kompiliert und simuliert alles
#   make compile  -> Nur kompilieren
#   make sim      -> Simulation starten
#   make wave     -> Waveform in GTKWave oeffnen
#   make clean    -> Alles aufraeumen
# ============================================================

GHDL = ghdl
GTKWAVE = gtkwave

# VHDL Quelldateien
SRC = src/adder_top.vhd src/adder_top_tb.vhd

# Top-Level Testbench Entity
TB = adder_top_tb

# Waveform Datei
VCD = waveform.vcd

# Simulationsdauer
SIM_TIME = 500ns

# ---- Targets ----

all: compile sim
	@echo ""
	@echo "=== Fertig! ==="
	@echo "Oeffne die Waveform mit: make wave"

compile:
	@echo "=== VHDL analysieren ==="
	$(GHDL) -a --std=08 $(SRC)
	@echo "=== Elaborieren ==="
	$(GHDL) -e --std=08 $(TB)

sim: compile
	@echo "=== Simulation starten ($(SIM_TIME)) ==="
	$(GHDL) -r --std=08 $(TB) --vcd=$(VCD) --stop-time=$(SIM_TIME)

wave: $(VCD)
	@echo "=== GTKWave oeffnen ==="
	$(GTKWAVE) $(VCD) &

clean:
	@echo "=== Aufraeumen ==="
	$(GHDL) --clean
	rm -f $(VCD)
	rm -f *.cf
	rm -f $(TB)

.PHONY: all compile sim wave clean
