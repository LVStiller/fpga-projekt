library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_simon_core_x2 is
end entity tb_simon_core_x2;

architecture sim of tb_simon_core_x2 is

    signal clk        : std_logic := '0';
    signal rst        : std_logic := '1';
    signal start      : std_logic := '0';
    signal plaintext  : std_logic_vector(31 downto 0) := (others => '0');
    signal key        : std_logic_vector(63 downto 0) := (others => '0');
    signal ciphertext : std_logic_vector(31 downto 0);
    signal busy       : std_logic;
    signal done       : std_logic;

    constant CLK_PERIOD : time := 10 ns;

begin

    dut : entity work.simon_core_x2
        port map (
            clk        => clk,
            rst        => rst,
            start      => start,
            plaintext  => plaintext,
            key        => key,
            ciphertext => ciphertext,
            busy       => busy,
            done       => done
        );

    clk <= not clk after CLK_PERIOD / 2;

    stimulus : process
    begin
        wait for 2 * CLK_PERIOD;
        rst <= '0';
        wait for CLK_PERIOD;

        plaintext <= x"65656877";
        key       <= x"1918111009080100";
        start     <= '1';
        wait for CLK_PERIOD;
        start     <= '0';

        wait until done = '1';
        assert ciphertext = x"C69BE9BB"
            report "FEHLER! Ciphertext ist " & to_hstring(ciphertext) &
            ", erwartet: C69BE9BB"
            severity failure;
        report "x2-Variante korrekt: " & to_hstring(ciphertext) &
            " (16 Takte statt 32)";

        wait for 5 * CLK_PERIOD;
        std.env.stop;
    end process;

end architecture sim;