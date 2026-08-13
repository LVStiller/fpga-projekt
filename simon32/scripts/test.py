#!/usr/bin/env python3
"""UART-Test fuer Simon32/64 auf dem BASYS3.

Schickt Schluessel + Klartext, prueft den Ciphertext
gegen den offiziellen NSA-Testvektor.
"""

import sys
import serial

# --- Konfiguration ---
PORT = sys.argv[1] if len(sys.argv) > 1 else "/dev/tty.usbserial-XXXX"
BAUD = 115200

# --- Testvektor Simon32/64 ---
KEY       = bytes.fromhex("1918111009080100")
PLAINTEXT = bytes.fromhex("65656877")
EXPECTED  = bytes.fromhex("C69BE9BB")

def main():
    print(f"Oeffne {PORT} mit {BAUD} Baud...")
    with serial.Serial(PORT, BAUD, timeout=2) as ser:
        ser.reset_input_buffer()

        tx = KEY + PLAINTEXT
        print(f"Sende  ({len(tx)} Bytes): {tx.hex().upper()}")
        ser.write(tx)

        rx = ser.read(4)
        if len(rx) < 4:
            print(f"FEHLER: Timeout – nur {len(rx)} Bytes empfangen.")
            print("Checkliste: richtiger Port? Bitstream geflasht? Reset gedrueckt?")
            sys.exit(1)

        print(f"Empfang (4 Bytes):  {rx.hex().upper()}")

        if rx == EXPECTED:
            print("TEST BESTANDEN: Ciphertext korrekt (C69BE9BB)")
        else:
            print(f"TEST FEHLGESCHLAGEN: erwartet {EXPECTED.hex().upper()}")
            sys.exit(1)

if __name__ == "__main__":
    main()