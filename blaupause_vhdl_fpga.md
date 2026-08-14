# Blaupause: VHDL-Projekt auf FPGA (Altera DE0 / Quartus)

Wiederverwendbare Vorgehensweise für den kompletten Weg vom leeren Blatt
bis zum laufenden Chip auf dem Board. Die Phasen bauen aufeinander auf —
jede wird erst abgehakt, wenn sie verifiziert ist, bevor die nächste beginnt.

Grundprinzip: **Erst denken, dann simulieren, dann erst Hardware.** Jeder
Fehler, den du in der Simulation findest, kostet Minuten. Derselbe Fehler auf
dem Board kostet Stunden.

---

## Die sieben Phasen auf einen Blick

| Phase | Inhalt | Ergebnis |
|-------|--------|----------|
| 0 | Toolchain-Test | Werkzeugkette läuft nachweislich |
| 1 | Spezifikation auf Papier | klares Pflichtenheft |
| 2 | Top-Entity | äußere Schnittstelle steht |
| 3 | Blockschaltbild / Dekomposition | Module + interne Signale festgelegt |
| 4 | Module einzeln bauen + simulieren | jedes Modul einzeln verifiziert |
| 5 | Integration | Gesamtsystem simuliert sauber |
| 6 | Synthese in Quartus | `.sof` erzeugt |
| 7 | Aufs Board + Test | Chip läuft und ist genau |

---

## Phase 0 — Toolchain-Test

Bevor das eigentliche Design beginnt: beweise, dass deine Werkzeugkette
funktioniert. Ein triviales Modul (z.B. ein einzelnes Register) bauen,
simulieren, Wellenform anschauen.

Warum: Wenn später etwas nicht klappt, willst du wissen, ob es am Design
liegt oder an der Umgebung. Diese Frage klärst du jetzt, nicht mitten im
Projekt.

Heimumgebung (Mac):
- Editor: IntelliJ (nur Editor, keine Synthese)
- Simulator: NVC
- Wellenform: Surfer
- Build: Makefile, Ordner `src/` und `tb/`

Einzelnes Modul simulieren:
```
nvc --std=2008 -a src/MODUL.vhd tb/MODUL_tb.vhd
nvc --std=2008 -e MODUL_tb
nvc -r MODUL_tb --wave=MODUL.vcd
surfer MODUL.vcd
```

Konkreter Beispielcode (ein Register + Testbench) und ein Lückentext zum
Selbsttesten stehen in **Anhang A** am Ende.

---

## Phase 1 — Spezifikation auf Papier

Keine Zeile Code, bevor das hier steht. Schreib es auf:

- **Ein- und Ausgänge:** Welche physischen Signale (Taster, Takt, Anzeige, LEDs)?
- **Verhalten:** Was genau soll passieren?
- **Sonderfälle festlegen** — die werden später zu Bugs, wenn du sie offen lässt:
  - Überlauf: wraparound auf 0, oder anhalten, oder sättigen?
  - Reset: nur Wert auf 0, oder auch anhalten?
  - Gleichzeitige Eingaben: was gewinnt?
- **Zahlendarstellung:** intern als Integer und erst am Ausgang umrechnen,
  oder durchgängig BCD? Faustregel: Zählen ist trivial, Umrechnen ist die
  Arbeit — also intern Integer, Umrechnung nur am Ausgang.
- **Genauigkeit → Taktteiler:** Zielfrequenz aus dem Boardtakt berechnen.
  Beispiel: 50 MHz / 10 Hz = 5 000 000. Exakt, sonst läuft die Uhr falsch.

---

## Phase 2 — Top-Entity

Die äußere Schnittstelle als Entity — die Ports, die später echte Pins werden.
Nur Ports, noch keine Architektur.

Worauf achten:
- Portrichtung **explizit** angeben (`in` / `out`). Ohne Angabe ist es `in` —
  klassische Falle bei Ausgängen.
