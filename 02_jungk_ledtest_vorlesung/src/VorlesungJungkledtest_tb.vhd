library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity ledtest_tb is
end ledtest_tb;

architecture behavioral of ledtest_tb is
    component ledtest is
            port ( clk : in std_logic;
               led : out std_logic_vector (15 downto 0);
               btn : in std_logic_vector (4 downto 0);
               sw : in std_logic_vector (15 downto 0);
               led : out std_logic_vector(15 downto 0)

    end compontent;


    signal clk_tb : std_logic;
    signal led_tb : std_logic_vector(15 to 0);
    singal btn_tb : std_logic_vector(4 to 0);
    singal sw_tb : std_logic_vector(15 to 0);

    constant clk_period : time := 10 ns

    begin
        ledtest_instance : ledtest
        port map ( clk => clk_tb,
                   led => led_tb,
                   btn => btn_tb,
                   sw  => sw_tb,
        );




        clk_process : process
        begin
            clk_tb <= '0';
            wait for CLK_PERIOD / 2;
            clk_tb <= '1';
            wait for CLK_PERIOD / 2;
        end process;


        btn_process: process
        begin

        wait for CLK_PERIOD * 2;

        btn_tb(0) <= '1';
        wait for clk_period;

        btn_tb(0) <= '0';
        wait for clk_period;

    end process;

end architecture behavioral;
