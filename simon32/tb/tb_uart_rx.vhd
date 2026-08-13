library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_uart_rx is
end entity tb_uart_rx;

architecture sim of tb_uart_rx is

    -- Kleiner Wert fuer schnelle Simulation (statt 868)
    constant CLKS_PER_BIT : natural := 10;
    constant CLK_PERIOD   : time := 10 ns;
    constant BIT_PERIOD   : time := CLKS_PER_BIT * CLK_PERIOD;

    signal clk      : std_logic := '0';
    signal rst      : std_logic := '1';
    signal rx       : std_logic := '1';  -- Ruhezustand: high!
    signal data_out : std_logic_vector(7 downto 0);
    signal valid    : std_logic;

    -- Hilfsprozedur: schickt ein Byte seriell ueber die Leitung
    procedure uart_send(
        constant byte : in  std_logic_vector(7 downto 0);
        signal   line : out std_logic
        ) is
    begin
        line <= '0';                     -- Startbit
        wait for BIT_PERIOD;
        for i in 0 to 7 loop             -- 8 Datenbits, LSB zuerst
            line <= byte(i);
            wait for BIT_PERIOD;
        end loop;
        line <= '1';                     -- Stopbit anlegen
        -- kein wait mehr! Sofort zurueck, damit der Aufrufer
        -- den valid-Puls nicht verpasst
    end procedure;

begin

    dut : entity work.uart_rx
        generic map ( CLKS_PER_BIT => CLKS_PER_BIT )
        port map (
            clk      => clk,
            rst      => rst,
            rx       => rx,
            data_out => data_out,
            valid    => valid
        );

    clk <= not clk after CLK_PERIOD / 2;

    stimulus : process
    begin
        wait for 3 * CLK_PERIOD;
        rst <= '0';
        wait for 3 * CLK_PERIOD;

        -- Erstes Testbyte senden
        uart_send(x"A5", rx);

        wait until valid = '1';
        assert data_out = x"A5"
            report "FEHLER! Empfangen: " & to_hstring(data_out) &
            ", erwartet: A5"
            severity failure;
        report "Byte 1 korrekt empfangen: " & to_hstring(data_out);

        -- Zweites Byte hinterher, prueft ob IDLE-Rueckkehr klappt
        wait for 5 * CLK_PERIOD;
        uart_send(x"3C", rx);

        wait until valid = '1';
        assert data_out = x"3C"
            report "FEHLER! Empfangen: " & to_hstring(data_out) &
            ", erwartet: 3C"
            severity failure;
        report "Byte 2 korrekt empfangen: " & to_hstring(data_out);

        report "UART-RX Testbench fertig - alles korrekt.";
        std.env.stop;
    end process;

end architecture sim;