- Vektorbreiten festlegen (z.B. Anzeige = 4 Stellen × 8 Segmente = 32 Bit,
  weil jede Stelle auch einen Dezimalpunkt hat).
- Das letzte Port in der Liste bekommt **kein** Semikolon.

---

## Phase 3 — Blockschaltbild / Dekomposition

Das System in Module zerlegen. Nicht raten — mit Tests herleiten, ob etwas
ein eigener Block ist:

- **Rhythmus-Test:** Braucht es einen Takt? Dann eigener getakteter Block.
- **Und-Test:** Macht der Block zwei unabhängige Dinge? Dann trennen.
- **Erzeuger-Test:** Verfolge jedes Ausgangssignal zu seinem Treiber zurück.
  Jeder Ausgang braucht genau einen Erzeuger.
- **Allein-Test:** Kannst du den Block isoliert testen? Wenn nein, ist er
  falsch geschnitten.

Ergebnis: Liste der Module plus die **internen Signale** — das sind die
Drähte zwischen den Modulen, die du später im Top deklarierst.

Trennung Simulation vs. Hardware schon hier mitdenken: Submodule
**active-high** halten (1 = an), Polaritäts-Invertierung zentral ins Top.
So bleiben die Module wiederverwendbar und die Testbenches sauber.

---

## Phase 4 — Module einzeln bauen und simulieren

Pro Modul immer dieselbe Reihenfolge: **Entity → Innenleben → Testbench.**
Nicht mischen. Jedes Modul einzeln verifizieren, bevor du integrierst.

Zwei wiederkehrende Techniken:

**Generic für die Simulation.** Hardware-Werte (z.B. Teiler = 5 000 000)
machen die Simulation unbrauchbar langsam. Lösung: Generic mit Default =
Hardware-Wert, in der Testbench mit kleinem Wert (z.B. 5) überschreiben.
```vhdl
generic ( teiler_wert : natural := 5000000 );
```
```vhdl
generic map ( teiler_wert => 5 )   -- in der Testbench
```

**Testbench schlank, aber den kritischen Fall zeigen.** Gerade genug, um es
zu beweisen — nicht mehr. Beispiel: Bei einem BCD-Zähler ist der entscheidende
Test der Übergang 0009 → 0010 (beweist die Umrechnung). Einstellige Zahlen
beweisen nichts, weil BCD und Hex da gleich aussehen.

Kombinatorische Ausgänge (z.B. ein Decoder) brauchen **keinen Takt** — kein
`rising_edge`, kein getakteter Prozess. Aber Achtung: in jedem Pfad **alle**
Ausgangsbits zuweisen, sonst baut die Synthese ein ungewolltes Latch.

---

## Phase 5 — Integration

Die Module im Top per `port map` zusammenstecken — das ist strukturelles
VHDL, dasselbe Konstrukt wie der DUT in jeder Testbench.

Schritte:
1. Interne Signale deklarieren (die Drähte aus Phase 3).
2. Jedes Modul instanziieren, Ports an interne Signale und Top-Ports verdrahten.
3. Generic durchreichen: `generic map (teiler_wert => teiler_wert)`.
4. Ungenutzte Ausgänge sauber abbinden: `led <= (others => '0');`

Dann eine **Gesamt-Testbench** mit Generic-Override (kleiner Teilerwert).
Prüfen, dass die ganze Kette zusammenspielt — inklusive der kritischen
Übergänge im Gesamtsystem.

Häufiger Fehler hier: `architecture rtl of MODUL` zeigt auf die falsche Entity
(aus einer kopierten Datei). Muss zur eigenen Entity passen.

---

## Phase 6 — Synthese in Quartus (Zielrechner)

**Dateien übertragen:** Gmail blockt `.vhd` und `.tcl` als Sicherheitsrisiko.
Workaround: in `.txt` umbenennen, senden, beim Empfänger zurückbenennen.
Alternative: über Cloud-Speicher (Drive blockt nicht).

