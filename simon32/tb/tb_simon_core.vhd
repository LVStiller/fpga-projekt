library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_simon_core is
end entity tb_simon_core;

architecture sim of tb_simon_core is

    -- Signale zum Verbinden mit dem Core
    signal clk        : std_logic := '0';
    signal rst        : std_logic := '1';
    signal start      : std_logic := '0';
    signal plaintext  : std_logic_vector(31 downto 0) := (others => '0');
    signal key        : std_logic_vector(63 downto 0) := (others => '0');
    signal ciphertext : std_logic_vector(31 downto 0);
    signal busy       : std_logic;
    signal done       : std_logic;

    constant CLK_PERIOD : time := 10 ns;  -- 100 MHz

begin

    -- Den Core einbauen (Device Under Test)
    dut : entity work.simon_core
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

    -- Taktgenerator: kippt alle 5 ns
    clk <= not clk after CLK_PERIOD / 2;

    -- Testablauf
    stimulus : process
    begin
        -- Reset fuer 2 Takte halten
        wait for 2 * CLK_PERIOD;
        rst <= '0';
        wait for CLK_PERIOD;

        -- Testvektor anlegen und starten
        plaintext <= x"65656877";
        key       <= x"1918111009080100";
        start     <= '1';
        wait for CLK_PERIOD;
        start     <= '0';

        -- Warten bis done kommt
        wait until done = '1';
        wait until done = '1';
        assert ciphertext = x"C69BE9BB"
            report "FEHLER! Ciphertext ist " & to_hstring(ciphertext) &
            ", erwartet: C69BE9BB"
            severity failure;
        report "Testvektor korrekt: " & to_hstring(ciphertext);

        wait for 5 * CLK_PERIOD;
        report "Testbench fertig." severity note;
        std.env.stop;
    end process;

end architecture sim;