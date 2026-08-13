library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart_tx is
    generic (
        CLKS_PER_BIT : natural := 868
    );
    port (
        clk     : in  std_logic;
        rst     : in  std_logic;
        send    : in  std_logic;                     -- 1 Takt Puls: sende!
        data_in : in  std_logic_vector(7 downto 0);  -- das Byte
        tx      : out std_logic;                     -- serielle Leitung
        busy    : out std_logic                      -- sende gerade
    );
end entity uart_tx;

architecture rtl of uart_tx is

    type state_t is (IDLE, START, DATA, STOP);
    signal state : state_t;

    signal clk_cnt : unsigned(9 downto 0);
    signal bit_idx : unsigned(2 downto 0);
    signal shift   : std_logic_vector(7 downto 0);

begin

    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                state   <= IDLE;
                clk_cnt <= (others => '0');
                bit_idx <= (others => '0');
                tx      <= '1';           -- Ruhezustand: high
            else
                case state is

                    when IDLE =>
                        tx      <= '1';
                        clk_cnt <= (others => '0');
                        bit_idx <= (others => '0');
                        if send = '1' then
                            shift <= data_in;   -- Byte einlagern
                            state <= START;
                        end if;

                    when START =>
                        tx <= '0';              -- Startbit
                        if clk_cnt = CLKS_PER_BIT - 1 then
                            clk_cnt <= (others => '0');
                            state   <= DATA;
                        else
                            clk_cnt <= clk_cnt + 1;
                        end if;

                    when DATA =>
                        tx <= shift(0);         -- LSB zuerst raus
                        if clk_cnt = CLKS_PER_BIT - 1 then
                            clk_cnt <= (others => '0');
                            shift   <= '0' & shift(7 downto 1);  -- weiterschieben
                            if bit_idx = 7 then
                                state <= STOP;
                            else
                                bit_idx <= bit_idx + 1;
                            end if;
                        else
                            clk_cnt <= clk_cnt + 1;
                        end if;

                    when STOP =>
                        tx <= '1';              -- Stopbit
                        if clk_cnt = CLKS_PER_BIT - 1 then
                            state <= IDLE;
                        else
                            clk_cnt <= clk_cnt + 1;
                        end if;

                end case;
            end if;
        end if;
    end process;

    busy <= '0' when state = IDLE else '1';

end architecture rtl;