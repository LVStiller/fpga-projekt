library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_uart_loopback is
end entity tb_uart_loopback;

architecture sim of tb_uart_loopback is

    constant CLKS_PER_BIT : natural := 10;
    constant CLK_PERIOD   : time := 10 ns;

    signal clk     : std_logic := '0';
    signal rst     : std_logic := '1';
    signal line_s  : std_logic;          -- die Leitung TX -> RX
    signal send    : std_logic := '0';
    signal tx_data : std_logic_vector(7 downto 0) := (others => '0');
    signal tx_busy : std_logic;
    signal rx_data : std_logic_vector(7 downto 0);
    signal rx_valid: std_logic;

begin

    sender : entity work.uart_tx
        generic map ( CLKS_PER_BIT => CLKS_PER_BIT )
        port map (
            clk => clk, rst => rst,
            send => send, data_in => tx_data,
            tx => line_s, busy => tx_busy
        );

    receiver : entity work.uart_rx
        generic map ( CLKS_PER_BIT => CLKS_PER_BIT )
        port map (
            clk => clk, rst => rst,
            rx => line_s,                -- Loopback!
            data_out => rx_data, valid => rx_valid
        );

    clk <= not clk after CLK_PERIOD / 2;

    stimulus : process
    begin
        wait for 3 * CLK_PERIOD;
        rst <= '0';
        wait for 3 * CLK_PERIOD;

        -- Byte 1 senden
        tx_data <= x"C6";
        send    <= '1';
        wait for CLK_PERIOD;
        send    <= '0';

        wait until rx_valid = '1';
        assert rx_data = x"C6"
            report "FEHLER! Loopback: " & to_hstring(rx_data) severity failure;
        report "Loopback Byte 1 OK: " & to_hstring(rx_data);

        -- Warten bis Sender frei, dann Byte 2
        wait until tx_busy = '0';
        wait for 2 * CLK_PERIOD;
        tx_data <= x"9B";
        send    <= '1';
        wait for CLK_PERIOD;
        send    <= '0';

        wait until rx_valid = '1';
        assert rx_data = x"9B"
            report "FEHLER! Loopback: " & to_hstring(rx_data) severity failure;
        report "Loopback Byte 2 OK: " & to_hstring(rx_data);

        report "Loopback-Test fertig - Sender und Empfaenger kompatibel.";
        std.env.stop;
    end process;

end architecture sim;