**Projekt anlegen — der wichtigste Punkt:**
- Projekt auf einer **lokalen Platte**, kurzer Pfad, **keine Leerzeichen**,
  z.B. `C:\fpga\projektname`.
- **Nicht** auf Desktop oder Dokumente — die sind an Uni-Rechnern meist auf
  ein Netzlaufwerk umgeleitet. Quartus macht tausende Dateizugriffe und
  erstickt dann an der Netzwerk-Latenz (Compile hängt scheinbar).
- New Project Wizard: Top-Level-Entity exakt benennen, alle `.vhd` einbinden.
- **Device exakt setzen:** DE0 = Cyclone III, `EP3C16F484C6`.

**Polaritäten an die Hardware anpassen** (zentral im Top, nicht in Submodulen):
- **Taster der DE0 sind active-low** (gedrückt = 0). In der Sim war gedrückt = 1.
  → im Top invertieren: `button_n <= not button;`
- **7-Segment der DE0 ist active-low** (Segment an = 0). Dein Decoder gibt 1
  für „an". → kompletten Vektor invertieren: `seg <= not seg_int;`
- LEDs sind active-high — nicht invertieren.

**Pin-Zuordnung per Tcl-Skript** (statt 46 Pins von Hand im Pin Planner):
Skript mit `set_location_assignment PIN_xxx -to signal` für jedes Signal,
dann in der Quartus Tcl Console:
```
source pins.tcl
```
Pins aus dem DE0 User Manual (Tabellen 4.2 Taster, 4.3 LEDs, 4.4 7-Segment,
4.5 Takt).

**Erst Analysis & Synthesis** (prüft Synthetisierbarkeit), dann der **volle
Compile** (Compile Design) → erzeugt `stoppuhr.sof` im `output_files`-Ordner.

Generic-Reminder: In Quartus läuft das Top mit dem **Default-Generic**
(Hardware-Wert). Nicht anfassen — der kleine Wert war nur für die Sim.

---

## Phase 7 — Aufs Board und Test

**Hardware vorbereiten:**
- USB-Kabel an den USB-Blaster-Port.
- Strom an, Power-Schalter ON.
- RUN/PROG-Schalter auf **RUN** (JTAG-Modus; PROG ist nur für AS-Programmierung).

**Programmieren:** Tools → Programmer → Hardware Setup = USB-Blaster,
Mode = JTAG → `.sof` laden → Program/Configure ankreuzen → Start → 100 %.
(JTAG ist flüchtig: Konfiguration ist nach dem Ausschalten weg. Für dauerhaft
gäbe es AS-Programmierung in den EPCS-Baustein per `.pof`.)

**Funktionstest** gegen die Spezifikation aus Phase 1.

**Genauigkeitstest:** System gegen eine echte Uhr laufen lassen (~60 s).
Wenn der Teiler exakt gerechnet ist, läuft es exakt mit.

---

## Stolperfallen-Schnellreferenz

| Symptom | Ursache | Fix |
|---------|---------|-----|
| Gmail blockt Anhang | `.vhd` / `.tcl` als riskant eingestuft | in `.txt` umbenennen oder Cloud |
| Compile hängt bei x % | Projekt auf Netzlaufwerk (Desktop) | lokaler Pfad `C:\fpga\…` |
| Quartus zickt beim Pfad | Leerzeichen im Pfad | Pfad ohne Leerzeichen |
| Sim läuft ewig | Generic nicht überschrieben | in Testbench kleinen Wert mappen |
| Anzeige zeigt „Negativ" | active-low nicht invertiert | `seg <= not seg_int` im Top |
| Taster reagiert beim Loslassen | active-low nicht invertiert | `button_n <= not button` im Top |
| „multiple constant drivers" | ein Signal von zwei Quellen getrieben | Port map zeigt auf falsches Signal |
| ungewolltes Latch | nicht alle Ausgänge in jedem Pfad zugewiesen | jeden Ausgang überall setzen |
| Taster togglet doppelt | Tastenprellen (Board nicht entprellt) | Entprell-Logik in die Steuerung |

