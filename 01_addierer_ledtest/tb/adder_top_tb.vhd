-- ============================================================
-- Testbench fuer Aufgabe 1.4 - 8-Bit Addierer
-- ============================================================
-- Testet verschiedene Eingabekombinationen und prueft das
-- Ergebnis auf den LEDs (binaer) und der 7-Segment-Anzeige.
-- ============================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity adder_top_tb is
    -- Testbench hat keine Ports
end entity adder_top_tb;

architecture sim of adder_top_tb is

    -- Komponente deklarieren
    component adder_top is
        port (
            clk : in  std_logic;
            sw  : in  std_logic_vector(15 downto 0);
            seg : out std_logic_vector(6 downto 0);
            an  : out std_logic_vector(3 downto 0);
            led : out std_logic_vector(15 downto 0)
        );
    end component;

    -- Testsignale
    signal clk_tb  : std_logic := '0';
    signal sw_tb   : std_logic_vector(15 downto 0) := (others => '0');
    signal seg_tb  : std_logic_vector(6 downto 0);
    signal an_tb   : std_logic_vector(3 downto 0);
    signal led_tb  : std_logic_vector(15 downto 0);

    -- Clock Periode: 10 ns = 100 MHz
    constant CLK_PERIOD : time := 10 ns;

    -- Hilfsfunktion: Erwartetes Ergebnis pruefen
    procedure check_result(
        signal   led_out : in std_logic_vector(15 downto 0);
        constant a       : in integer;
        constant b       : in integer
    ) is
        variable expected : unsigned(8 downto 0);
        variable actual   : unsigned(8 downto 0);
    begin
        expected := to_unsigned(a + b, 9);
        actual   := unsigned(led_out(8 downto 0));
        
        assert actual = expected
            report "FEHLER: " & integer'image(a) & " + " & integer'image(b) &
                   " = " & integer'image(to_integer(actual)) &
                   " (erwartet: " & integer'image(to_integer(expected)) & ")"
            severity error;
            
        report integer'image(a) & " + " & integer'image(b) &
               " = " & integer'image(to_integer(actual)) & " -> OK"
            severity note;
    end procedure;

begin

    -- ========================================
    -- Device Under Test (DUT) instanziieren
    -- ========================================
    dut : adder_top
        port map (
            clk => clk_tb,
            sw  => sw_tb,
            seg => seg_tb,
            an  => an_tb,
            led => led_tb
        );

    -- ========================================
    -- Clock Generierung
    -- ========================================
    clk_process : process
    begin
        clk_tb <= '0';
        wait for CLK_PERIOD / 2;
        clk_tb <= '1';
        wait for CLK_PERIOD / 2;
    end process;

    -- ========================================
    -- Teststimuli
    -- ========================================
    test_process : process
    begin
        report "=== Testbench Start ===" severity note;
        wait for CLK_PERIOD * 2;

        -- ---- Test 1: 0 + 0 = 0 ----
        sw_tb(7 downto 0)  <= std_logic_vector(to_unsigned(0, 8));   -- A = 0
        sw_tb(15 downto 8) <= std_logic_vector(to_unsigned(0, 8));   -- B = 0
        wait for CLK_PERIOD * 2;
        check_result(led_tb, 0, 0);

        -- ---- Test 2: 5 + 3 = 8 ----
        sw_tb(7 downto 0)  <= std_logic_vector(to_unsigned(5, 8));
        sw_tb(15 downto 8) <= std_logic_vector(to_unsigned(3, 8));
        wait for CLK_PERIOD * 2;
        check_result(led_tb, 5, 3);

        -- ---- Test 3: 100 + 55 = 155 ----
        sw_tb(7 downto 0)  <= std_logic_vector(to_unsigned(100, 8));
        sw_tb(15 downto 8) <= std_logic_vector(to_unsigned(55, 8));
        wait for CLK_PERIOD * 2;
        check_result(led_tb, 100, 55);

        -- ---- Test 4: 255 + 1 = 256 (Ueberlauf, 9. Bit) ----
        sw_tb(7 downto 0)  <= std_logic_vector(to_unsigned(255, 8));
        sw_tb(15 downto 8) <= std_logic_vector(to_unsigned(1, 8));
        wait for CLK_PERIOD * 2;
        check_result(led_tb, 255, 1);

        -- ---- Test 5: 255 + 255 = 510 (Maximum) ----
        sw_tb(7 downto 0)  <= std_logic_vector(to_unsigned(255, 8));
        sw_tb(15 downto 8) <= std_logic_vector(to_unsigned(255, 8));
        wait for CLK_PERIOD * 2;
        check_result(led_tb, 255, 255);

        -- ---- Test 6: 42 + 0 = 42 ----
        sw_tb(7 downto 0)  <= std_logic_vector(to_unsigned(42, 8));
        sw_tb(15 downto 8) <= std_logic_vector(to_unsigned(0, 8));
        wait for CLK_PERIOD * 2;
        check_result(led_tb, 42, 0);

        -- ---- Test 7: 128 + 128 = 256 ----
        sw_tb(7 downto 0)  <= std_logic_vector(to_unsigned(128, 8));
        sw_tb(15 downto 8) <= std_logic_vector(to_unsigned(128, 8));
        wait for CLK_PERIOD * 2;
        check_result(led_tb, 128, 128);

        report "=== Testbench Ende - Alle Tests abgeschlossen ===" severity note;
        wait;
    end process;

end architecture sim;
