library ieee;
use IEEE.STD_LOGIC_1164.ALL;



entity ledtest is
    port ( clk : in std_logic;
           led : out std_logic_vector (15 downto 0);
           btn : in std_logic_vector (4 downto 0);
           sw : in std_logic_vector (15 downto 0);
           led : out std_logic_vector(15 downto 0)
    );
end ledtest;

architecture behavioral of ledtest is

    signal sampling : std_logic_vector(15 to 0);
    singal sampling_reg : std_logic_vector(15 to 0);

    singal btn_state : std_logic;
    singal btn_state_reg : std_logic := '0'; --Standard Wert von 0 angeben
    signal btn_rising_edge : std_logic;
    singal btn falling_edge : std_logic;



begin

    -- sampling <= sampling_reg(14 downto 0 & btn(0));
    sample : process (sampling_reg, btn) is
    begin
        sampling <= sampling_reg(14 downto 0) & btn(0);
    end process;



    sample: process (clk) is
    begin
        if(rising_edge(clk) then
            btn_state_reg <= sampling;
            sampling_reg <= sampling;
    end process;

    state: process (sampling_reg) is
    begin
        if(sampling_reg = X"FF") then
            btn_state <= '1';
        elseif(sampling_reg = x"0000") then
            btn_state <= '0';
        else
            btn_state <= btn_state_reg;
        end if;
    end process;
 
    edge_detect : process (clk) is
    begin
        if(rising_edge(clk)) then
            if (btn_state = '1' and btn_state_reg = '0') then
                btn_rising_edge <= '1';
            elseif(btn_state = '0' and btn_state_reg = '1') then
                btn_falling_edge <= '1';
            else
                btn_rising_edge <= '0';
                btn_falling_edge <= '0';
            end if
        end if;
    end process;

    op1 : process (clk) is
    begin
        if(rising_edge(clk)) then
            if(btn_rising_edge = '1') then
            op1_reg <= sw;
            end if;
        end if;
    end process;

end behavioral;