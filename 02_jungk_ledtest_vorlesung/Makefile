NVC = nvc
GTKWAVE = surfer

SRC = src/adder_top.vhd src/adder_top_tb.vhd
TB = adder_top_tb
VCD = waveform.vcd
SIM_TIME = 500ns

all: compile sim
	@echo ""
	@echo "=== Fertig! ==="
	@echo "Oeffne die Waveform mit: make wave"

compile:
	@echo "=== VHDL analysieren ==="
	$(NVC) --std=2008 -a $(SRC)
	@echo "=== Elaborieren ==="
	$(NVC) --std=2008 -e $(TB)

sim: compile
	@echo "=== Simulation starten ($(SIM_TIME)) ==="
	$(NVC) -r $(TB) --stop-time=$(SIM_TIME) --format=vcd --wave=$(VCD)

wave: $(VCD)
	@echo "=== GTKWave oeffnen ==="
	$(GTKWAVE) $(VCD) &

clean:
	@echo "=== Aufraeumen ==="
	rm -rf work
	rm -f $(VCD)

.PHONY: all compile sim wave clean