---

## VHDL-Syntax-Checkliste

Die Fehler, die unter Zeitdruck am häufigsten durchrutschen:

- `<=` ist **Zuweisung**, `=` ist **Vergleich** — nicht verwechseln.
- Letztes Port in der Portliste: **kein** Semikolon. Davor: Semikolon.
- Schlüsselwort ist `elsif` — nicht `else if`, nicht `elseif`.
- `'0'` = einzelnes Bit (std_logic), `"0"` = Vektor, `0` = Integer.
- Kein `++` oder `+=`. Hochzählen: `x <= x + 1;`.
- `architecture rtl of ENTITY` — der Entity-Name muss zur Datei passen
  (häufiger Copy-Paste-Fehler).
- Portrichtung `out` für Ausgänge explizit angeben (Default ist `in`).
- Kombinatorische Zuweisungen gehören **außerhalb** des getakteten Prozesses.
- Bibliothek heißt `work`, nicht `worker`.
- `to_unsigned`, `unsigned` brauchen `use ieee.numeric_std.all;`.
  `std_logic_vector` kommt aus `ieee.std_logic_1164.all;`.
- `to_unsigned(wert, bits)`, `&` ist Verkettung, `mod 10` ist die letzte
  Ziffer, `/10` schiebt eine Stelle weg.
- Einen `out`-Port kann man nicht sauber zurücklesen. Wenn ein Ausgang von
  seinem eigenen Wert abhängt (z.B. Toggle), internes Signal nutzen und am
  Ende nach außen geben.

---

## Befehls- und Werkzeugreferenz

**NVC (Simulation, Mac):**
```
nvc --std=2008 -a src/A.vhd src/B.vhd tb/TOP_tb.vhd   # analyze
nvc --std=2008 -e TOP_tb                               # elaborate
nvc -r TOP_tb --wave=TOP.vcd                           # run + Wellenform
surfer TOP.vcd                                         # anschauen
```
Reihenfolge beim Analysieren: Blätter zuerst, dann das Top, dann die Testbench.

**Quartus (Synthese, Zielrechner):**
- File → New Project Wizard (Top-Level, Dateien, Device)
- Tasks: Analysis & Synthesis (Check) → Compile Design (voll, erzeugt `.sof`)
- View → Utility Windows → Tcl Console (für `source pins.tcl`)
- Tools → Programmer (Board flashen)

**Tcl (Pin-Zuordnung):**
```
set_location_assignment PIN_G21 -to clk
set_location_assignment PIN_E11 -to seg[0]
```

---

## Anhang A — Phase-0-Beispielcode

Ein einzelnes Register, das seinen Eingang bei jeder Taktflanke an den Ausgang
durchreicht. Es hat keinen Zweck ausser einem: beweisen, dass die Kette
analysieren → elaborieren → simulieren → Wellenform durchläuft.

### A.1 Vollständig (Referenz)

```vhdl
-- src/reg1.vhd
library ieee;
use ieee.std_logic_1164.all;

entity reg1 is
  port (
    clk : in  std_logic;   -- Takt
    d   : in  std_logic;   -- Eingang
    q   : out std_logic    -- Ausgang
  );
end entity;

architecture rtl of reg1 is
begin
  process(clk)
  begin
    if rising_edge(clk) then
      q <= d;              -- bei steigender Taktflanke: d -> q
    end if;
  end process;
end architecture;
```

```vhdl
-- tb/reg1_tb.vhd
library ieee;
use ieee.std_logic_1164.all;
use std.env.all;           -- stellt finish bereit

entity reg1_tb is
end entity;                -- Testbench hat keine Ports

architecture sim of reg1_tb is
  signal clk : std_logic := '0';
  signal d   : std_logic := '0';
  signal q   : std_logic;
begin

  dut : entity work.reg1
    port map (
      clk => clk,
      d   => d,
      q   => q
    );

  clk <= not clk after 10 ns;   -- Takt: Periode 20 ns

  stim : process
  begin
    d <= '0';  wait for 25 ns;
    d <= '1';  wait for 30 ns;
    d <= '0';  wait for 30 ns;
    d <= '1';  wait for 30 ns;
    finish;                     -- ohne finish tickt der Takt endlos
  end process;

end architecture;
```

