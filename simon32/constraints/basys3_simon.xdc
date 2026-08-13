## ============================================================
## BASYS3 Constraints fuer Simon32/64
## Board: Artix-7 XC7A35TCPG236-1
## ============================================================

## Takt: 100 MHz
set_property PACKAGE_PIN W5  [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]
create_clock -add -name sys_clk -period 10.00 [get_ports clk]

## Reset: Button BTNC (Mitte)
set_property PACKAGE_PIN U18 [get_ports rst]
set_property IOSTANDARD LVCMOS33 [get_ports rst]

## UART ueber den USB-Bridge-Chip (feste Pins auf dem Board)
## RX = Daten vom PC zum FPGA
set_property PACKAGE_PIN B18 [get_ports uart_rx]
set_property IOSTANDARD LVCMOS33 [get_ports uart_rx]

## TX = Daten vom FPGA zum PC
set_property PACKAGE_PIN A18 [get_ports uart_tx]
set_property IOSTANDARD LVCMOS33 [get_ports uart_tx]

## Status-LEDs
set_property PACKAGE_PIN U16 [get_ports led_busy]
set_property IOSTANDARD LVCMOS33 [get_ports led_busy]
set_property PACKAGE_PIN E19 [get_ports led_done]
set_property IOSTANDARD LVCMOS33 [get_ports led_done]

## QSPI-Flash-Konfiguration (Boot vom Flash-Speicher)
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]
set_property CONFIG_MODE SPIx4 [current_design]