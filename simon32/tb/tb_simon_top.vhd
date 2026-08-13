library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_simon_top is
end entity tb_simon_top;

architecture sim of tb_simon_top is

    constant CLKS_PER_BIT : natural := 10;
    constant CLK_PERIOD   : time := 10 ns;
    constant BIT_PERIOD   : time := CLKS_PER_BIT * CLK_PERIOD;

    signal clk       : std_logic := '0';
    signal rst       : std_logic := '1';
    signal pc_to_fpga: std_logic := '1';   -- Leitung PC -> FPGA
    signal fpga_to_pc: std_logic;          -- Leitung FPGA -> PC
    signal mon_data  : std_logic_vector(7 downto 0);
    signal mon_valid : std_logic;

    -- Testvektor: 8 Byte Schluessel + 4 Byte Klartext
    type byte_array is array (natural range <>) of std_logic_vector(7 downto 0);
    constant TX_BYTES : byte_array(0 to 11) := (
        x"19", x"18", x"11", x"10", x"09", x"08", x"01", x"00",  -- Schluessel
        x"65", x"65", x"68", x"77"                               -- Klartext
    );
    constant EXPECTED : byte_array(0 to 3) := (
        x"C6", x"9B", x"E9", x"BB"                               -- Ciphertext
    );

    -- Diesmal MIT Stopbit-Wartezeit (Bytes kommen direkt hintereinander)
    procedure uart_send(
        constant byte : in  std_logic_vector(7 downto 0);
        signal   line : out std_logic
        ) is
    begin
        line <= '0';                     -- Startbit
        wait for BIT_PERIOD;
        for i in 0 to 7 loop
            line <= byte(i);
            wait for BIT_PERIOD;
        end loop;
        line <= '1';                     -- Stopbit
        wait for BIT_PERIOD;
    end procedure;

begin

    dut : entity work.simon_top
        generic map ( CLKS_PER_BIT => CLKS_PER_BIT )
        port map (
            clk => clk, rst => rst,
            uart_rx => pc_to_fpga,
            uart_tx => fpga_to_pc,
            led_busy => open, led_done => open
        );

    -- Monitor: verifizierter Empfaenger lauscht auf die Antwort
    monitor : entity work.uart_rx
        generic map ( CLKS_PER_BIT => CLKS_PER_BIT )
        port map (
            clk => clk, rst => rst,
            rx => fpga_to_pc,
            data_out => mon_data, valid => mon_valid
        );

    clk <= not clk after CLK_PERIOD / 2;

    stimulus : process
    begin
        wait for 3 * CLK_PERIOD;
        rst <= '0';
        wait for 3 * CLK_PERIOD;

        -- 12 Bytes senden (Schluessel + Klartext)
        for i in TX_BYTES'range loop
            uart_send(TX_BYTES(i), pc_to_fpga);
        end loop;
        report "12 Bytes gesendet, warte auf Antwort...";

        -- 4 Antwort-Bytes einsammeln und pruefen
        for i in EXPECTED'range loop
            wait until mon_valid = '1';
            assert mon_data = EXPECTED(i)
                report "FEHLER bei Byte " & integer'image(i) &
                ": empfangen " & to_hstring(mon_data) &
                ", erwartet " & to_hstring(EXPECTED(i))
                severity failure;
            report "Antwort-Byte " & integer'image(i) & " OK: " &
                to_hstring(mon_data);
        end loop;

        report "SYSTEMTEST BESTANDEN: C69BE9BB komplett ueber UART verifiziert!";
        std.env.stop;
    end process;

end architecture sim;