Bestanden, wenn `q` den Wert von `d` jeweils erst bei der nächsten steigenden
Taktflanke übernimmt — `q` folgt `d` also um einen Takt verzögert.

### A.2 Lückentext (Selbsttest)

Die markierten Stellen `[1]`..`[14]` sind die **Lückenwörter**: die tragenden
Syntax-Tokens, die am leichtesten vergessen oder vertippt werden — genau die,
die in der Praxis Fehler verursachen. Lösung (A.3) abdecken und aus dem
Gedächtnis ausfüllen. Gleiche Nummer = gleiches Wort.

```vhdl
-- src/reg1.vhd  — Lückentext
library ieee;
use ieee.std_logic_1164.all;

[1] reg1 is
  [2] (
    clk : [3]  std_logic;
    d   : [3]  std_logic;
    q   : [4]  [5]
  );
end [1];

architecture rtl [6] reg1 is
begin
  [7](clk)
  begin
    if [8](clk) then
      q [9] d;
    end if;
  end [7];
end architecture;
```

```vhdl
-- tb/reg1_tb.vhd  — Lückentext
library ieee;
use ieee.std_logic_1164.all;
use std.env.all;

entity reg1_tb is
end entity;

architecture sim of reg1_tb is
  signal clk : std_logic := '0';
  signal d   : std_logic := '0';
  signal q   : std_logic;
begin

  dut : [10] work.reg1
    [11] (
      clk => clk,
      d   => d,
      q   => q
    );

  clk <= not clk [12] 10 ns;

  stim : process
  begin
    d <= '0';  [13] 25 ns;
    d <= '1';  [13] 30 ns;
    d <= '0';  [13] 30 ns;
    d <= '1';  [13] 30 ns;
    [14];
  end process;

end architecture;
```

### A.3 Lösungsschlüssel

| Nr. | Wort | Wofür |
|-----|------|-------|
| [1] | `entity` | leitet die Schnittstelle ein (und schließt sie: `end entity`) |
| [2] | `port` | beginnt die Portliste |
| [3] | `in` | Eingangsrichtung |
| [4] | `out` | Ausgangsrichtung (Falle: Default ist `in`) |
| [5] | `std_logic` | Bit-Typ (Falle: Tippfehler `std_locic`) |
| [6] | `of` | bindet Architecture an ihre Entity |
| [7] | `process` | getakteter Prozess (und `end process`) |
| [8] | `rising_edge` | reagiert auf die steigende Taktflanke |
| [9] | `<=` | Signalzuweisung (nicht `=`, das ist Vergleich) |
| [10] | `entity` | Modul instanziieren: `entity work.NAME` |
| [11] | `port map` | verdrahtet die Ports des Moduls |
| [12] | `after` | zeitversetzte Zuweisung (Takterzeugung) |
| [13] | `wait for` | simulierte Zeit weiterlaufen lassen |
| [14] | `finish` | Simulation beenden (Falle: ohne läuft sie ewig) |

### A.4 Was die Konstrukte bedeuten

- `entity` = die Schnittstelle (die Ports nach außen).
- `architecture` = das Innenleben, was das Modul tut.
- `process(clk)` + `if rising_edge(clk)` = „tu das bei jeder steigenden
  Taktflanke". So baut man getaktete Logik.
- `<=` = einem Signal einen Wert zuweisen.
- Testbench = Baustein **ohne Ports**, steht ganz oben, erzeugt selbst Takt
  und Reize.
- `entity work.NAME ... port map (...)` = ein fertiges Modul einbauen.
- `finish` = Simulation sauber beenden.
