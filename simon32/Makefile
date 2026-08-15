# ============================================================
# Makefile fuer Simon32/64 – NVC Simulation
# Verwendung:
#   make all          → alle Testbenches ausfuehren
#   make core         → Simon-Core (Basisvariante) testen
#   make core_x2      → entrollte Variante testen
#   make uart         → UART-Empfaenger + Loopback testen
#   make top          → System-Testbench (UART + Core)
#   make clean        → Build-Artefakte loeschen
# ============================================================

NVC = nvc

SRC = src
TB  = tb

.PHONY: all core core_x2 uart top clean

all: core core_x2 uart top

core:
	$(NVC) -a $(SRC)/simon_core.vhd $(TB)/tb_simon_core.vhd
	$(NVC) -e tb_simon_core
	$(NVC) -r tb_simon_core

core_x2:
	$(NVC) -a $(SRC)/simon_core_x2.vhd $(TB)/tb_simon_core_x2.vhd
	$(NVC) -e tb_simon_core_x2
	$(NVC) -r tb_simon_core_x2

uart:
	$(NVC) -a $(SRC)/uart_rx.vhd $(SRC)/uart_tx.vhd
	$(NVC) -a $(TB)/tb_uart_rx.vhd $(TB)/tb_uart_loopback.vhd
	$(NVC) -e tb_uart_rx
	$(NVC) -r tb_uart_rx
	$(NVC) -e tb_uart_loopback
	$(NVC) -r tb_uart_loopback

top: uart core
	$(NVC) -a $(SRC)/simon_top.vhd $(TB)/tb_simon_top.vhd
	$(NVC) -e tb_simon_top
	$(NVC) -r tb_simon_top

clean:
	rm -rf work *.fst