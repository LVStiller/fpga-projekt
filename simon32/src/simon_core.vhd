library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity simon_core is
    port (
        clk        : in  std_logic;
        rst        : in  std_logic;
        start      : in  std_logic;
        plaintext  : in  std_logic_vector(31 downto 0);
        key        : in  std_logic_vector(63 downto 0);
        ciphertext : out std_logic_vector(31 downto 0);
        busy       : out std_logic;
        done       : out std_logic
    );
end entity simon_core;

architecture rtl of simon_core is

    -- FSM-Zustaende
    type state_t is (IDLE, RUN, DONE_ST);
    signal state : state_t;

    -- Datenregister: die zwei 16-Bit-Haelften
    signal x_reg : unsigned(15 downto 0);
    signal y_reg : unsigned(15 downto 0);

    -- Rundenzaehler: 0 bis 31
    signal round_cnt : unsigned(4 downto 0);

    -- Zirkulaerer Linksshift fuer 16-Bit-Woerter
    function rol16(v : unsigned(15 downto 0); n : natural) return unsigned is
    begin
        return v(15 - n downto 0) & v(15 downto 16 - n);
    end function;

begin

    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                state     <= IDLE;
                round_cnt <= (others => '0');
                x_reg     <= (others => '0');
                y_reg     <= (others => '0');
            else
                case state is

                    when IDLE =>
                        if start = '1' then
                            -- Klartext laden: obere Haelfte in x, untere in y
                            x_reg     <= unsigned(plaintext(31 downto 16));
                            y_reg     <= unsigned(plaintext(15 downto 0));
                            round_cnt <= (others => '0');
                            state     <= RUN;
                        end if;

                    when RUN =>
                        x_reg <= y_reg xor
                            (rol16(x_reg, 1) and rol16(x_reg, 8)) xor
                            rol16(x_reg, 2) xor
                            round_key;
                        y_reg <= x_reg;
                        if round_cnt = 31 then
                            state <= DONE_ST;
                        else
                            round_cnt <= round_cnt + 1;
                        end if;

                    when DONE_ST =>
                        state <= IDLE;

                end case;
            end if;
        end if;
    end process;

    -- Ausgaenge (kombinatorisch aus dem Zustand abgeleitet)
    busy       <= '1' when state = RUN else '0';
    done       <= '1' when state = DONE_ST else '0';
    ciphertext <= std_logic_vector(x_reg) & std_logic_vector(y_reg);

end architecture rtl;