library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart_rx is
    generic (
        CLKS_PER_BIT : natural := 868  -- 100 MHz / 115200 Baud
    );
    port (
        clk      : in  std_logic;
        rst      : in  std_logic;
        rx       : in  std_logic;                     -- die serielle Leitung
        data_out : out std_logic_vector(7 downto 0);  -- empfangenes Byte
        valid    : out std_logic                      -- 1 Takt Puls: Byte da!
    );
end entity uart_rx;

architecture rtl of uart_rx is

    type state_t is (IDLE, START, DATA, STOP);
    signal state : state_t;

    signal clk_cnt  : unsigned(9 downto 0);  -- zaehlt bis 868
    signal bit_idx  : unsigned(2 downto 0);  -- welches der 8 Bits
    signal shift    : std_logic_vector(7 downto 0);

begin

    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                state   <= IDLE;
                clk_cnt <= (others => '0');
                bit_idx <= (others => '0');
                valid   <= '0';
            else
                valid <= '0';  -- Default: kein Puls

                case state is

                    when IDLE =>
                        clk_cnt <= (others => '0');
                        bit_idx <= (others => '0');
                        if rx = '0' then          -- Startbit-Flanke!
                            state <= START;
                        end if;

                    when START =>
                        if clk_cnt = CLKS_PER_BIT / 2 - 1 then
                            if rx = '0' then      -- immer noch low: echt
                                clk_cnt <= (others => '0');
                                state   <= DATA;
                            else                  -- Stoerimpuls
                                state <= IDLE;
                            end if;
                        else
                            clk_cnt <= clk_cnt + 1;
                        end if;

                    when DATA =>
                        if clk_cnt = CLKS_PER_BIT - 1 then
                            clk_cnt <= (others => '0');
                            shift   <= rx & shift(7 downto 1);  -- LSB first!
                            if bit_idx = 7 then
                                state <= STOP;
                            else
                                bit_idx <= bit_idx + 1;
                            end if;
                        else
                            clk_cnt <= clk_cnt + 1;
                        end if;

                    when STOP =>
                        if clk_cnt = CLKS_PER_BIT - 1 then
                            valid <= '1';
                            state <= IDLE;
                        else
                            clk_cnt <= clk_cnt + 1;
                        end if;

                end case;
            end if;
        end if;
    end process;

    data_out <= shift;

end architecture rtl;