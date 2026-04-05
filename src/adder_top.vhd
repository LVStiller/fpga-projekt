-- ============================================================
-- Aufgabe 1.4 - Variante 1: 8-Bit Addierer mit 7-Segment-Anzeige
-- Hochschule Albstadt-Sigmaringen
-- Security Hardware Design - Prof. Dr. Bernhard Jungk
-- ============================================================
-- Switches 0-7:  Zahl A (8 Bit, 0-255)
-- Switches 8-15: Zahl B (8 Bit, 0-255)
-- 7-Segment:     Ergebnis als Dezimalzahl (0-510)
-- LEDs 0-8:      Ergebnis als Binärzahl (9 Bit inkl. Carry)
-- ============================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity adder_top is
    port (
        clk     : in  std_logic;                      -- 100 MHz Board Clock
        sw      : in  std_logic_vector(15 downto 0);  -- 16 Switches
        seg     : out std_logic_vector(6 downto 0);   -- 7-Segment (a-g)
        an      : out std_logic_vector(3 downto 0);   -- 7-Segment Anoden (4 Digits)
        led     : out std_logic_vector(15 downto 0)   -- 16 LEDs
    );
end entity adder_top;

architecture behavioral of adder_top is

    -- Eingangssignale
    signal a        : unsigned(7 downto 0);
    signal b        : unsigned(7 downto 0);
    
    -- Ergebnis: 9 Bit (8 Bit + Carry)
    signal sum_result : unsigned(8 downto 0);
    
    -- BCD-Ziffern fuer die 7-Segment-Anzeige
    signal bcd_ones     : unsigned(3 downto 0);  -- Einer
    signal bcd_tens     : unsigned(3 downto 0);  -- Zehner
    signal bcd_hundreds : unsigned(3 downto 0);  -- Hunderter
    
    -- Multiplexing der 7-Segment-Anzeige
    signal refresh_counter : unsigned(19 downto 0) := (others => '0');
    signal digit_select    : unsigned(1 downto 0);
    signal current_digit   : unsigned(3 downto 0);
    
    -- 7-Segment Dekodierung
    signal seg_pattern : std_logic_vector(6 downto 0);

begin

    -- ========================================
    -- Eingabe: Switches aufteilen
    -- ========================================
    a <= unsigned(sw(7 downto 0));    -- Untere 8 Switches = Zahl A
    b <= unsigned(sw(15 downto 8));   -- Obere 8 Switches = Zahl B

    -- ========================================
    -- Addition: 8 Bit + 8 Bit = 9 Bit
    -- ========================================
    sum_result <= ('0' & a) + ('0' & b);

    -- ========================================
    -- LEDs: Ergebnis binaer anzeigen
    -- ========================================
    led(8 downto 0)  <= std_logic_vector(sum_result);
    led(15 downto 9) <= (others => '0');  -- Restliche LEDs aus

    -- ========================================
    -- Binaer zu BCD Umwandlung (Double Dabble)
    -- ========================================
    process(sum_result)
        variable temp : unsigned(8 downto 0);
        variable bcd  : unsigned(11 downto 0);
    begin
        bcd  := (others => '0');
        temp := sum_result;
        
        -- Double Dabble Algorithmus
        for i in 0 to 8 loop
            -- Pruefen ob BCD-Ziffern >= 5, dann +3
            if bcd(3 downto 0) >= 5 then
                bcd(3 downto 0) := bcd(3 downto 0) + 3;
            end if;
            if bcd(7 downto 4) >= 5 then
                bcd(7 downto 4) := bcd(7 downto 4) + 3;
            end if;
            if bcd(11 downto 8) >= 5 then
                bcd(11 downto 8) := bcd(11 downto 8) + 3;
            end if;
            
            -- Links schieben
            bcd := bcd(10 downto 0) & temp(8);
            temp := temp(7 downto 0) & '0';
        end loop;
        
        bcd_ones     <= bcd(3 downto 0);
        bcd_tens     <= bcd(7 downto 4);
        bcd_hundreds <= bcd(11 downto 8);
    end process;

    -- ========================================
    -- 7-Segment Multiplexing (Refresh Counter)
    -- ========================================
    -- Bei 100 MHz: 2^20 = ~1 Million -> ~100 Hz Refresh pro Digit
    process(clk)
    begin
        if rising_edge(clk) then
            refresh_counter <= refresh_counter + 1;
        end if;
    end process;
    
    digit_select <= refresh_counter(19 downto 18);

    -- ========================================
    -- Digit Auswahl: Welches Digit ist aktiv?
    -- ========================================
    process(digit_select, bcd_ones, bcd_tens, bcd_hundreds)
    begin
        case digit_select is
            when "00" =>
                an <= "1110";  -- Digit 0 aktiv (Einer)
                current_digit <= bcd_ones;
            when "01" =>
                an <= "1101";  -- Digit 1 aktiv (Zehner)
                current_digit <= bcd_tens;
            when "10" =>
                an <= "1011";  -- Digit 2 aktiv (Hunderter)
                current_digit <= bcd_hundreds;
            when others =>
                an <= "0111";  -- Digit 3 aus (nicht benoetigt)
                current_digit <= "0000";
        end case;
    end process;

    -- ========================================
    -- 7-Segment Dekoder (Active Low!)
    -- ========================================
    --    Segment-Zuordnung:
    --       a
    --      ---
    --   f |   | b
    --      -g-
    --   e |   | c
    --      ---
    --       d
    --
    --    seg = "abcdefg"
    process(current_digit)
    begin
        case current_digit is
            when "0000" => seg <= "0000001"; -- 0
            when "0001" => seg <= "1001111"; -- 1
            when "0010" => seg <= "0010010"; -- 2
            when "0011" => seg <= "0000110"; -- 3
            when "0100" => seg <= "1001100"; -- 4
            when "0101" => seg <= "0100100"; -- 5
            when "0110" => seg <= "0100000"; -- 6
            when "0111" => seg <= "0001111"; -- 7
            when "1000" => seg <= "0000000"; -- 8
            when "1001" => seg <= "0000100"; -- 9
            when others => seg <= "1111111"; -- Aus
        end case;
    end process;

end architecture behavioral;
